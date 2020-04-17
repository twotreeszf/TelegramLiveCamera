//
//  TCTelegramClient.m
//  TelegramLiveCamera
//
//  Created by fanzhang on 2020年4月16日  16周Thursday.
//  Copyright © 2020 twotrees. All rights reserved.
//

#import "TCTelegramClient.h"
#import "td/telegram/Client.h"
#import <map>

#define LOG_LEVEL_DEF LOG_LEVEL_VERBOSE
#import <DDLog.h>

using namespace td;

// overloaded
namespace detail {
template <class... Fs>
struct overload;

template <class F>
struct overload<F> : public F {
  explicit overload(F f) : F(f) {
  }
};
template <class F, class... Fs>
struct overload<F, Fs...>
    : public overload<F>
    , overload<Fs...> {
  overload(F f, Fs... fs) : overload<F>(f), overload<Fs...>(fs...) {
  }
  using overload<F>::operator();
  using overload<Fs...>::operator();
};
}  // namespace detail

template <class... F>
auto overloaded(F... f) {
  return detail::overload<F...>(f...);
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------

@interface TCTelegramClient() {
    std::unique_ptr<td::Client> _client;
    dispatch_source_t _timer;
    std::uint64_t _currentQueryId;
    std::map<std::uint64_t, std::function<void(td_api::Object&)>> _handlers;
}
@property(nonatomic, readwrite, strong) dispatch_queue_t queue;
@property(nonatomic, readonly, strong) NSString* libraryPath;

@end

@implementation TCTelegramClient

- (NSString*)libraryPath {
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    libraryPath = [libraryPath stringByAppendingPathComponent:@"Telegram"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:libraryPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:libraryPath withIntermediateDirectories:NO attributes:nil error:nil];
    return libraryPath;
}

- (instancetype)initWithApiId:(NSUInteger)apiId apiHash:(NSString *)apiHash {
    self = [super init];
    
    _apiId = apiId;
    _apiHash = apiHash;
    _client = std::make_unique<td::Client>();
    _queue = dispatch_queue_create("TelegramQueue",  DISPATCH_QUEUE_SERIAL);
    
    return self;
}

- (void)run {
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);

    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, 0);
    uint64_t intervalTime = (int64_t)(1 * NSEC_PER_SEC);
    dispatch_source_set_timer(_timer, startTime, intervalTime, 0);
    dispatch_source_set_event_handler(_timer, ^{
        [self _poll];
    });

    dispatch_resume(_timer);
    
    _running = YES;
}

- (void)stop {
    _running = NO;
    
    dispatch_suspend(_timer);
    _timer = 0;
    
    dispatch_async(_queue, ^{
        self->_currentQueryId = 0;
        self->_handlers.clear();
    });
}

- (BOOL)cleanSession {
    if (_running)
        return NO;
    
    NSError* err;
    [[NSFileManager defaultManager] removeItemAtPath:self.libraryPath error:&err];
    return err != nil;
}

- (void)setPhoneNumber:(NSString*)phoneNumber success:(TCBlock)success failed:(TCFailedBlock)failed {
    __weak typeof(self) weakSelf = self;
    dispatch_async(weakSelf.queue, ^{
        [weakSelf _sendQuery:td_api::make_object<td_api::setAuthenticationPhoneNumber>(phoneNumber.UTF8String, nullptr)
                     handler:[weakSelf, success, failed](td_api::Object& obj) {
            BOOL ok = [weakSelf _checkError:obj failed:^(NSInteger code, NSString * _Nonnull message) {
                failed(code, message);
            }];
            if (ok) {
                DDLogInfo(@"[Telegram] 手机号设置成功");
                success();
            }
        }];
    });
}

- (void)setCode:(NSString*)code success:(TCBlock)success failed:(TCFailedBlock)failed {
    __weak typeof(self) weakSelf = self;
    dispatch_async(weakSelf.queue, ^{
        [weakSelf _sendQuery:td_api::make_object<td_api::checkAuthenticationCode>(code.UTF8String) handler:[weakSelf, success, failed](td_api::Object& obj) {
            BOOL ok = [weakSelf _checkError:obj failed:^(NSInteger code, NSString * _Nonnull message) {
                failed(code, message);
            }];
            if (ok) {
                DDLogInfo(@"[Telegram] 验证码发送成功");
                success();
            }
        }];
    });
}

- (void)logout {
    __weak typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        [weakSelf _sendQuery:td_api::make_object<td_api::logOut>() handler:[weakSelf](td_api::Object& obj) {
            if (![weakSelf _checkError:obj failed:nil])
                DDLogInfo(@"[Telegram] 登出成功");
        }];
    });
}

- (void)sendMessage:(NSInteger)chatId message:(NSString*)message success:(TCBlock)success{
    __weak typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        auto sendMessage = td_api::make_object<td_api::sendMessage>();
        sendMessage->chat_id_ = chatId;
        auto content = td_api::make_object<td_api::inputMessageText>();
        content->text_ = td_api::make_object<td_api::formattedText>();
        content->text_->text_ = message.UTF8String;
        sendMessage->input_message_content_ = std::move(content);
        [weakSelf _sendQuery:std::move(sendMessage) handler:[weakSelf, success](td_api::Object& obj) {
            if (![weakSelf _checkError:obj failed:nil]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    success();
                });
            }
        }];
    });
}

- (void)_poll {
    while (true) {
        auto response = _client->receive(0);
        if (!response.object)
            break;
        
        if (0 == response.id) {
            td_api::downcast_call(*response.object, overloaded(
            [self](td_api::updateAuthorizationState& state) {
                [self _processAuthorization:*state.authorization_state_];
            },
            [self](td_api::updateNewMessage& message) {
                [self _processNewMessage:message];
            },
            [](auto &update){
                DDLogDebug(@"update: %s", td_api::to_string(update).c_str());
            }));
        }
        else {
            [self _processResponse:response];
        }
    }
}

- (void)_processNewMessage:(td_api::updateNewMessage&)newMessage {
    auto chatId = newMessage.message_->chat_id_;
    auto senderId = newMessage.message_->sender_user_id_;
    std::string text;
    if (newMessage.message_->content_->get_id() == td_api::messageText::ID) {
        text = static_cast<td_api::messageText &>(*newMessage.message_->content_).text_->text_;
        
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.delegate)
                [weakSelf.delegate newMessage:chatId senderId:senderId content:[NSString stringWithUTF8String:text.c_str()]];
        });
    }
}

- (void)_processResponse:(Client::Response&)response {
    auto it = _handlers.find(response.id);
    if (it != _handlers.end()) {
        it->second(*response.object);
        _handlers.erase(it);
    }
}

- (void)_processAuthorization:(td_api::AuthorizationState&)state {
    __weak typeof(self) weakSelf = self;
    
    td_api::downcast_call(state, overloaded(
    [weakSelf](td_api::authorizationStateReady&){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.delegate)
                [weakSelf.delegate authReady];
        });
    },
    [weakSelf](td_api::authorizationStateLoggingOut&){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.delegate)
                [weakSelf.delegate authLoggingOut];
        });
    },
    [weakSelf](td_api::authorizationStateWaitPhoneNumber&){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.delegate)
                [weakSelf.delegate authNeedPhoneNumber];
        });
    },
    [weakSelf](td_api::authorizationStateWaitCode&){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.delegate)
                [weakSelf.delegate authNeedCode];
        });
    },
    [weakSelf](td_api::authorizationStateWaitTdlibParameters&){
        auto parameters = td_api::make_object<td_api::tdlibParameters>();
        parameters->use_test_dc_ = false;
        parameters->database_directory_ = weakSelf.libraryPath.UTF8String;
        parameters->use_file_database_ = true;
        parameters->use_chat_info_database_ = true;
        parameters->use_message_database_ = true;
        parameters->use_secret_chats_ = true;
        parameters->api_id_ = (int32_t)weakSelf.apiId;
        parameters->api_hash_ = weakSelf.apiHash.UTF8String;
        parameters->system_language_code_ = "en";
        parameters->device_model_ = [UIDevice currentDevice].model.UTF8String;
        parameters->system_version_ = [UIDevice currentDevice].systemVersion.UTF8String;
        NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        parameters->application_version_ = appVersion.UTF8String;
        parameters->enable_storage_optimizer_ = true;
        
        [weakSelf _sendQuery:td_api::make_object<td_api::setTdlibParameters>(std::move(parameters)) handler:[weakSelf](td_api::Object& obj) {
            if (![weakSelf _checkError:obj failed:nil]) {
                DDLogInfo(@"[Telegram] 参数设置成功");
            }
        }];
    },
    [weakSelf](td_api::authorizationStateWaitEncryptionKey&){
        [weakSelf _sendQuery:td_api::make_object<td_api::checkDatabaseEncryptionKey>("twotrees") handler:[weakSelf](td_api::Object& obj) {
            if (![weakSelf _checkError:obj failed:nil]) {
                DDLogInfo(@"[Telegram] 通信秘钥设置成功");
            }
        }];
    },
    [self](auto& state){
        DDLogDebug(@"in other authorization state: %s", td_api::to_string(state).c_str());
    }
    ));
}

- (void)_sendQuery:(td_api::object_ptr<td_api::Function>)func handler:(std::function<void(td_api::Object&)>)handler {
    uint64_t queryId = ++_currentQueryId;
    _handlers[queryId] = std::move(handler);
    _client->send({queryId, std::move(func)});
}

- (BOOL)_checkError:(td_api::Object&)obj failed:(TCFailedBlock)failed{
    if (obj.get_id() == td_api::error::ID) {
        auto& error = static_cast<td_api::error&>(obj);
        DDLogError(@"Telegram 错误, code:%d message:%s", error.code_, error.message_.c_str());
        
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failed)
                failed(error.code_,[NSString stringWithUTF8String:error.message_.c_str()]);
            else if (weakSelf.delegate)
                [weakSelf.delegate error:error.code_ msg:[NSString stringWithUTF8String:error.message_.c_str()]];
        });
        
        return YES;
    }
    return NO;
}

@end
