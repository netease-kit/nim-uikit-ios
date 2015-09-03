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
- (void)notfiyUserInfoChanged:(NSString *)userId;

/**
 *  群信息变更通知接口
 *
 *  @param teamId 群id
 */
- (void)notfiyTeamInfoChanged:(NSString *)teamId;

@end

@interface NIMKit(Private)
//这两个接口是NIMKit内部调用的。
//用户应该自己实现获取用户及群组信息方法，并注入到NIMKit的provider属性中，而不是调用这两个接口，靠NIMKit来获取用户信息。
- (NIMKitInfo *)infoByUser:(NSString *)userId;
- (NIMKitInfo *)infoByTeam:(NSString *)teamId;
@end



@interface NIMKitInfo : NSObject
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

extern NSString *const NIMKitUserInfoHasUpdatedNotification;
extern NSString *const NIMKitTeamInfoHasUpdatedNotification;
extern NSString *const NIMKitInfoKey;