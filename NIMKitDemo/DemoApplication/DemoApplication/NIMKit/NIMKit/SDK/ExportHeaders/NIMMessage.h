//
//  NIMMessage.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMGlobalDefs.h"
#import "NIMSession.h"
#import "NIMImageObject.h"
#import "NIMLocationObject.h"
#import "NIMAudioObject.h"
#import "NIMCustomObject.h"
#import "NIMVideoObject.h"
#import "NIMFileObject.h"
#import "NIMNotificationObject.h"

/**
 *  消息送达状态枚举
 */
typedef NS_ENUM(NSInteger, NIMMessageDeliveryState){
    /**
     *  消息发送失败
     */
    NIMMessageDeliveryStateFailed,
    /**
     *  消息发送中
     */
    NIMMessageDeliveryStateDelivering,
    /**
     *  消息发送成功
     */
    NIMMessageDeliveryStateDeliveried
};

/**
 *  消息附件下载状态
 */
typedef NS_ENUM(NSInteger, NIMMessageAttachmentDownloadState){
    /**
     *  附件收取失败
     */
    NIMMessageAttachmentDownloadStateFailed,
    /**
     *  附件收取中
     */
    NIMMessageAttachmentDownloadStateDownloading,
    /**
     *  附件下载成功
     */
    NIMMessageAttachmentDownloadStateDownloaded
};




/**
 *  消息体协议
 */
@protocol NIMMessageObject;
/**
 *  消息结构
 */
@interface NIMMessage : NSObject

/**
 *  消息类型
 */
@property (nonatomic,assign,readonly)       NIMMessageType messageType;

/**
 *  消息来源
 */
@property (nonatomic,copy,readonly)         NSString *from;

/**
 *  消息所属会话
 */
@property (nonatomic,strong,readonly)       NIMSession *session;

/**
 *  消息ID,唯一标识
 */
@property (nonatomic,copy,readonly)         NSString *messageId;

/**
 *  消息文本
 *  @discussion 对于非文本消息，这个字段用于推送信息的显示
 */
@property (nonatomic,copy,readwrite)         NSString *text;

/**
 *  消息附件内容
 */
@property (nonatomic,strong,readwrite)       id<NIMMessageObject> messageObject;

/**
 *  消息发送时间
 */
@property (nonatomic,assign,readwrite)       NSTimeInterval timestamp;

/**
 *  消息投递状态 仅针对发送的消息
 */
@property (nonatomic,assign,readonly)       NIMMessageDeliveryState deliveryState;


/**
 *  消息附件下载状态 仅针对收到的消息
 */
@property (nonatomic,assign,readonly)       NIMMessageAttachmentDownloadState attachmentDownloadState;


/**
 *  是否是收到的消息
 *  @discussion 由于有漫游消息的概念,所以自己发出的消息漫游下来后仍旧是"收到的消息",这个字段用于消息出错是时用于判断需要重发还是重收
 */
@property (nonatomic,assign,readonly)       BOOL isReceivedMsg;

/**
 *  是否是往外发的消息
 *  @discussion 是否是发出去的消息，由于"我的电脑"的存在，所以并不是所有from = 自己的消息都是outgoingMsg，这个字段用于判断头像排版位置。
 */
@property (nonatomic,assign,readonly)       BOOL isOutgoingMsg;

/**
 *  消息是否被播放过
 *  @discussion 修改这个属性,后台会自动更新db中对应的数据
 */
@property (nonatomic,assign,readwrite)      BOOL isPlayed;

/**
 *  消息发送者名字
 *  @discussion 当发送者是自己时,这个值为空,这个值表示的是发送者当前的昵称,而不是发送消息时的昵称
 */
@property (nonatomic,copy,readonly)         NSString *senderName;
@end
