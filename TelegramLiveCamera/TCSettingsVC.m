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
}

@end
