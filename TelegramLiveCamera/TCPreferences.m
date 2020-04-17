//
//  TCPreferences.m
//  TelegramLiveCamera
//
//  Created by fanzhang on 2020年4月17日  16周Friday.
//  Copyright © 2020 twotrees. All rights reserved.
//

#import "TCPreferences.h"

@implementation TCPreferences

@dynamic telegramApiId;
@dynamic telegramApiHash;
@dynamic telegramPhoneNumber;
@dynamic telegramMessageTag;
@dynamic liveRtmpUrl;
@dynamic liveViewUrl;

- (BOOL)ready {
    return
    self.telegramApiId &&
    self.telegramApiHash.length &&
    self.telegramPhoneNumber.length &&
    self.telegramMessageTag.length &&
    self.liveRtmpUrl.length &&
    self.liveViewUrl.length;
}

@end
