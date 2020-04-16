//
//  TCTelegramClient.h
//  TelegramLiveCamera
//
//  Created by fanzhang on 2020年4月16日  16周Thursday.
//  Copyright © 2020 twotrees. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^TCBlock)();
typedef void (^TCFailedBlock)(NSInteger code, NSString* message);

@protocol TCTelegramClientDelegate <NSObject>
- (void)authNeedPhoneNumber;
- (void)authNeedCode;
- (void)authReady;
- (void)authLoggingOut;
- (void)newMessage:(NSInteger)chatId senderId:(NSInteger)senderId content:(NSString*)content;
- (void)error:(NSInteger)code msg:(NSString*)msg;

@end

@interface TCTelegramClient : NSObject

@property(nonatomic, readonly, assign) BOOL running;
@property(nonatomic, readwrite, weak) id<TCTelegramClientDelegate> delegate;
@property(nonatomic, readonly, assign) NSInteger apiId;
@property(nonatomic, readonly, strong) NSString* apiHash;

- (instancetype)initWithApiId:(NSUInteger)apiId apiHash:(NSString*)apiHash;
- (void)run;
- (void)stop;
- (void)setPhoneNumber:(NSString*)phoneNumber success:(TCBlock)success failed:(TCFailedBlock)failed;
- (void)setCode:(NSString*)code success:(TCBlock)success failed:(TCFailedBlock)failed;

- (void)logout;
- (void)sendMessage:(NSInteger)chatId message:(NSString*)message success:(TCBlock)success;

@end

NS_ASSUME_NONNULL_END
