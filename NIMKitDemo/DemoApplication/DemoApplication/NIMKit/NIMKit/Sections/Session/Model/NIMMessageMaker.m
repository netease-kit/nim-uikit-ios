//
//  NIMMessageMaker.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMMessageMaker.h"
#import "NSString+NIM.h"
#import "NIMKitLocationPoint.h"

@implementation NIMMessageMaker

+ (NIMMessage*)msgWithText:(NSString*)text
{
    NIMMessage *textMessage = [[NIMMessage alloc] init];
    textMessage.text        = text;
    return textMessage;
}

+ (NIMMessage*)msgWithAudio:(NSString*)filePath
{
    NIMAudioObject *audioObject = [[NIMAudioObject alloc] initWithSourcePath:filePath];
    NIMMessage *message = [[NIMMessage alloc] init];
    message.messageObject = audioObject;
    message.text = @"发来了一段语音";
    return message;
}

+ (NIMMessage*)msgWithVideo:(NSString*)filePath
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    NIMVideoObject *videoObject = [[NIMVideoObject alloc] initWithSourcePath:filePath];
    videoObject.displayName = [NSString stringWithFormat:@"视频发送于%@",dateString];
    NIMMessage *message = [[NIMMessage alloc] init];
    message.messageObject = videoObject;
    message.apnsContent = @"发来了一段视频";
    return message;
}

+ (NIMMessage*)msgWithImage:(UIImage*)image
{
    NIMImageObject * imageObject = [[NIMImageObject alloc] initWithImage:image];
    return [NIMMessageMaker generateImageMessage:imageObject];
}

+ (NIMMessage *)msgWithImagePath:(NSString*)path
{
    NIMImageObject * imageObject = [[NIMImageObject alloc] initWithFilepath:path];
    return [NIMMessageMaker generateImageMessage:imageObject];
}

+ (NIMMessage *)generateImageMessage:(NIMImageObject *)imageObject
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    imageObject.displayName = [NSString stringWithFormat:@"图片发送于%@",dateString];
    NIMImageOption *option  = [[NIMImageOption alloc] init];
    option.compressQuality  = 0.8;
    imageObject.option = option;
    NIMMessage *message     = [[NIMMessage alloc] init];
    message.messageObject   = imageObject;
    message.apnsContent = @"发来了一张图片";
    return message;
}


+ (NIMMessage*)msgWithLocation:(NIMKitLocationPoint *)locationPoint{
    NIMLocationObject *locationObject = [[NIMLocationObject alloc] initWithLatitude:locationPoint.coordinate.latitude
                                                                          longitude:locationPoint.coordinate.longitude
                                                                              title:locationPoint.title];
    NIMMessage *message               = [[NIMMessage alloc] init];
    message.messageObject             = locationObject;
    message.apnsContent = @"发来了一条位置信息";
    return message;
}


@end
