//
//  NTESGroupedUsrInfo.h
//  NIM
//
//  Created by Xuhui on 15/3/24.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESGroupedDataCollection.h"

@interface NTESGroupedUsrInfo : NTESGroupedDataCollection

- (instancetype)initWithContacts:(NSArray *)contacts;

@end


@interface NTESGroupedTeamInfo : NTESGroupedDataCollection

- (instancetype)initWithTeams:(NSArray *)teams;

@end
