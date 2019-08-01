//
//  NIMContactSelectConfig.h
//  NIMKit
//
//  Created by chris on 15/9/14.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMKitInfo.h"
#import "NIMGroupedUsrInfo.h"

/**
 *  联系人选择器数据回调
 */
typedef void(^NIMContactDataProviderHandler)(NSDictionary *contentDic, NSArray *titles);

@protocol NIMContactSelectConfig <NSObject>

@optional

/**
 *  联系人选择器标题
 */
- (NSString *)title;

/**
 *  最多选择的人数
 */
- (NSInteger)maxSelectedNum;

/**
 *  超过最多选择人数时的提示
 */
- (NSString *)selectedOverFlowTip;

/**
 *  默认已经勾选的人或群组
 */
- (NSArray *)alreadySelectedMemberId;

/**
 *  需要过滤的人或群组id
 */
- (NSArray *)filterIds;

/**
 *  当数据源类型为群组时，需要设置的群id
 *
 *  @return 群id
 */
- (NSString *)teamId;

/**
 *  显示具体选择人数
 */
- (BOOL)showSelectDetail;

/**
 *  提供联系人选择期的昵称，title信息
 */
- (void)getContactData:(NIMContactDataProviderHandler)handler;

/**
 *  提供联系人id、显示名、头像等信息
 */
- (NIMKitInfo *)getInfoById:(NSString *)selectedId;

@end

/**
 *  内置配置-选择好友
 */
@interface NIMContactFriendSelectConfig : NSObject<NIMContactSelectConfig>

@property (nonatomic,assign) BOOL needMutiSelected;

@property (nonatomic,assign) NSInteger maxSelectMemberCount;

@property (nonatomic,copy) NSArray *alreadySelectedMemberId;

@property (nonatomic,copy) NSArray *filterIds;

@property (nonatomic,assign) BOOL showSelectDetail;

@end

/**
 *  内置配置-选择群成员
 */
@interface NIMContactTeamMemberSelectConfig : NSObject<NIMContactSelectConfig>

@property (nonatomic,copy) NSString *teamId;

@property (nonatomic,strong) NIMSession *session;

@property (nonatomic,assign) NIMKitTeamType teamType;

@property (nonatomic,assign) BOOL needMutiSelected;

@property (nonatomic,assign) NSInteger maxSelectMemberCount;

@property (nonatomic,copy) NSArray *alreadySelectedMemberId;

@property (nonatomic,copy) NSArray *filterIds;

@property (nonatomic,assign) BOOL showSelectDetail;

@end


/**
 *  内置配置-选择群
 */
@interface NIMContactTeamSelectConfig : NSObject<NIMContactSelectConfig>

@property (nonatomic,assign) NIMKitTeamType teamType;

@property (nonatomic,assign) BOOL needMutiSelected;

@property (nonatomic,assign) NSInteger maxSelectMemberCount;

@property (nonatomic,copy) NSArray *alreadySelectedMemberId;

@property (nonatomic,copy) NSArray *filterIds;

@property (nonatomic,assign) BOOL showSelectDetail;

@end
