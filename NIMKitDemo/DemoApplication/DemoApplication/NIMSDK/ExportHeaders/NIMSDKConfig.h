//
//  NIMSDKConfig.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

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
 *  是否在收到消息后自动下载附件
 *  @discussion 默认为YES,SDK会在第一次收到消息是直接下载消息附件,上层开发可以根据自己的需要进行设置
 */
@property (nonatomic,assign)    BOOL    fetchAttachmentAutomaticallyAfterReceiving;


/**
 *  是否托管好友信息
 *  @discussion 默认为 YES，SDK 默认上层应用托管了好友信息,会尝试从服务器和本地获取好友信息。如果应用确认不托管好友资料信息，可以将这个值设为 NO，使得 SDK 可以忽略很多耗费流量和 CPU 的操作。
 */
@property (nonatomic,assign)    BOOL    hostUserInfos;

/**
 *  是否使用 NSFileProtectionNone 作为云信文件的 NSProtectionKey
 *  @discussion 默认为 NO，只有在上层 APP 开启了 Data Protection 时才起效
 */
@property (nonatomic,assign)    BOOL    fileProtectionNone;

/**
 *  设置 SDK 根目录
 *
 *  @param sdkDir SDK 根目录
 *  @discussion 设置该值后 SDK 产生的数据(包括聊天记录，但不包括临时文件)都将放置在这个目录下，如果不设置，所有数据将放置于 $Document/NIMSDK目录下
 *              该配置项必须在 NIMSDK 任一一个 sharedSDK 方法调用之前调用，否则配置无法生效
 */
- (void)setupSDKDir:(NSString *)sdkDir;
@end
