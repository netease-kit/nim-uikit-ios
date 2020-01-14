//
//  NIMTeamListDataManager.h
//  NIMKit
//
//  Created by Netease on 2019/6/17.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import "NIMTeamMemberListDataSource.h"


extern NSString * _Nonnull const kNIMTeamListDataTeamInfoUpdate;
extern NSString * _Nonnull const kNIMTeamListDataTeamMembersChanged;

NS_ASSUME_NONNULL_BEGIN

@interface NIMTeamListDataManager : NSObject<NIMTeamMemberListDataSource>

//当前群
@property (nonatomic, readonly) NIMTeam *team;

//自己的帐号
@property (nonatomic, readonly) NSString *myAccount;

//自己的群成员信息
@property (nonatomic, readonly) NIMTeamMember *myTeamInfo;

//所有群成员的id
@property (nonatomic, readonly) NSMutableArray <NSString *>*memberIds;

//初始化
- (instancetype)initWithTeam:(NIMTeam *)team session:(NIMSession *)session;

//更新个人群组信息
- (void)reloadMyTeamInfo;

@end

NS_ASSUME_NONNULL_END
