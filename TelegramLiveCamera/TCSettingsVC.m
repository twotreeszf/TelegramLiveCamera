//
//  TCSettingsVC.m
//  TelegramLiveCamera
//
//  Created by fanzhang on 2020年4月17日  16周Friday.
//  Copyright © 2020 twotrees. All rights reserved.
//

#import "TCSettingsVC.h"
#import "TCExportQRVC.h"
#import <ZXingObjC/ZXingObjC.h>
#import "TCPreferences.h"
#import "TCScanQRVC.h"

@implementation TCSettingsVC

- (void)viewDidLoad {
    [self setTitle:@"设置"];
    self.neverShowPrivacySettings = YES;
    self.showCreditsFooter = NO;
    self.showDoneButton = NO;
    
    [super viewDidLoad];
    self.delegate = self;
    
    UIBarButtonItem* exportButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"export"] style:UIBarButtonItemStylePlain target:self action:@selector(_onExport)];
    UIBarButtonItem* scanButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"scan"] style:UIBarButtonItemStylePlain target:self action:@selector(_onScan)];
    
    self.navigationItem.rightBarButtonItems = @[scanButton, exportButton];
}

- (void)_onExport {
    CGFloat width = self.view.bounds.size.width * 2;
    NSString* json = [TCPreferences.sharedInstance exportJson];
    NSString* base64 = [[json dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];

    NSError *error = nil;
    ZXMultiFormatWriter *writer = [ZXMultiFormatWriter writer];
    ZXEncodeHints* hints = [ZXEncodeHints hints];
    hints.errorCorrectionLevel = [ZXQRCodeErrorCorrectionLevel errorCorrectionLevelH];
    ZXBitMatrix* result = [writer encode:base64 format:kBarcodeFormatQRCode width:width height:width hints:hints error:&error];
    if (result) {
        CGImageRef image = [[ZXImage imageWithMatrix:result] cgimage];
        UIImage* qrCode = [UIImage imageWithCGImage:image];
        TCExportQRVC* export = [TCExportQRVC new];
        export.image = qrCode;
        [self.navigationController pushViewController:export animated:YES];
    }
    else {
        DDLogError(@"%@", error);
    }
}

- (void)_onScan {
    TCScanQRVC* scan = [TCScanQRVC new];
    [self.navigationController pushViewController:scan animated:YES];
}

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender {
    ;
}

- (void)settingsViewController:(IASKAppSettingsViewController*)sender buttonTappedForSpecifier:(IASKSpecifier*)specifier {
    if ([specifier.key isEqualToString:@"CleanAccount"]) {
        __weak typeof(self) weakSelf = self;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"确认退出？" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            weakSelf.cleanAccount();
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"退出成功" message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            [weakSelf presentViewController:alert animated:YES completion:nil];
        }];
        [alertController addAction:confirmAction];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"Canelled");
        }];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

@end
