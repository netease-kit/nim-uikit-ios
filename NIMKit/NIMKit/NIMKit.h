//
//  NIMKit.h
//  NIMKit
//
//  Created by amao on 8/14/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>


//! Project version number for NIMKit.
FOUNDATION_EXPORT double NIMKitVersionNumber;

//! Project version string for NIMKit.
FOUNDATION_EXPORT const unsigned char NIMKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <NIMKit/PublicHeader.h>


#import "NIMSDK.h"

/**
 *  基础Model
 */
#import "NIMKitInfo.h"
#import "NIMMediaItem.h"            //多媒体面板对象
#import "NIMMessageModel.h"         //message Wrapper


/**
 *  协议
 */
#import "NIMKitMessageProvider.h"
#import "NIMCellConfig.h"           //message cell配置协议
#import "NIMInputProtocol.h"        //输入框回调
#import "NIMKitDataProvider.h"      //APP内容提供器
#import "NIMMessageCellProtocol.h"  //message cell事件回调
#import "NIMSessionConfig.h"        //会话页面配置
#import "NIMKitEvent.h"             //点击事件封装类

#import "NIMCellLayoutConfig.h"

/**
 *  消息cell的视觉模板
 */
#import "NIMSessionMessageContentView.h"

/**
 *  会话页
 */
#import "NIMSessionViewController.h"

/**
 *  会话列表页
 */
#import "NIMSessionListViewController.h"


@interface NIMKit : NSObject

+ (instancetype)sharedKit;

/**
 *  注册自定义的排版配置，通过注册自定义排版配置来实现自定义消息的定制化排版
 */
- (void)registerLayoutConfig:(Class)layoutConfigClass;

/**
 *  返回当前的排版配置
 */
- (id<NIMCellLayoutConfig>)layoutConfig;

/**
 *  内容提供者，由上层开发者注入。如果没有则使用默认 provider
 */
@property (nonatomic,strong)    id<NIMKitDataProvider> provider;

/**
 *  NIMKit图片资源所在的 bundle 名称。
 */
@property (nonatomic,copy)      NSString *resourceBundleName;

/**
 *  NIMKit表情资源所在的 bundle 名称。
 */
@property (nonatomic,copy)      NSString *emoticonBundleName;

/**
 *  NIMKit设置资源所在的 bundle 名称。
 */
@property (nonatomic,copy)      NSString *settingBundleName;


/**
 *  用户信息变更通知接口
 *
 *  @param userId 用户id
 */
- (void)notfiyUserInfoChanged:(NSArray *)userIds;

/**
 *  群信息变更通知接口
 *
 *  @param teamId 群id
 */
- (void)notifyTeamInfoChanged:(NSArray *)teamIds;


/**
 *  群成员变更通知接口
 *
 *  @param teamId 群id
 */
- (void)notifyTeamMemebersChanged:(NSArray *)teamIds;

/**
 *  返回用户信息
 */
- (NIMKitInfo *)infoByUser:(NSString *)userId;


/**
 *  返回用户在会话中需要显示的信息
 */
- (NIMKitInfo *)infoByUser:(NSString *)userId
                 inSession:(NIMSession *)session;

/**
 *  返回用户在某条消息中需要显示的信息
 */
- (NIMKitInfo *)infoByUser:(NSString *)userId
               withMessage:(NIMMessage *)message;

/**
 *  返回群信息
 */
- (NIMKitInfo *)infoByTeam:(NSString *)teamId;

@end



