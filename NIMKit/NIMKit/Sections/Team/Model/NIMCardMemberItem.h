//
//  NTESTeamCardMemberItem.h
//  NIM
//
//  Created by chris on 15/3/5.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMCardDataSourceProtocol.h"

@class NIMUsrInfo;

/**
 *  普通用户member,只显示默认昵称
 */
@interface NIMUserCardMemberItem : NSObject<NIMKitCardHeaderData>

- (instancetype)initWithUserId:(NSString*)userId;

@end


/**
 *  team member，优先显示 team 昵称，并且存储一些群成员的权限级别
 */
@interface NIMTeamCardMemberItem : NSObject<NIMKitCardHeaderData>

@property (nonatomic, assign) NIMTeamMemberType type;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, strong) NIMTeam *team;
@property (nonatomic, readonly, strong) NIMTeamMember *member;

- (instancetype)initWithMember:(NIMTeamMember*)member;

@end
