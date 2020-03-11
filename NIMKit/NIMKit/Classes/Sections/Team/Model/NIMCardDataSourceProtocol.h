//
//  NIMCardDataSourceProtocol.h
//  NIM
//
//  Created by chris on 15/3/5.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <NIMSDK/NIMSDK.h>

@protocol NIMKitSelectCardData;

typedef void(^NIMTeamCardRowSelectedBlock)(id <NIMKitSelectCardData> item);

typedef NS_ENUM(NSInteger, NIMKitCardHeaderOpeator){
    CardHeaderOpeatorNone   = 0,
    CardHeaderOpeatorAdd    = (1UL << 0),
    CardHeaderOpeatorRemove = (1UL << 1),
};

typedef NS_ENUM(NSInteger, NIMKitTeamCardRowItemType) {
    TeamCardRowItemTypeCommon,
    TeamCardRowItemTypeTeamMember,
    TeamCardRowItemTypeRedButton,
    TeamCardRowItemTypeBlueButton,
    TeamCardRowItemTypeSwitch,
    TeamCardRowItemTypeSelected,
};

@protocol NIMKitCardHeaderData <NSObject>

- (NSString*)teamId;

- (NSString*)userId;

- (NIMTeamMemberType)userType;

- (void)setUserType:(NIMTeamMemberType)userType;

- (NIMTeamType)teamType;

- (UIImage*)imageNormal;

- (NSString*)title;

- (NSString*)imageUrl;

- (NSString*)inviterAccid;

- (BOOL)isMuted;

- (BOOL)isMyUserId;

@end

@protocol NIMKitSelectCardData <NSObject>

- (id)value;

- (NSString*)title;

- (BOOL)selected;

- (void)setSelected:(BOOL)selected;

@end

@protocol NTESCardBodyData <NSObject>

- (NSString*)title;

- (id)value;

- (NIMKitTeamCardRowItemType)type;

- (CGFloat)rowHeight;

- (NIMTeamCardRowSelectedBlock)selectedBlock;

- (NSMutableArray <id <NIMKitSelectCardData>> *)optionItems;

@optional
- (NSString*)subTitle;

- (SEL)action;

- (BOOL)actionDisabled;

- (BOOL)switchOn;

- (NSInteger)identify;

- (BOOL)disableUserInteraction;

@end
