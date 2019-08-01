//
//  NTESCardMemberItem.m
//  NIM
//
//  Created by chris on 15/3/5.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMCardMemberItem.h"
#import "NIMKitUtil.h"
#import "NIMKit.h"

@implementation NIMCardMemberItem

- (NSUInteger)hash {
    return [self.userId hash];
}

- (BOOL)isEqual:(id)object{
    if (![object isKindOfClass:[NIMTeamCardMemberItem class]]) {
        return NO;
    }
    NIMCardMemberItem *obj = (NIMCardMemberItem*)object;
    return [obj.userId isEqual:self.userId];
}

#pragma mark - <NIMKitCardHeaderData>
- (UIImage *)imageNormal{
    NIMKitInfo *info = [[NIMKit sharedKit] infoByUser:self.userId option:nil];
    return info.avatarImage;
}

- (NSString *)title {
    NIMSession *session = [NIMSession session:self.teamId type:NIMSessionTypeTeam];
    return [NIMKitUtil showNick:self.userId inSession:session];
}

- (NSString *)imageUrl{
    return [[NIMKit sharedKit] infoByUser:self.userId option:nil].avatarUrlString;
}

- (NIMKitCardHeaderOpeator)opera{
    return CardHeaderOpeatorNone;
}

- (NSString*)teamId {
    return nil;
}

- (NSString*)inviterAccid {
    return nil;
}

- (BOOL)isMuted {
    return NO;
}

- (NIMKitTeamCardType)teamType {
    return NIMKitTeamCardTypeNormal;
}

- (BOOL)isMyUserId {
    return NO;
}

#pragma mark - Class Function
+ (NIMKitTeamMemberType)showTypeWithTeamMemberType:(NIMTeamMemberType)type {
    NIMKitTeamMemberType ret = NIMKitTeamMemberTypeNormal;
    switch (type) {
            case NIMTeamMemberTypeNormal:
            ret = NIMKitTeamMemberTypeNormal;
            break;
            case NIMTeamMemberTypeOwner:
            ret = NIMKitTeamMemberTypeOwner;
            break;
            case NIMTeamMemberTypeManager:
            ret = NIMKitTeamMemberTypeManager;
            break;
            case NIMTeamMemberTypeApply:
            ret = NIMKitTeamMemberTypeApply;
            break;
        default:
            break;
    }
    return ret;
}

@end

#pragma mark - NIMTeamCardMemberItem
@implementation NIMTeamCardMemberItem
- (instancetype)initWithTeamId:(NSString *)teamId
                        member:(NIMTeamMember *)member {
    if (self = [super init]) {
        self.userId = member.userId;
        self.userType = [NIMCardMemberItem showTypeWithTeamMemberType:member.type];
        self.teamId = teamId;
        self.teamType = NIMKitTeamCardTypeNormal;
        self.inviterAccid = member.inviterAccid;
        self.isMute = member.isMuted;
    }
    return self;
}

- (instancetype)initWithSuperTeamId:(NSString *)teamId
                             member:(NIMTeamMember *)member {
    if (self = [super init]) {
        self.userId = member.userId;
        self.userType = [NIMCardMemberItem showTypeWithTeamMemberType:member.type];
        self.teamId = teamId;
        self.teamType = NIMKitTeamCardTypeSuper;
        self.inviterAccid = @"";
        self.isMute = NO;
    }
    return self;
}

@end

#pragma mark - NIMUserCardMemberItem
@implementation NIMUserCardMemberItem

- (instancetype)initWithTeamMember:(NIMTeamMember *)member {
    if (self = [super init]) {
        self.userId = member.userId;
        self.userType = [NIMCardMemberItem showTypeWithTeamMemberType:member.type];
        self.isMyUserId = [member.userId isEqualToString:[NIMSDK sharedSDK].loginManager.currentAccount];
    }
    return self;
}

- (instancetype)initWithSuperTeamMember:(NIMTeamMember *)member {
    if (self = [super init]) {
        self.userId = member.userId;
        self.userType = [NIMCardMemberItem showTypeWithTeamMemberType:member.type];
        self.isMyUserId = [member.userId isEqualToString:[NIMSDK sharedSDK].loginManager.currentAccount];
    }
    return self;
}

@end
