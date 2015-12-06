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
#import "NIMTipObject.h"
#import "NIMMessageSetting.h"

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
     *  附件需要进行下载 (有附件但并没有下载过)
     */
    NIMMessageAttachmentDownloadStateNeedDownload,
    /**
     *  附件收取失败 (尝试下载过一次并失败)
     */
    NIMMessageAttachmentDownloadStateFailed,
    /**
     *  附件下载中
     */
    NIMMessageAttachmentDownloadStateDownloading,
    /**
     *  附件下载成功/无附件
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
@property (nonatomic,copy)                  NSString *from;

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
 */
@property (nonatomic,copy)                  NSString *text;

/**
 *  消息附件内容
 */
@property (nonatomic,strong)                id<NIMMessageObject> messageObject;


/**
 *  消息设置
 *  @discussion 可以通过这个字段制定当前消息的各种设置,如是否需要计入未读，是否需要多端同步等
 */
@property (nonatomic,strong)                NIMMessageSetting *setting;

/**
 *  消息推送文案,长度限制200字节
 */
@property (nonatomic,copy)                  NSString *apnsContent;

/**
 *  消息推送Payload
 *  @discussion 可以通过这个字段定义消息推送Payload,支持字段参考苹果技术文档,转成JSON后长度限制为2K
 */
@property (nonatomic,strong)                NSDictionary *apnsPayload;

/**
 *  服务器扩展
 *  @discussion 这个字段会发送到其他端,上层需要保证NSDictionary可以转换为JSON,转成JSON后长度限制为1K
 */
@property (nonatomic,strong)                NSDictionary    *remoteExt;

/**
 *  客户端本地扩展
 *  @discussion 当前字段只在本地存储，不会发送至对端,上层需要保证NSDictionary可以转换为JSON
 */
@property (nonatomic,strong)                NSDictionary    *localExt;

/**
 *  消息发送时间
 */
@property (nonatomic,assign,readonly)       NSTimeInterval timestamp;

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
 *  @discussion 由于有漫游消息的概念,所以自己发出的消息漫游下来后仍旧是"收到的消息",这个字段用于消息出错是时判断需要重发还是重收
 */
@property (nonatomic,assign,readonly)       BOOL isReceivedMsg;

/**
 *  是否是往外发的消息
 *  @discussion 由于能对自己发消息，所以并不是所有来源是自己的消息都是往外发的消息，这个字段用于判断头像排版位置（是左还是右）。
 */
@property (nonatomic,assign,readonly)       BOOL isOutgoingMsg;

/**
 *  消息是否被播放过
 *  @discussion 修改这个属性,后台会自动更新db中对应的数据
 */
@property (nonatomic,assign)                BOOL isPlayed;


/**
 *  消息是否标记为已删除
 *  @discussion 已删除的消息在获取本地消息列表时会被过滤掉，只有根据messageId获取消息的接口可能会返回已删除消息。
 */
@property (nonatomic,assign,readonly)       BOOL isDeleted;

/**
 *  消息发送者名字
 *  @discussion 当发送者是自己时,这个值为空,这个值表示的是发送者当前的昵称,而不是发送消息时的昵称
 */
@property (nonatomic,copy,readonly)         NSString *senderName;
@end
