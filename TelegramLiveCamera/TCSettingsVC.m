//
//  TCSettingsVC.m
//  TelegramLiveCamera
//
//  Created by fanzhang on 2020年4月17日  16周Friday.
//  Copyright © 2020 twotrees. All rights reserved.
//

#import "TCSettingsVC.h"

@implementation TCSettingsVC

- (void)viewDidLoad {
    [self setTitle:@"设置"];
    self.neverShowPrivacySettings = YES;
    self.showCreditsFooter = NO;
    self.showDoneButton = NO;
    
    [super viewDidLoad];
    self.delegate = self;
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
