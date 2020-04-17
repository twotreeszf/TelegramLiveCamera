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

@end

@implementation TCMainVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setTitle:@"TeleCam"];
    
    [DDLog addLogger:[UIForLumberjack sharedInstance]];
    [[UIForLumberjack sharedInstance] showLogInView:self.view];
    
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
    switch (state) {
        case LFLiveReady:
            DDLogInfo(@"[推流] 状态:%ld, Ready", state);
            break;
            
        case LFLivePending:
            DDLogInfo(@"[推流] 状态:%ld, Pending", state);
            break;
            
        case LFLiveStart:
            DDLogInfo(@"[推流] 状态:%ld, Start", state);
            break;
            
        case LFLiveStop:
            DDLogInfo(@"[推流] 状态:%ld, Stop", state);
            break;
            
        case LFLiveError:
            DDLogInfo(@"[推流] 状态:%ld, Error", state);
            break;
            
        case LFLiveRefresh:
            DDLogInfo(@"[推流] 状态:%ld, Refresh", state);
            break;
            
        default:
            break;
    }
    
}

- (void)liveSession:(nullable LFLiveSession *)session debugInfo:(nullable LFLiveDebug *)debugInfo {
    DDLogDebug(@"debug info:%@", debugInfo);
}

- (void)liveSession:(nullable LFLiveSession *)session errorCode:(LFLiveSocketErrorCode)errorCode {
    switch (errorCode) {
        case LFLiveSocketError_PreView:
            DDLogError(@"[推流]错误:%ld, Preview failed", errorCode);
            break;
            
        case LFLiveSocketError_GetStreamInfo:
            DDLogError(@"[推流]错误:%ld, Get stream info failed", errorCode);
            break;
        case LFLiveSocketError_ConnectSocket:
            DDLogError(@"[推流]错误:%ld, Connect socket failed", errorCode);
            break;
            
        case LFLiveSocketError_Verification:
            DDLogError(@"[推流]错误:%ld, Verification failed", errorCode);
            break;
        
        case LFLiveSocketError_ReConnectTimeOut:
            DDLogError(@"[推流]错误:%ld, Reconnect timeout", errorCode);
            break;
            
        default:
            break;
    }
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
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Verify Code:" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Verify Code";
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

- (void)authLoggingOut {
    DDLogInfo(@"[Telegram] 登出成功");
}

- (void)newMessage:(NSInteger)chatId senderId:(NSInteger)senderId content:(NSString*)content {
    DDLogInfo(@"[Telegram] 新消息, chatId:%ld, sendId:%ld, msg:%@", chatId, senderId, content);
}

- (void)error:(NSInteger)code msg:(NSString*)msg {
    
}

@end
