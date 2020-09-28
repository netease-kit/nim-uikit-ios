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
    [self setupMessage:textMessage];
    return textMessage;
}

+ (NIMMessage*)msgWithAudio:(NSString*)filePath
{
    NIMAudioObject *audioObject = [[NIMAudioObject alloc] initWithSourcePath:filePath scene:NIMNOSSceneTypeMessage];
    NIMMessage *message = [[NIMMessage alloc] init];
    message.messageObject = audioObject;
    message.text = @"发来了一段语音".nim_localized;
    [self setupMessage:message];
    return message;
}

+ (NIMMessage*)msgWithVideo:(NSString*)filePath
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    NIMVideoObject *videoObject = [[NIMVideoObject alloc] initWithSourcePath:filePath scene:NIMNOSSceneTypeMessage];
    videoObject.displayName = [NSString stringWithFormat:@"视频发送于%@".nim_localized,dateString];
    NIMMessage *message = [[NIMMessage alloc] init];
    message.messageObject = videoObject;
    message.apnsContent = @"发来了一段视频".nim_localized;
    [self setupMessage:message];
    return message;
}

+ (NIMMessage*)msgWithImage:(UIImage*)image
{
    NIMImageObject *imageObject = [[NIMImageObject alloc] initWithImage:image scene:NIMNOSSceneTypeMessage];
    NIMImageOption *option  = [[NIMImageOption alloc] init];
    option.compressQuality  = 0.7;
    imageObject.option      = option;
    return [NIMMessageMaker generateImageMessage:imageObject];
}

+ (NIMMessage *)msgWithImagePath:(NSString*)path
{
    NIMImageObject * imageObject = [[NIMImageObject alloc] initWithFilepath:path scene:NIMNOSSceneTypeMessage];
    return [NIMMessageMaker generateImageMessage:imageObject];
}

+ (NIMMessage *)msgWithImageData:(NSData *)data extension:(NSString *)extension
{
    NIMImageObject *imageObject = [[NIMImageObject alloc] initWithData:data extension:extension];
    return [NIMMessageMaker generateImageMessage:imageObject];
}

+ (NIMMessage *)generateImageMessage:(NIMImageObject *)imageObject
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    imageObject.displayName = [NSString stringWithFormat:@"图片发送于%@".nim_localized,dateString];
    NIMMessage *message     = [[NIMMessage alloc] init];
    message.messageObject   = imageObject;
    message.apnsContent = @"发来了一张图片".nim_localized;
    [self setupMessage:message];
    return message;
}


+ (NIMMessage*)msgWithLocation:(NIMKitLocationPoint *)locationPoint{
    NIMLocationObject *locationObject = [[NIMLocationObject alloc] initWithLatitude:locationPoint.coordinate.latitude
                                                                          longitude:locationPoint.coordinate.longitude
                                                                              title:locationPoint.title];
    NIMMessage *message               = [[NIMMessage alloc] init];
    message.messageObject             = locationObject;
    message.apnsContent = @"发来了一条位置信息".nim_localized;
    [self setupMessage:message];
    return message;
}

+ (void)setupMessage:(NIMMessage *)message
{
    message.apnsPayload = @{
        @"apns-collapse-id": message.messageId,
    };
    
    NIMMessageSetting *setting = [[NIMMessageSetting alloc] init];
    setting.scene = NIMNOSSceneTypeMessage;
    message.setting = setting;
    message.env = [[NSUserDefaults standardUserDefaults] objectForKey:@"nim_test_msg_env"];
}


@end


@implementation NIMCommentMaker

+ (NIMQuickComment *)commentWithType:(int64_t)type
                             content:(NSString *)content
                                 ext:(NSString *)ext
{
    NIMQuickComment *comment = [[NIMQuickComment alloc] init];
    comment.ext = ext;
    NIMQuickCommentSetting *setting = [[NIMQuickCommentSetting alloc] init];
    setting.needPush = YES;
    setting.needBadge = YES;
    setting.pushTitle = @"你收到了一条快捷评论";
    setting.pushContent = content;
    setting.pushPayload = @{
        @"key" : @"value"
    };
    comment.setting = setting;
    comment.replyType = type;
    return comment;
}

@end
