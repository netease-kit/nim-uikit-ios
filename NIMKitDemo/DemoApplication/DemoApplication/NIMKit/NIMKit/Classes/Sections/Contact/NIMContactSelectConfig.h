//
//  NIMContactSelectConfig.h
//  NIMKit
//
//  Created by chris on 15/9/14.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NIMContactSelectType) {
    NIMContactSelectTypeFriend,
    NIMContactSelectTypeTeamMember,
    NIMContactSelectTypeTeam,
};


@protocol NIMContactSelectConfig <NSObject>

@required
/**
 *  联系人选择器中的数据源类型
 *  当是群组时，需要设置群组id
 */
- (NIMContactSelectType)selectType;


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

@end

/**
 *  内置配置-选择好友
 */
@interface NIMContactFriendSelectConfig : NSObject<NIMContactSelectConfig>

@property (nonatomic,assign) BOOL needMutiSelected;

@property (nonatomic,copy) NSArray *alreadySelectedMemberId;

@property (nonatomic,copy) NSArray *filterIds;

@end

/**
 *  内置配置-选择群成员
 */
@interface NIMContactTeamMemberSelectConfig : NSObject<NIMContactSelectConfig>

@property (nonatomic,copy) NSString *teamId;

@property (nonatomic,assign) BOOL needMutiSelected;

@property (nonatomic,copy) NSArray *alreadySelectedMemberId;

@property (nonatomic,copy) NSArray *filterIds;

@end


/**
 *  内置配置-选择群
 */
@interface NIMContactTeamSelectConfig : NSObject<NIMContactSelectConfig>

@property (nonatomic,assign) BOOL needMutiSelected;

@property (nonatomic,copy) NSArray *alreadySelectedMemberId;

@property (nonatomic,copy) NSArray *filterIds;

@end
