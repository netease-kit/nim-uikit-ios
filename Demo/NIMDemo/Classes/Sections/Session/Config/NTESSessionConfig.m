//
//  NTESSessionConfig.m
//  NIM
//
//  Created by amao on 8/11/15.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import "NTESSessionConfig.h"
#import "NIMMediaItem.h"
#import "NTESBundleSetting.h"
#import "NTESSnapchatAttachment.h"
#import "NTESWhiteboardAttachment.h"
#import "NTESBundleSetting.h"
#import "NIMKitUIConfig.h"

@interface NTESSessionConfig()

@end

@implementation NTESSessionConfig

- (NSArray *)mediaItems
{
    NSArray *defaultMediaItems = [NIMKitUIConfig sharedConfig].defaultMediaItems;
    
    NIMMediaItem *janKenPon = [NIMMediaItem item:@"onTapMediaItemJanKenPon:"
                                     normalImage:[UIImage imageNamed:@"icon_jankenpon_normal"]
                                   selectedImage:[UIImage imageNamed:@"icon_jankenpon_pressed"]
                                           title:@"石头剪刀布"];
    
    NIMMediaItem *fileTrans = [NIMMediaItem item:@"onTapMediaItemFileTrans:"
                                                normalImage:[UIImage imageNamed:@"icon_file_trans_normal"]
                                              selectedImage:[UIImage imageNamed:@"icon_file_trans_pressed"]
                                           title:@"文件传输"];
    
    NIMMediaItem *tip       = [NIMMediaItem item:@"onTapMediaItemTip:"
                                     normalImage:[UIImage imageNamed:@"bk_media_tip_normal"]
                                   selectedImage:[UIImage imageNamed:@"bk_media_tip_pressed"]
                                           title:@"提醒消息"];
    
    NIMMediaItem *audioChat =  [NIMMediaItem item:@"onTapMediaItemAudioChat:"
                                      normalImage:[UIImage imageNamed:@"btn_media_telphone_message_normal"]
                                    selectedImage:[UIImage imageNamed:@"btn_media_telphone_message_pressed"]
                                           title:@"实时语音"];
    
    NIMMediaItem *videoChat =  [NIMMediaItem item:@"onTapMediaItemVideoChat:"
                                      normalImage:[UIImage imageNamed:@"btn_bk_media_video_chat_normal"]
                                    selectedImage:[UIImage imageNamed:@"btn_bk_media_video_chat_pressed"]
                                            title:@"视频聊天"];
    
    NIMMediaItem *snapChat =   [NIMMediaItem item:@"onTapMediaItemSnapChat:"
                                      normalImage:[UIImage imageNamed:@"bk_media_snap_normal"]
                                    selectedImage:[UIImage imageNamed:@"bk_media_snap_pressed"]
                                            title:@"阅后即焚"];

    NIMMediaItem *whiteBoard = [NIMMediaItem item:@"onTapMediaItemWhiteBoard:"
                                      normalImage:[UIImage imageNamed:@"btn_whiteboard_invite_normal"]
                                    selectedImage:[UIImage imageNamed:@"btn_whiteboard_invite_pressed"]
                                            title:@"白板"];
    
    
    BOOL isMe   = _session.sessionType == NIMSessionTypeP2P
    && [_session.sessionId isEqualToString:[[NIMSDK sharedSDK].loginManager currentAccount]];
    NSArray *items = @[];
    if (_session.sessionType != NIMSessionTypeTeam && !isMe)
    {
        items = @[janKenPon,audioChat,videoChat,fileTrans,snapChat,whiteBoard,tip];
    }
    else
    {
        items = @[janKenPon,fileTrans,tip];
    }

    return [defaultMediaItems arrayByAddingObjectsFromArray:items];
    
}

- (BOOL)shouldHandleReceipt{
    return YES;
}

- (BOOL)shouldHandleReceiptForMessage:(NIMMessage *)message
{
    //文字，语音，图片，视频，文件，地址位置和自定义消息都支持已读回执，其他的不支持
    NIMMessageType type = message.messageType;
    if (type == NIMMessageTypeCustom) {
        NIMCustomObject *object = (NIMCustomObject *)message.messageObject;
        id attachment = object.attachment;
        
        if ([attachment isKindOfClass:[NTESWhiteboardAttachment class]]) {
            return NO;
        }
    }
    
    
    
    return type == NIMMessageTypeText ||
           type == NIMMessageTypeAudio ||
           type == NIMMessageTypeImage ||
           type == NIMMessageTypeVideo ||
           type == NIMMessageTypeFile ||
           type == NIMMessageTypeLocation ||
           type == NIMMessageTypeCustom;
}

- (BOOL)disableProximityMonitor{
    return [[NTESBundleSetting sharedConfig] disableProximityMonitor];
}

- (NIMAudioType)recordType
{
    return [[NTESBundleSetting sharedConfig] usingAmr] ? NIMAudioTypeAMR : NIMAudioTypeAAC;
}

@end
