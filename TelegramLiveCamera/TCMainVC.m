//
//  TCMainVC.m
//  TelegramLiveCamera
//
//  Created by fanzhang on 2020年4月15日  16周Wednesday.
//  Copyright © 2020 twotrees. All rights reserved.
//

#import "TCMainVC.h"
#import "UIForLumberjack/UIForLumberjack.h"
#import "LFLiveKit.h"
#import "TelegramClient/TCTelegramClient.h"
#import "TCPreferences.h"
#import "TCSettingsVC.h"

@interface TCMainVC () <LFLiveSessionDelegate, TCTelegramClientDelegate>

@property(nonatomic, readwrite, strong) LFLiveSession* liveSession;
@property(nonatomic, readwrite, strong) TCTelegramClient* telegram;
@property(nonatomic, readwrite, assign) BOOL running;
@property(nonatomic, readwrite, assign) NSInteger keyChatId;
@property(nonatomic, readwrite, assign) NSInteger meUserId;

@end

@implementation TCMainVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setTitle:@"TeleCam"];
    
    [DDLog addLogger:[UIForLumberjack sharedInstance]];
    [[UIForLumberjack sharedInstance] showLogInView:self.view];
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    UIBarButtonItem* runButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"run"] style:UIBarButtonItemStylePlain target:self action:@selector(_onRun)];
    self.navigationItem.leftBarButtonItem = runButton;
    
    UIBarButtonItem* configButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"config"] style:UIBarButtonItemStylePlain target:self action:@selector(_onConfig)];
    self.navigationItem.rightBarButtonItem = configButton;
}

- (void)_onRun {
    if (!TCPreferences.sharedInstance.ready) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"配置错误" message:@"配置未完成，去设置页面看看" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self _onConfig];
        }];
        [alert addAction:confirmAction];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    if (!_running) {
        [self _startTelegram];
        
        _running = YES;
        self.navigationItem.leftBarButtonItem.image = [UIImage imageNamed:@"pause"];
    }
    else {
        [self _stopTelegram];
        [self _stopLive];
        
        _running = NO;
        self.navigationItem.leftBarButtonItem.image = [UIImage imageNamed:@"run"];
    }
}
- (void)_onConfig {
    TCSettingsVC* settingsVC = [TCSettingsVC new];
    settingsVC.cleanAccount = ^ {
        [self _stopLive];
        [self _stopTelegram];
        [TCTelegramClient cleanSession];
    };
    [self.navigationController pushViewController:settingsVC animated:YES];
}

- (void)_startLive {
    LFLiveAudioConfiguration* audio = [LFLiveAudioConfiguration defaultConfigurationForQuality:LFLiveAudioQuality_VeryHigh];
    LFLiveVideoConfiguration* video = [LFLiveVideoConfiguration defaultConfigurationForQuality:LFLiveVideoQuality_High4 outputImageOrientation:UIInterfaceOrientationLandscapeRight];
    
    _liveSession = [[LFLiveSession alloc] initWithAudioConfiguration:audio videoConfiguration:video];
    _liveSession.captureDevicePosition = AVCaptureDevicePositionBack;
    _liveSession.delegate = self;

    LFLiveStreamInfo* info = [LFLiveStreamInfo new];
    info.url = TCPreferences.sharedInstance.liveRtmpUrl;
    [_liveSession startLive:info];
    
    [self _requestAccessForVideo];
    [self _requestAccessForAudio];
}

- (void)_stopLive {
    _liveSession.delegate = nil;
    [_liveSession stopLive];
    _liveSession = nil;
}

- (void)_requestAccessForVideo {
    __weak typeof(self) wself = self;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
    case AVAuthorizationStatusNotDetermined: {
        // 许可对话没有出现，发起授权许可
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [wself.liveSession setRunning:YES];
                    });
                }
            }];
        break;
    }
    case AVAuthorizationStatusAuthorized: {
        // 已经开启授权，可继续
        dispatch_async(dispatch_get_main_queue(), ^{
            [wself.liveSession setRunning:YES];
        });
        break;
    }
    case AVAuthorizationStatusDenied:
    case AVAuthorizationStatusRestricted:
        // 用户明确地拒绝授权，或者相机设备无法访问
        break;
    default:
        break;
    }
}

- (void)_requestAccessForAudio {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (status) {
    case AVAuthorizationStatusNotDetermined: {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            }];
        break;
    }
    case AVAuthorizationStatusAuthorized: {
        break;
    }
    case AVAuthorizationStatusDenied:
    case AVAuthorizationStatusRestricted:
        break;
    default:
        break;
    }
}

- (void)liveSession:(nullable LFLiveSession *)session liveStateDidChange:(LFLiveState)state {
    NSString* status = [self _liveStatus2Msg:state];
    if (status.length) {
        DDLogDebug(status);
        if (_keyChatId) {
            [ _telegram sendMessage:_keyChatId message:status success:^{
                DDLogDebug(@"[telegram] 回复消息成功, %@", status);
            }];
            
            if (LFLiveStart == state) {
                NSString* replay = [NSString stringWithFormat:@"正在直播，点击观看: %@", TCPreferences.sharedInstance.liveViewUrl];
                [ _telegram sendMessage:_keyChatId message:replay success:^{
                    DDLogDebug(@"[telegram] 回复消息成功, %@", replay);
                }];
            }
        }
    }
}

- (void)liveSession:(nullable LFLiveSession *)session debugInfo:(nullable LFLiveDebug *)debugInfo {
    DDLogDebug(@"debug info:%@", debugInfo);
}

- (void)liveSession:(nullable LFLiveSession *)session errorCode:(LFLiveSocketErrorCode)errorCode {
    NSString* errorMsg;
    switch (errorCode) {
        case LFLiveSocketError_PreView:
            errorMsg = [NSString stringWithFormat:@"[推流] 错误:%ld, Preview failed", errorCode];
            break;
            
        case LFLiveSocketError_GetStreamInfo:
            errorMsg = [NSString stringWithFormat:@"[推流] 错误:%ld, Get stream info failed", errorCode];
            break;
        case LFLiveSocketError_ConnectSocket:
            errorMsg = [NSString stringWithFormat:@"[推流] 错误:%ld, Connect socket failed", errorCode];
            break;
            
        case LFLiveSocketError_Verification:
            errorMsg = [NSString stringWithFormat:@"[推流] 错误:%ld, Verification failed", errorCode];
            break;
        
        case LFLiveSocketError_ReConnectTimeOut:
            errorMsg = [NSString stringWithFormat:@"[推流] 错误:%ld, Reconnect timeout", errorCode];
            break;
            
        default:
            break;
    }
    
    if (errorMsg.length) {
        DDLogError(errorMsg);
        
        if (_keyChatId) {
            [ _telegram sendMessage:_keyChatId message:errorMsg success:^{
                DDLogDebug(@"[telegram] 回复消息成功, %@", errorMsg);
            }];
        }
    }
}

- (NSString*)_liveStatus2Msg:(LFLiveState)state {
    NSString* status;
    switch (state) {
        case LFLiveReady:
            status = [NSString stringWithFormat:@"[推流] 状态:%ld, Ready", state];
            break;
            
        case LFLivePending:
            status = [NSString stringWithFormat:@"[推流] 状态:%ld, Pending", state];
            break;
            
        case LFLiveStart:
            status = [NSString stringWithFormat:@"[推流] 状态:%ld, Start", state];
            break;
            
        case LFLiveStop:
            status = [NSString stringWithFormat:@"[推流] 状态:%ld, Stop", state];
            break;
            
        case LFLiveError:
            status = [NSString stringWithFormat:@"[推流] 状态:%ld, Error", state];
            break;
            
        case LFLiveRefresh:
            status = [NSString stringWithFormat:@"[推流] 状态:%ld, Refresh", state];
            break;
            
        default:
            break;
    }
    
    return status;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------

- (void)_startTelegram {
    NSInteger apiId = TCPreferences.sharedInstance.telegramApiId;
    NSString* apiHash = TCPreferences.sharedInstance.telegramApiHash;
    _telegram = [[TCTelegramClient alloc] initWithApiId:apiId apiHash:apiHash];
    _telegram.delegate = self;
    [_telegram run];
}

- (void)_stopTelegram {
    _telegram.delegate = nil;
    _meUserId = 0;
    _keyChatId = 0;
    [_telegram stop];
    _telegram = nil;
}

- (void)authNeedPhoneNumber{
    NSString* phoneNumber = TCPreferences.sharedInstance.telegramPhoneNumber;
    [_telegram setPhoneNumber:phoneNumber success:^{
        ;
    } failed:^(NSInteger code, NSString * _Nonnull message) {
        DDLogError(@"[Telegram] 设置电话号码错误, code:%ld, message:%@", code, message);
    }];
}

- (void)authNeedCode {
    __weak typeof(self) weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"验证码" message:@"请输入来自 Telegram app 的验证码：" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"code";
    }];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString* code =[[alertController textFields][0] text];
        [weakSelf.telegram setCode:code success:^{
            ;
        } failed:^(NSInteger code, NSString * _Nonnull message) {
            [weakSelf authNeedCode];
        }];
    }];
    [alertController addAction:confirmAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"Canelled");
    }];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)authReady {
    DDLogInfo(@"[Telegram] 登录成功");
}

- (void)getMeUserId:(NSInteger)userId {
    _meUserId = userId;
    DDLogInfo(@"[Telegram] 获取 uid 成功");
}

- (void)authLoggingOut {
    DDLogInfo(@"[Telegram] 登出成功");
}

- (void)newMessage:(NSInteger)chatId senderId:(NSInteger)senderId content:(NSString*)content {
    DDLogInfo(@"[Telegram] 新消息, chatId:%ld, sendId:%ld, msg:%@", chatId, senderId, content);
    
    if (senderId == _meUserId)
        return;
    
    NSString* replay;
    if ([content isEqualToString:@"help"]) {
        replay =
        @"使用帮助:\n\
        [暗号] ->对接暗号\n\
        query ->查询当前状态\n\
        start ->开始直播推流\n\
        stop ->停止直播推流\n";
    }
    else if ([content isEqualToString:TCPreferences.sharedInstance.telegramMessageTag]){
        _keyChatId = chatId;
        replay = @"暗号对接成功!";
    }
    else if (_keyChatId == chatId)
    {
        NSString* command = content;
        if ([command isEqualToString:@"query"]) {
            if (LFLiveStart == _liveSession.state) {
                replay = [NSString stringWithFormat:@"正在直播，点击观看: %@", TCPreferences.sharedInstance.liveViewUrl];
            }
            else
                replay = [self _liveStatus2Msg:_liveSession.state];
        }
        else if ([command isEqualToString:@"start"]) {
            replay = @"收到，开始直播";
            [self _stopLive];
            [self _startLive];
        }
        else if ([command isEqualToString:@"stop"]) {
            replay = @"收到，停止直播";
            [self _stopLive];
        }
    }
    
    if (replay.length) {
        [_telegram sendMessage:chatId message:replay success:^{
            DDLogDebug(@"[telegram] 回复消息成功, %@", replay);
        }];
    }
}

- (void)error:(NSInteger)code msg:(NSString*)msg {
    
}

@end
