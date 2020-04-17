//
//  TCPreferences.h
//  TelegramLiveCamera
//
//  Created by fanzhang on 2020年4月17日  16周Friday.
//  Copyright © 2020 twotrees. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PAPreferences/PAPreferences.h>

NS_ASSUME_NONNULL_BEGIN

@interface TCPreferences : PAPreferences

@property(nonatomic, readwrite, assign) NSInteger telegramApiId;
@property(nonatomic, readwrite, assign) NSString* telegramApiHash;
@property(nonatomic, readwrite, assign) NSString* telegramPhoneNumber;
@property(nonatomic, readwrite, assign) NSString* telegramMessageTag;

@property(nonatomic, readwrite, assign) NSString* liveRtmpUrl;
@property(nonatomic, readwrite, assign) NSString* liveViewUrl;


@end

NS_ASSUME_NONNULL_END
