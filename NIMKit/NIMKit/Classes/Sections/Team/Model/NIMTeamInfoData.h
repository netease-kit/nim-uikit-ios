//
//  TeamInfoData.h
//  NIM
//
//  Created by chris on 15/6/1.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import "NIMUsrInfoData.h"


@interface NIMTeamInfoData : NSObject<NIMGroupMemberProtocol>

@property (nonatomic, copy) NSString *teamId;
@property (nonatomic, copy) NSString *iconId;
@property (nonatomic, copy) NSString *teamName;


- (instancetype)initWithTeam:(NIMTeam *)team;

@end
