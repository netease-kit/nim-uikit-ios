//
//  NTESSessionUtil.h
//  NIMDemo
//
//  Created by ght on 15-1-27.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface NTESSessionUtil : NSObject

+ (CGSize)getImageSizeWithImageOriginSize:(CGSize)originSize
                                  minSize:(CGSize)imageMinSize
                                  maxSize:(CGSize)imageMaxSize;

+ (NSString *)showNick:(NSString*)uid inSession:(NIMSession*)session;

//接收时间格式化
+ (NSString*)showTime:(NSTimeInterval) msglastTime showDetail:(BOOL)showDetail;

+ (void)sessionWithInputURL:(NSURL*)inputURL
                  outputURL:(NSURL*)outputURL
               blockHandler:(void (^)(AVAssetExportSession*))handler;


+ (NSDictionary *)dictByJsonData:(NSData *)data;

+ (NSDictionary *)dictByJsonString:(NSString *)jsonString;

+ (BOOL)canMessageBeForwarded:(NIMMessage *)message;

+ (BOOL)canMessageBeRevoked:(NIMMessage *)message;

+ (NSString *)tipOnMessageRevoked:(id)message;

+ (void)addRecentSessionAtMark:(NIMSession *)session;

+ (void)removeRecentSessionAtMark:(NIMSession *)session;

+ (BOOL)recentSessionIsAtMark:(NIMRecentSession *)recent;

+ (NSString *)onlineState:(NSString *)userId detail:(BOOL)detail;

+ (NSString *)formatAutoLoginMessage:(NSError *)error;

@end
