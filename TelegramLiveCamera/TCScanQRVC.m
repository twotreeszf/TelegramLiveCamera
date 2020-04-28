//
//  TCScanQRVC.m
//  TelegramLiveCamera
//
//  Created by fanzhang on 2020年4月27日  18周Monday.
//  Copyright © 2020 twotrees. All rights reserved.
//

#import "TCScanQRVC.h"
#import <MTBBarcodeScanner/MTBBarcodeScanner.h>
#import "TCPreferences.h"
#import <Toast/Toast.h>

@interface TCScanQRVC ()

@property(nonatomic, readwrite, strong) MTBBarcodeScanner* scanner;

@end

@implementation TCScanQRVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _scanner = [[MTBBarcodeScanner alloc] initWithMetadataObjectTypes:@[AVMetadataObjectTypeQRCode] previewView:self.view];
}

- (void)viewWillAppear:(BOOL)animated {
    [MTBBarcodeScanner requestCameraPermissionWithSuccess:^(BOOL success) {
        if (success) {
            NSError *error = nil;
            BOOL ret = [self.scanner startScanningWithResultBlock:^(NSArray *codes) {
                AVMetadataMachineReadableCodeObject *code = [codes firstObject];
                NSString* base64 = code.stringValue;
                if (!base64.length)
                    return;
                NSData *data = [[NSData alloc] initWithBase64EncodedString:base64 options:0];
                if (!data)
                    return;
                
                NSString* json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                DDLogDebug(@"检测到配置:\n%@", json);
                
                if ([TCPreferences.sharedInstance importJson:json]) {
                    [self.scanner stopScanning];
                    [self.view makeToast:@"配置导入成功" duration:0.5 position:CSToastPositionCenter];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self.navigationController popViewControllerAnimated:YES];
                    });
                }
            } error:&error];
            
            if (!ret)
                DDLogError(@"qrcode scan error:%@", error);
        }
        else {
            [self.navigationController popViewControllerAnimated:YES];
            DDLogError(@"request camera permission failed");
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [_scanner stopScanning];
}

@end
