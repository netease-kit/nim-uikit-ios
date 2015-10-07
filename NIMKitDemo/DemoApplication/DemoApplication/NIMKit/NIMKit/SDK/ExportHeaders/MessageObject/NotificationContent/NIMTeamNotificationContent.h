//
//  NIMTeamNotificationContent.h
//  NIMLib
//
//  Created by Netease
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMNotificationContent.h"


/**
 *  群操作类型
 */
typedef NS_ENUM(NSInteger, NIMTeamOperationType){
    /**
     *  邀请成员
     */
    NIMTeamOperationTypeInvite          = 0,
    /**
     *  移除成员
     */
    NIMTeamOperationTypeKick            = 1,
    /**
     *  离开群
     */
    NIMTeamOperationTypeLeave           = 2,
    /**
     *  更新群信息
     */
    NIMTeamOperationTypeUpdate          = 3,
    /**
     *  解散群
     */
    NIMTeamOperationTypeDismiss         = 4,
    /**
     *  高级群申请加入成功
     */
    NIMTeamOperationTypeApplyPass       = 5,
    /**
     *  高级群群主转移群主身份
     */
    NIMTeamOperationTypeTransferOwner   = 6,
    /**
     *  添加管理员
     */
    NIMTeamOperationTypeAddManager      = 7,
    /**
     *  移除管理员
     */
    NIMTeamOperationTypeRemoveManager   = 8,
    /**
     *  高级群接受邀请进群
     */
    NIMTeamOperationTypeAcceptInvitation= 9,
    
};


/**
 *  群信息修改字段
 */
typedef NS_ENUM(NSInteger, NIMTeamUpdateTag){
    /**
     *  群名
     */
    NIMTeamUpdateTagName            = 3,
    /**
     *  群简介
     */
    NIMTeamUpdateTagIntro           = 14,
    /**
     *  群公告
     */
    NIMTeamUpdateTagAnouncement     = 15,
    /**
     *  群验证方式
     */
    NIMTeamUpdateTagJoinMode        = 16,
    /**
     *  客户端自定义拓展字段
     */
    NIMTeamUpdateTagClientCustom    = 18,
    /**
     *  服务器自定义拓展字段
     *  @discussion SDK 无法直接修改这个字段
     */
    NIMTeamUpdateTagServerCustom    = 19,
    
};



/**
 *  群通知内容
 */
@interface NIMTeamNotificationContent : NIMNotificationContent
/**
 *  操作发起者ID
 */
@property (nonatomic,copy,readonly)     NSString    *sourceID;

/**
 *  操作类型
 */
@property (nonatomic,assign,readonly)   NIMTeamOperationType  operationType;

/**
 *  被操作者ID列表
 */
@property (nonatomic,strong,readonly)   NSArray *targetIDs;

/**
 *  额外信息
 *  @discussion 目前只有群信息更新才有attachment,attachment为NIMUpdateTeamInfoAttachment
 */
@property (nonatomic,strong,readonly)   id attachment;
@end


/**
 *  更新群信息的额外信息
 */
@interface NIMUpdateTeamInfoAttachment : NSObject

/**
 *  群内修改的信息键值对
 */
@property (nonatomic,strong,readonly)   NSDictionary    *values;
@end

