//
//  NIMTeamMemberListDataSource.h
//  NIMKit
//
//  Created by Netease on 2019/6/17.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMCardMemberItem.h"
#import "NIMMembersFetchOption.h"

typedef void(^NIMTeamListDataBlock)(NSError * _Nullable error, NSString * _Nullable msg);

NS_ASSUME_NONNULL_BEGIN

@protocol NIMTeamMemberListDataSource <NSObject>

- (NIMSession *)session;

- (NSInteger)memberNumber;

- (NSMutableArray <NIMTeamCardMemberItem *> *)datas;

- (NIMTeamCardMemberItem *)myCard;

//身份显示字符串
- (NSString *)memberTypeString:(NIMKitTeamMemberType)type;

//查询群成员
- (void)fetchTeamMembersWithOption:(NIMMembersFetchOption * _Nullable )option
                        completion:(NIMTeamListDataBlock)completion;

//踢人
- (void)kickUsers:(NSArray *)userIds
       completion:(NIMTeamListDataBlock)completion;

//修改用户昵称
- (void)updateUserNick:(NSString *)userId
                  nick:(NSString *)nick
            completion:(NIMTeamListDataBlock)completion;

//修改用户禁言状态
- (void)updateUserMuteState:(NSString *)userId
                       mute:(BOOL)mute
                 completion:(NIMTeamListDataBlock)completion;

//增加管理员
- (void)addManagers:(NSArray *)userIds
         completion:(NIMTeamListDataBlock)completion;

//移除管理员
- (void)removeManagers:(NSArray *)userIds
            completion:(NIMTeamListDataBlock)completion;

//群通知状态修改
- (void)updateTeamNotifyState:(NIMKitTeamNotifyState)state
                   completion:(NIMTeamListDataBlock)completion;

//查询群通知状态
- (NIMKitTeamNotifyState)notifyState;

@end

NS_ASSUME_NONNULL_END
