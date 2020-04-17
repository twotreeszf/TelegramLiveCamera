//
//  TCSettingsVC.h
//  TelegramLiveCamera
//
//  Created by fanzhang on 2020年4月17日  16周Friday.
//  Copyright © 2020 twotrees. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <InAppSettingsKit/IASKAppSettingsViewController.h>

NS_ASSUME_NONNULL_BEGIN

@interface TCSettingsVC : IASKAppSettingsViewController <IASKSettingsDelegate>

@property(nonatomic, readwrite, strong) TCBlock cleanAccount;

@end

NS_ASSUME_NONNULL_END
