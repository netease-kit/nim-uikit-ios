//
//  NIMSDKConfig.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class NIMNotificationObject;

/**
 *  SDK 配置委托
 */
@protocol NIMSDKConfigDelegate <NSObject>

@optional

/**
 *  是否需要忽略某个通知
 *
 *  @param notification 通知对象
 *
 *  @return 是否通知
 */
- (BOOL)shouldIgnoreNotification:(NIMNotificationObject *)notification;

@end

/**
 *  NIM SDK 配置项目
 */
@interface NIMSDKConfig : NSObject

/**
 *  返回配置项实例
 *
 *  @return 配置项
 */
+ (instancetype)sharedConfig;


/**
 *  是否在收到消息后自动下载附件 (群和个人)
 *  @discussion 默认为YES,SDK会在第一次收到消息是直接下载消息附件,上层开发可以根据自己的需要进行设置
 */
@property (nonatomic,assign)    BOOL    fetchAttachmentAutomaticallyAfterReceiving;


/**
 *  是否在收到聊天室消息后自动下载附件
 *  @discussion 默认为NO
 */
@property (nonatomic,assign)    BOOL    fetchAttachmentAutomaticallyAfterReceivingInChatroom;


/**
 *  是否使用 NSFileProtectionNone 作为云信文件的 NSProtectionKey
 *  @discussion 默认为 NO，只有在上层 APP 开启了 Data Protection 时才起效
 */
@property (nonatomic,assign)    BOOL    fileProtectionNone;

/**
 *  配置项委托
 */
@property (nullable,nonatomic,weak)    id<NIMSDKConfigDelegate>    delegate;

/**
 *  设置 SDK 根目录
 *
 *  @param sdkDir SDK 根目录
 *  @discussion 设置该值后 SDK 产生的数据(包括聊天记录，但不包括临时文件)都将放置在这个目录下，如果不设置，所有数据将放置于 $Document/NIMSDK目录下
 *              该配置项必须在 NIMSDK 任一一个 sharedSDK 方法调用之前调用，否则配置无法生效
 */
- (void)setupSDKDir:(NSString *)sdkDir;
@end


NS_ASSUME_NONNULL_END