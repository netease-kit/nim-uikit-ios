//
//  NIMTeamHelper.m
//  NIMKit
//
//  Created by Genning-Work on 2019/12/11.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "NIMTeamHelper.h"
#import "NIMTeamCardRowItem.h"
#import "UIImage+NIMKit.h"
#import "NSString+NIMKit.h"

static NSString *const kTeamHelperText = @"kTeamHelperText";
static NSString *const kTeamHelperValue = @"kTeamHelperValue";

@implementation NIMTeamHelper

#pragma mark - 验证方式
+ (NSArray<NSDictionary *> *)allJoinModes {
    NSArray *ret = @[
                     @{
                         kTeamHelperValue : @(NIMTeamJoinModeNoAuth),
                         kTeamHelperText : [NIMTeamHelper jonModeText:NIMTeamJoinModeNoAuth]
                         },
                     @{
                         kTeamHelperValue : @(NIMTeamJoinModeNeedAuth),
                         kTeamHelperText : [NIMTeamHelper jonModeText:NIMTeamJoinModeNeedAuth]
                         },
                     @{
                         kTeamHelperValue : @(NIMTeamJoinModeRejectAll),
                         kTeamHelperText : [NIMTeamHelper jonModeText:NIMTeamJoinModeRejectAll]
                         },
                     ];
    return ret;
}

+ (NSString *)jonModeText:(NIMTeamJoinMode)mode {
    switch (mode) {
        case NIMTeamJoinModeNoAuth:
            return @"允许任何人".nim_localized;
        case NIMTeamJoinModeNeedAuth:
            return @"需要验证".nim_localized;
        case NIMTeamJoinModeRejectAll:
            return @"拒绝任何人".nim_localized;
        default:
            return @"";
    }
}

+ (NSMutableArray<id <NIMKitSelectCardData>> *)joinModeItemsWithSeleced:(NIMTeamJoinMode)mode {
    return [self itemsWithListDic:[self allJoinModes] selectValue:mode];
}

#pragma mark - 邀请模式
+ (NSArray<NSDictionary *> *)allInviteModes {
    NSArray *ret = @[
                     @{
                         kTeamHelperValue : @(NIMTeamInviteModeManager),
                         kTeamHelperText : [NIMTeamHelper InviteModeText:NIMTeamInviteModeManager]
                         },
                     @{
                         kTeamHelperValue : @(NIMTeamInviteModeAll),
                         kTeamHelperText : [NIMTeamHelper InviteModeText:NIMTeamInviteModeAll]
                         },
                     ];
    return ret;
}

+ (NSString *)InviteModeText:(NIMTeamInviteMode)mode {
    switch (mode) {
        case NIMTeamInviteModeManager:
            return @"管理员".nim_localized;
        case NIMTeamInviteModeAll:
            return @"所有人".nim_localized;
        default:
            return @"未知权限".nim_localized;
    }
}

+ (NSMutableArray<id <NIMKitSelectCardData>> *)InviteModeItemsWithSeleced:(NIMTeamInviteMode)mode {
    return [self itemsWithListDic:[self allInviteModes] selectValue:mode];
}

#pragma mark - 被邀请模式
+ (NSArray<NSDictionary *> *)allBeInviteModes {
    NSArray *ret = @[
                     @{
                         kTeamHelperValue : @(NIMTeamBeInviteModeNeedAuth),
                         kTeamHelperText : [NIMTeamHelper beInviteModeText:NIMTeamBeInviteModeNeedAuth]
                         },
                     @{
                         kTeamHelperValue : @(NIMTeamBeInviteModeNoAuth),
                         kTeamHelperText : [NIMTeamHelper beInviteModeText:NIMTeamBeInviteModeNoAuth]
                         },
                     ];
    return ret;
}

+ (NSString *)beInviteModeText:(NIMTeamBeInviteMode)mode {
    switch (mode) {
        case NIMTeamBeInviteModeNeedAuth:
            return @"需要验证".nim_localized;
        case NIMTeamBeInviteModeNoAuth:
            return @"不需要验证".nim_localized;
        default:
            return @"未知".nim_localized;
    }
}

+ (NSMutableArray<id <NIMKitSelectCardData>> *)beInviteModeItemsWithSeleced:(NIMTeamBeInviteMode)mode {
    return [self itemsWithListDic:[self allBeInviteModes] selectValue:mode];
}

#pragma mark - 信息修改权限
+ (NSArray<NSDictionary *> *)allUpdateInfoModes {
    NSArray *ret = @[
                     @{
                         kTeamHelperValue : @(NIMTeamUpdateInfoModeManager),
                         kTeamHelperText : [NIMTeamHelper updateInfoModeText:NIMTeamUpdateInfoModeManager]
                         },
                     @{
                         kTeamHelperValue : @(NIMTeamUpdateInfoModeAll),
                         kTeamHelperText : [NIMTeamHelper updateInfoModeText:NIMTeamUpdateInfoModeAll]
                         },
                     ];
    return ret;
}

+ (NSString *)updateInfoModeText:(NIMTeamUpdateInfoMode)mode {
    switch (mode) {
        case NIMTeamUpdateInfoModeManager:
            return @"管理员".nim_localized;
        case NIMTeamUpdateInfoModeAll:
            return @"所有人".nim_localized;
        default:
            return @"未知权限".nim_localized;
    }
}

+ (NSMutableArray<id <NIMKitSelectCardData>> *)updateInfoModeItemsWithSeleced:(NIMTeamUpdateInfoMode)mode {
    return [self itemsWithListDic:[self allUpdateInfoModes] selectValue:mode];
}

#pragma mark - 消息接受状态
+ (NSArray<NSDictionary *> *)allNotifyStates {
    NSArray *ret = @[
                     @{
                         kTeamHelperValue : @(NIMTeamNotifyStateAll),
                         kTeamHelperText : [NIMTeamHelper notifyStateText:NIMTeamNotifyStateAll]
                         },
                     @{
                         kTeamHelperValue : @(NIMTeamNotifyStateNone),
                         kTeamHelperText : [NIMTeamHelper notifyStateText:NIMTeamNotifyStateNone]
                         },
                     @{
                         kTeamHelperValue : @(NIMTeamNotifyStateOnlyManager),
                         kTeamHelperText : [NIMTeamHelper notifyStateText:NIMTeamNotifyStateOnlyManager]
                         },
                     ];
    return ret;
}

+ (NSArray<NSDictionary *> *)allSuperNotifyStates {
    NSArray *ret = @[
                     @{
                         kTeamHelperValue : @(NIMTeamNotifyStateAll),
                         kTeamHelperText : [NIMTeamHelper notifyStateText:NIMTeamNotifyStateAll]
                         },
                     @{
                         kTeamHelperValue : @(NIMTeamNotifyStateNone),
                         kTeamHelperText : [NIMTeamHelper notifyStateText:NIMTeamNotifyStateNone]
                         },
                     ];
    return ret;
}

+ (NSString *)notifyStateText:(NIMTeamNotifyState)state {
    switch (state) {
        case NIMTeamNotifyStateAll:
            return @"提醒所有消息".nim_localized;
        case NIMTeamNotifyStateNone:
            return @"不提醒任何消息".nim_localized;
        case NIMTeamNotifyStateOnlyManager:
            return @"只提醒管理员消息".nim_localized;
        default:
            return @"未知模式".nim_localized;
    }
}

+ (NSMutableArray<id <NIMKitSelectCardData>> *)notifyStateItemsWithSeleced:(NIMTeamNotifyState)state {
    return [self itemsWithListDic:[self allNotifyStates] selectValue:state];
}

+ (NSMutableArray<id <NIMKitSelectCardData>> *)superNotifyStateItemsWithSeleced:(NIMTeamNotifyState)state {
    return [self itemsWithListDic:[self allSuperNotifyStates] selectValue:state];
}

#pragma mark - 群禁言
+ (NSArray<NSDictionary *> *)allTeamMuteState {
    NSArray *ret = @[
                     @{
                         kTeamHelperValue : @(YES),
                         kTeamHelperText : [NIMTeamHelper teamMuteText:YES]
                         },
                     @{
                         kTeamHelperValue : @(NO),
                         kTeamHelperText : [NIMTeamHelper teamMuteText:NO]
                         },
                     ];
    return ret;
}
+ (NSString *)teamMuteText:(BOOL)isMute {
    return isMute ? @"开启".nim_localized : @"关闭".nim_localized;
}

+ (NSMutableArray<id <NIMKitSelectCardData>> *)teamMuteItemsWithSeleced:(BOOL)isMute {
    return [self itemsWithListDic:[self allTeamMuteState] selectValue:isMute];
}

#pragma mark - 成员类型
+ (NSString *)memberTypeText:(NIMTeamMemberType)type {
    switch (type) {
        case NIMTeamMemberTypeNormal:
            return @"普通成员".nim_localized;
        case NIMTeamMemberTypeOwner:
            return @"群主".nim_localized;
        case NIMTeamMemberTypeManager:
            return @"管理员".nim_localized;
        default:
            return @"未知".nim_localized;
    }
}

+ (UIImage *)imageWithMemberType:(NIMTeamMemberType)type {
    UIImage *ret = nil;
    switch (type) {
        case NIMTeamMemberTypeOwner:
            ret = [UIImage nim_imageInKit:@"icon_team_creator"];
            break;
        case NIMTeamMemberTypeManager:
            ret = [UIImage nim_imageInKit:@"icon_team_manager"];
            break;
        default:
            ret = nil;
            break;
    }
    return ret;
}

#pragma mark - Tool
+ (NSMutableArray *)itemsWithListDic:(NSArray <NSDictionary *> *)listDic
                         selectValue:(NSInteger)selectValue {
    NSMutableArray *items = [[NSMutableArray alloc] init];
    for (NSDictionary *dic in listDic) {
        NIMTeamCardRowItem *item = [[NIMTeamCardRowItem alloc] init];
        item.value = dic[kTeamHelperValue];
        item.title = dic[kTeamHelperText];
        item.selected = (selectValue == [dic[kTeamHelperValue] integerValue]);
        [items addObject:item];
    }
    return items;
}

@end
