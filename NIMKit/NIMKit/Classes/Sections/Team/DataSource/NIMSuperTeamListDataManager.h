//
//  NIMSuperTeamListDataManager.h
//  NIMKit
//
//  Created by Netease on 2019/6/17.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import "NIMTeamMemberListDataSource.h"
#import "NIMMembersFetchOption.h"

NS_ASSUME_NONNULL_BEGIN

@interface NIMSuperTeamListDataManager : NSObject<NIMTeamMemberListDataSource>

@property (nonatomic, readonly) NIMTeam *team;

@property (nonatomic, readonly) NIMTeamMember *myTeamInfo;

@property (nonatomic, readonly) NSString *myAccount;

@property (nonatomic, readonly) NSArray <NIMTeamMember *> *members;

@property (nonatomic, readonly) NSMutableArray <NSString *>*memberIds;

//消息通知显示字符串
@property (nonatomic, readonly) NSString *notifyStateText;

//所有消息通知显示信息
@property (nonatomic, readonly) NSArray <NSDictionary *> *allNotifyStates;

- (instancetype)initWithTeam:(NIMTeam *)team session:(NIMSession *)session;

- (void)reloadMyTeamInfo;

- (void)inviteUsers:(NSArray<NSString *> *)userIds
         completion:(NIMTeamListDataBlock)completion;

- (void)updateTeamAvatar:(NSString *)filePath
              completion:(NIMTeamListDataBlock)completion;

- (void)updateTeamName:(NSString *)name
            completion:(NIMTeamListDataBlock)completion;

- (void)updateTeamNick:(NSString *)nick
            completion:(NIMTeamListDataBlock)completion;

- (void)updateTeamIntro:(NSString *)intro
             completion:(NIMTeamListDataBlock)completion;

- (void)updateTeamAnnouncement:(NSString *)content
                    completion:(NIMTeamListDataBlock)completion;

- (void)quitTeamCompletion:(NIMTeamListDataBlock)completion;

@end

NS_ASSUME_NONNULL_END
