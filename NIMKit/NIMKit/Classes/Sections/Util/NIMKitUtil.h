//
//  NIMUtil.h
//  NIMKit
//
//  Created by chris on 15/8/10.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import "NIMGlobalMacro.h"

@interface NIMKitUtil : NSObject

+ (NSString *)showNick:(NSString *)uid inMessage:(NIMMessage *)message;

+ (NSString *)showNick:(NSString *)uid inSession:(NIMSession *)session;

+ (NSString *)showTime:(NSTimeInterval)msglastTime showDetail:(BOOL)showDetail;

+ (NSString *)messageTipContent:(NIMMessage *)message;

+ (BOOL)canEditTeamInfo:(NIMTeamMember *)member;

+ (BOOL)canInviteMemberToTeam:(NIMTeamMember *)member;

+ (BOOL)canEditSuperTeamInfo:(NIMTeamMember *)member;

+ (BOOL)canInviteMemberToSuperTeam:(NIMTeamMember *)member;

@end
