//
//  NTESTeamCardMemberItem.h
//  NIM
//
//  Created by chris on 15/3/5.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMCardDataSourceProtocol.h"

@interface NIMCardMemberItem : NSObject<NIMKitCardHeaderData>

@property (nonatomic, copy) NSString *userId;

@end

@interface NIMTeamCardMemberItem : NSObject<NIMKitCardHeaderData>

@property (nonatomic, readonly) NIMTeamMember *member;

@property (nonatomic, copy) NSString *userId;

@property (nonatomic, assign) NIMKitCardHeaderOpeator opeator;

- (instancetype)initWithMember:(NIMTeamMember *)member
                      teamType:(NIMTeamType)teamType;

@end


