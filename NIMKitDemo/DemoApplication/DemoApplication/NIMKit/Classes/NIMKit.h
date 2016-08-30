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


@class NIMKitInfo;

@interface NIMKit : NSObject

+ (instancetype)sharedKit;

/**
 *  内容提供者，由上层开发者注入。
 */
@property (nonatomic,strong)    id<NIMKitDataProvider> provider;

/**
 *  NIMKit资源所在的bundle名称。
 */
@property (nonatomic,copy)      NSString *bundleName;


/**
 *  用户信息变更通知接口
 *
 *  @param userId 用户id
 */
- (void)notfiyUserInfoChanged:(NSArray *)userIds;


/**
 *  用户黑名单变更通知接口
 *
 *  @param userId 用户id
 */
- (void)notifyUserBlackListChanged;


/**
 *  用户静音列表变更通知接口
 */
- (void)notifyUserMuteListChanged;

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

@end

@interface NIMKit(Private)
- (NIMKitInfo *)infoByUser:(NSString *)userId;

- (NIMKitInfo *)infoByUser:(NSString *)userId
                 inSession:(NIMSession *)session;

- (NIMKitInfo *)infoByTeam:(NSString *)teamId;

- (NIMKitInfo *)infoByUser:(NSString *)userId
               withMessage:(NIMMessage *)message;

@end



@interface NIMKitInfo : NSObject
/**
 *   id,如果是用户信息，为用户id；如果是群信息，为群id
 */
@property (nonatomic,copy) NSString *infoId;

/**
 *  显示名
 */
@property (nonatomic,copy)   NSString *showName;


//如果avatarUrlString为nil，则显示头像图片
//如果avatarUrlString不为nil,则将头像图片当做占位图，当下载完成后显示头像url指定的图片。

/**
 *  头像url
 */
@property (nonatomic,copy)   NSString *avatarUrlString;

/**
 *  头像图片
 */
@property (nonatomic,strong) UIImage  *avatarImage;

@end

/**
 *  用户信息变更通知
 */
extern NSString *const NIMKitUserInfoHasUpdatedNotification;

/**
 *  群组信息变更通知
 */
extern NSString *const NIMKitTeamInfoHasUpdatedNotification;

/**
 *  黑名单更新通知
 */
extern NSString *const NIMKitUserBlackListHasUpdatedNotification;

/**
 *  静音列表更新通知
 */
extern NSString *const NIMKitUserMuteListHasUpdatedNotification;

/**
 *  群组成员变更通知
 */
extern NSString *const NIMKitTeamMembersHasUpdatedNotification;

/**
 *  聊天室成员信息变更通知
 */
extern NSString *const NIMKitChatroomMemberInfoHasUpdatedNotification;


extern NSString *const NIMKitInfoKey;
extern NSString *const NIMKitChatroomMembersKey;
