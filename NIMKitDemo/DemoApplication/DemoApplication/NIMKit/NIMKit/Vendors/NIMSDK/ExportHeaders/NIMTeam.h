//
//  NIMTeam.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  群类型
 */
typedef NS_ENUM(NSInteger, NIMTeamType){
    /**
     *  普通群
     */
    NIMTeamTypeNormal       = 0,
    /**
     *  高级群
     */
    NIMTeamTypeAdvanced     = 1,
};

/**
 *  群验证方式
 */
typedef NS_ENUM(NSInteger, NIMTeamJoinMode) {
    /**
     *  允许所有人加入
     */
    NIMTeamJoinModeNoAuth    = 0,
    /**
     *  需要验证
     */
    NIMTeamJoinModeNeedAuth  = 1,
    /**
     *  不允许任何人加入
     */
    NIMTeamJoinModeRejectAll = 2,
};


/**
 *  申请入群状态
 */
typedef NS_ENUM(NSInteger, NIMTeamApplyStatus) {
    /**
     *  无效状态
     */
    NIMTeamApplyStatusInvalid,
    /**
     *  已经在群里
     */
    NIMTeamApplyStatusAlreadyInTeam,
    /**
     *  申请等待通过
     */
    NIMTeamApplyStatusWaitForPass,
    
};

/**
 *  创建群选项
 */
@interface NIMCreateTeamOption : NSObject
/**
 *  群名
 *  @discussion 这个参数不能省略
 */
@property (nonatomic,copy)      NSString        *name;
/**
 *  群类型
 *  @discussion 默认为普通群
 */
@property (nonatomic,assign)    NIMTeamType     type;

/**
 *  群简介
 */
@property (nonatomic,copy)      NSString        *intro;

/**
 *  群公告
 */
@property (nonatomic,copy)      NSString        *announcement;

/**
 *  客户端自定义信息
 */
@property (nonatomic,copy)      NSString        *clientCustomInfo;

/**
 *  邀请他人的附言
 *  @discussion 当创建的群为高级群需要带上,普通群没有认证过程,所以不需要
 */
@property (nonatomic,copy)      NSString        *postscript;

/**
 *  群验证模式
 *  @discussion 只有高级群才有群验证模式,普通群一律不需要验证
 */
@property (nonatomic,assign)    NIMTeamJoinMode joinMode;


@end



/**
 *  群组信息
 */
@interface NIMTeam : NSObject
/**
 *  群ID
 */
@property (nonatomic,copy,readonly)      NSString *teamId;

/**
 *  群名称
 */
@property (nonatomic,copy)               NSString *teamName;

/**
 *  群类型
 */
@property (nonatomic,assign,readonly)    NIMTeamType type;

/**
 *  群拥有者ID
 *  @discussion 普通群拥有者就是群创建者,但是高级群可以进行拥有信息的转让
 */
@property (nonatomic,copy,readonly)      NSString *owner;

/**
 *  群介绍
 */
@property (nonatomic,copy)              NSString *intro;

/**
 *  群公告
 */
@property (nonatomic,copy)              NSString *announcement;

/**
 *  群成员人数
 *  @discussion 这个值表示是上次登录后同步下来群成员数据,并不实时变化,必要时需要调用fetchTeamInfo:completion:进行刷新
 */
@property (nonatomic,assign,readonly)   NSInteger memberNumber;

/**
 *  群等级
 *  @discussion 目前群人数主要是限制群人数上限
 */
@property (nonatomic,assign,readonly)    NSInteger level;

/**
 *  群创建时间
 */
@property (nonatomic,assign,readonly)    NSTimeInterval createTime;


/**
 *  群验证方式
 */
@property (nonatomic,assign)   NIMTeamJoinMode joinMode;


/**
 *  群服务端自定义信息
 *  @discussion 应用方可以自行拓展这个字段做个性化配置,客户端不可以修改这个字段
 */
@property (nonatomic,copy,readonly)      NSString *serverCustomInfo;


/**
 *  群客户端自定义信息
 *  @discussion 应用方可以自行拓展这个字段做个性化配置,客户端可以修改这个字段
 */
@property (nonatomic,copy,readonly)     NSString *clientCustomInfo;


/**
 *  群消息是否需要通知
 *  @discussion 这个设置影响群消息的APNS推送
 */
@property (nonatomic,assign,readonly)   BOOL notifyForNewMsg;



@end


