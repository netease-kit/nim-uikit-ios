//
//  NTESTeamCardMemberItem.h
//  NIM
//
//  Created by chris on 15/3/5.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMCardDataSourceProtocol.h"


@interface NIMCardMemberItem : NSObject<NIMKitCardHeaderData>

@property (nonatomic, copy) NSString *userId;

@property (nonatomic, assign) NIMKitTeamMemberType userType;

+ (NIMKitTeamMemberType)showTypeWithTeamMemberType:(NIMTeamMemberType)type;

@end


@interface NIMUserCardMemberItem : NIMCardMemberItem

@property (nonatomic, assign) BOOL isMyUserId;

- (instancetype)initWithTeamMember:(NIMTeamMember *)member;

- (instancetype)initWithSuperTeamMember:(NIMTeamMember *)member;

@end

#pragma mark - Team Card Member Item
/**
 *  team member，优先显示 team 昵称，并且存储一些群成员的权限级别
 */
@interface NIMTeamCardMemberItem : NIMCardMemberItem

@property (nonatomic, copy) NSString *teamId;

@property (nonatomic, copy) NSString *inviterAccid;

@property (nonatomic, assign) NIMKitTeamCardType teamType;

@property (nonatomic, assign) BOOL isMute;

- (instancetype)initWithTeamId:(NSString *)teamId
                        member:(NIMTeamMember *)member;

- (instancetype)initWithSuperTeamId:(NSString *)teamId
                             member:(NIMTeamMember *)member;

@end


