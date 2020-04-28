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
    BOOL ret =
    self.telegramApiId &&
    self.telegramApiHash.length &&
    self.telegramPhoneNumber.length &&
    self.telegramMessageTag.length &&
    self.liveRtmpUrl.length &&
    self.liveViewUrl.length;
    
    return ret;;
}

- (NSString*)exportJson {
    NSMutableDictionary* dic = [NSMutableDictionary new];
    dic[PROPERTY_NAME(telegramApiId)] = @(self.telegramApiId);
    dic[PROPERTY_NAME(telegramApiHash)] = self.telegramApiHash;
    dic[PROPERTY_NAME(telegramPhoneNumber)] = self.telegramPhoneNumber;
    dic[PROPERTY_NAME(telegramMessageTag)] = self.telegramMessageTag;
    dic[PROPERTY_NAME(liveRtmpUrl)] = self.liveRtmpUrl;
    dic[PROPERTY_NAME(liveViewUrl)] = self.liveViewUrl;
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];
   return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (BOOL)importJson:(NSString *)json {
    NSDictionary* dic = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    if (!dic)
        return NO;
    
    self.telegramApiId = ((NSNumber*)dic[PROPERTY_NAME(telegramApiId)]).integerValue;
    self.telegramApiHash = dic[PROPERTY_NAME(telegramApiHash)];
    self.telegramPhoneNumber = dic[PROPERTY_NAME(telegramPhoneNumber)];
    self.telegramMessageTag = dic[PROPERTY_NAME(telegramMessageTag)];
    self.liveRtmpUrl = dic[PROPERTY_NAME(liveRtmpUrl)];
    self.liveViewUrl = dic[PROPERTY_NAME(liveViewUrl)];
    
    return self.ready;
}

@end
