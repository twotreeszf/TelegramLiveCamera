//
//  ViewController.m
//  TelegramLiveCamera
//
//  Created by fanzhang on 2020年4月15日  16周Wednesday.
//  Copyright © 2020 twotrees. All rights reserved.
//

#import "ViewController.h"
#import <UIForLumberjack.h>
#import "LFLiveKit.h"
#import "TelegramClient/TCTelegramClient.h"

@interface ViewController () <LFLiveSessionDelegate, TCTelegramClientDelegate>{
    LFLiveSession* _session;
}

@property(nonatomic, readwrite, strong) TCTelegramClient* telegram;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [DDLog addLogger:[UIForLumberjack sharedInstance]];
    [[UIForLumberjack sharedInstance] showLogInView:self.view];
    
    _telegram = [[TCTelegramClient alloc] initWithApiId:1268427 apiHash:@"d0a9c00357cff3ee823cda3e98e13753"];
    _telegram.delegate = self;
    [_telegram run];
    
//    [self _initSession];
//    [self _startLive];
    
}

- (void)_initSession {
    LFLiveAudioConfiguration* audio = [LFLiveAudioConfiguration defaultConfigurationForQuality:LFLiveAudioQuality_VeryHigh];
    LFLiveVideoConfiguration* video = [LFLiveVideoConfiguration defaultConfigurationForQuality:LFLiveVideoQuality_High4 outputImageOrientation:UIInterfaceOrientationLandscapeRight];
    
    _session = [[LFLiveSession alloc] initWithAudioConfiguration:audio videoConfiguration:video];
    _session.captureDevicePosition = AVCaptureDevicePositionBack;
    _session.delegate = self;
    
    [self _requestAccessForVideo];
    [self _requestAccessForAudio];
}

- (void) _startLive{
    LFLiveStreamInfo* info = [LFLiveStreamInfo new];
    info.url = @"rtmp://hkg.contribute.live-video.net/app/live_514405968_2xo6qo4ceEMMywOJkfhnyGULkgDntg";
    [_session startLive:info];
}

- (void)_setRunning:(BOOL)running {
    [_session setRunning:running];
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
                        [wself _setRunning:YES];
                    });
                }
            }];
        break;
    }
    case AVAuthorizationStatusAuthorized: {
        // 已经开启授权，可继续
        dispatch_async(dispatch_get_main_queue(), ^{
            [wself _setRunning:YES];
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
            DDLogInfo(@"state:%ld, Ready", state);
            break;
            
        case LFLivePending:
            DDLogInfo(@"state:%ld, Pending", state);
            break;
            
        case LFLiveStart:
            DDLogInfo(@"state:%ld, Start", state);
            break;
            
        case LFLiveStop:
            DDLogInfo(@"state:%ld, Stop", state);
            break;
            
        case LFLiveError:
            DDLogInfo(@"state:%ld, Error", state);
            break;
            
        case LFLiveRefresh:
            DDLogInfo(@"state:%ld, Refresh", state);
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
            DDLogError(@"error:%ld, Preview failed", errorCode);
            break;
            
        case LFLiveSocketError_GetStreamInfo:
            DDLogError(@"error:%ld, Get stream info failed", errorCode);
            break;
        case LFLiveSocketError_ConnectSocket:
            DDLogError(@"error:%ld, Connect socket failed", errorCode);
            break;
            
        case LFLiveSocketError_Verification:
            DDLogError(@"error:%ld, Verification failed", errorCode);
            break;
        
        case LFLiveSocketError_ReConnectTimeOut:
            DDLogError(@"error:%ld, Reconnect timeout", errorCode);
            break;
            
        default:
            break;
    }
}

- (void)authNeedPhoneNumber{
    __weak typeof(self) weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Phone Number:" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Phone Number";
    }];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString* phoneNumber =[[alertController textFields][0] text];
        [weakSelf.telegram setPhoneNumber:phoneNumber success:^{
            ;
        } failed:^(NSInteger code, NSString * _Nonnull message) {
            [weakSelf authNeedPhoneNumber];
        }];
    }];
    [alertController addAction:confirmAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"Canelled");
    }];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
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
    
}

- (void)authLoggingOut {
    
}

- (void)newMessage:(NSInteger)chatId senderId:(NSInteger)senderId content:(NSString*)content {
    DDLogInfo(@"new message, chatId:%ld, sendId:%ld, msg:%@", chatId, senderId, content);
}

- (void)error:(NSInteger)code msg:(NSString*)msg {
    
}

@end
