//
//  NIMMessageMaker.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>

@class NIMKitLocationPoint;

@interface NIMMessageMaker : NSObject

+ (NIMMessage*)msgWithText:(NSString *)text;

+ (NIMMessage *)msgWithAudio:(NSString *)filePath;

+ (NIMMessage *)msgWithImage:(UIImage *)image;

+ (NIMMessage *)msgWithImagePath:(NSString *)path;

+ (NIMMessage *)msgWithImageData:(NSData *)data extension:(NSString *)extension;

+ (NIMMessage *)msgWithVideo:(NSString *)filePath;

+ (NIMMessage *)msgWithLocation:(NIMKitLocationPoint *)locationPoint;

@end


@interface NIMCommentMaker : NSObject

+ (NIMQuickComment *)commentWithType:(int64_t)type
                             content:(NSString *)content
                                 ext:(NSString *)ext;

@end
