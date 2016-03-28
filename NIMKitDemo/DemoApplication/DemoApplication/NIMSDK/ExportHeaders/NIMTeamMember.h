//
//  NIMTeamMember.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  群成员类型
 */
typedef NS_ENUM(NSInteger, NIMTeamMemberType){
    /**
     *  普通群员
     */
    NIMTeamMemberTypeNormal = 0,
    /**
     *  群拥有者
     */
    NIMTeamMemberTypeOwner = 1,
    /**
     *  群管理员
     */
    NIMTeamMemberTypeManager = 2,
    /**
     *  申请加入用户
     */
    NIMTeamMemberTypeApply   = 3,
};


/**
 *  群成员信息
 */
@interface NIMTeamMember : NSObject
/**
 *  群ID
 */
@property (nonatomic,copy,readonly)         NSString *teamId;

/**
 *  群成员ID
 */
@property (nonatomic,copy,readonly)         NSString *userId;

/**
 *  邀请者ID, 此字段仅当该成员为自己时有效。不允许查看其他群成员的邀请者；当自己为建群者时，邀请者ID为0。
 */
@property (nonatomic,copy,readonly)         NSString *invitor;

/**
 *  群成员类型
 */
@property (nonatomic,assign)                NIMTeamMemberType  type;


/**
 *  群昵称
 */
@property (nonatomic,copy)                  NSString *nickname;

@end