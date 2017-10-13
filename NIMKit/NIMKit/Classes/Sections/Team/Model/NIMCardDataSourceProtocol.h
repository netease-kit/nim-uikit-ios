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
    TeamCardRowItemTypeCheckMark,
};


@protocol NIMKitCardHeaderData <NSObject>

- (UIImage*)imageNormal;

- (NSString*)title;

@optional
- (NSString*)imageUrl;

- (NSString*)memberId;

- (NIMKitCardHeaderOpeator)opera;

@end



@protocol NTESCardBodyData <NSObject>

- (NSString*)title;

- (NIMKitTeamCardRowItemType)type;

- (CGFloat)rowHeight;

@optional
- (NSString*)subTitle;

- (SEL)action;

- (BOOL)actionDisabled;

- (BOOL)switchOn;

- (id)value;

@end
