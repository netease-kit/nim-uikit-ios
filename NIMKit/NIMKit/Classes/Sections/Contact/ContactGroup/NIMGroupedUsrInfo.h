//
//  NIMGroupedUsrInfo.h
//  NIM
//
//  Created by Xuhui on 15/3/24.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMContactDefines.h"


@interface NIMGroupUser:NSObject<NIMGroupMemberProtocol>

- (instancetype)initWithUserId:(NSString *)userId;

@end

@interface NIMGroupTeamMember:NSObject<NIMGroupMemberProtocol>

- (instancetype)initWithUserId:(NSString *)userId teamId:(NSString *)teamId;

@end


@interface NIMGroupTeam:NSObject<NIMGroupMemberProtocol>

- (instancetype)initWithTeam:(NSString *)teamId;

@end


