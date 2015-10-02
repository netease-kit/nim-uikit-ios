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

@interface NIMUserCardMemberItem : NSObject<NIMKitCardHeaderData>

- (instancetype)initWithUserId:(NSString*)userId;

@end

@interface NIMTeamCardMemberItem : NSObject<NIMKitCardHeaderData>

@property (nonatomic, assign) NIMTeamMemberType type;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, strong) NIMTeam *team;

- (instancetype)initWithMember:(NIMTeamMember*)member;

@end
