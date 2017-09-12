//
//  NIMMessageMaker.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMMessageMaker.h"
#import "NSString+NIMKit.h"
#import "NIMKitLocationPoint.h"
#import "NIMKit.h"
#import "NIMInputAtCache.h"

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
    NIMImageObject *imageObject = [[NIMImageObject alloc] initWithImage:image];
    NIMImageOption *option  = [[NIMImageOption alloc] init];
    option.compressQuality  = 0.7;
    imageObject.option      = option;
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

+ (NIMMessage *)msgWithRobotQuery:(NSString *)text
                          toRobot:(NSString *)robotId
{
    NIMMessage *queryMessage = [[NIMMessage alloc] init];
    //要在界面上显示的消息
    queryMessage.text        = text;
    
    NSString *robotContent = [[NIMKit sharedKit] infoByUser:robotId option:nil].showName;
    NSString *content = [text stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@%@%@",NIMInputAtStartChar,robotContent,NIMInputAtEndChar] withString:@""];
    // bot 服务不接受空字符串，当上层没有查询的时候，发送长度为 1 的空格 （这个由上层交互自己定义）
    content = content.length? content : @" ";
    NIMRobotObject *object     = [[NIMRobotObject alloc] initWithRobot:content robotId:robotId];
    queryMessage.messageObject = object;
    return queryMessage;
}

+ (NIMMessage *)msgWithRobotSelect:(NSString *)text
                            target:(NSString *)target
                            params:(NSString *)params
                           toRobot:(NSString *)robotId
{
    NIMMessage *queryMessage   = [[NIMMessage alloc] init];
    NIMRobotObject *object     = [[NIMRobotObject alloc] initWithRobotId:robotId target:target param:params];
    queryMessage.messageObject = object;
    queryMessage.text        = text;
    return queryMessage;
}


@end
