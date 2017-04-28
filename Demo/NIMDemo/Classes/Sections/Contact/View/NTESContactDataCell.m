//
//  NTESContactDataCell.m
//  NIM
//
//  Created by chris on 2017/4/7.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import "NTESContactDataCell.h"
#import "NTESSessionUtil.h"
@implementation NTESContactDataCell

- (void)refreshUser:(id<NIMGroupMemberProtocol>)member
{
    [super refreshUser:member];
    NSString *state = [NTESSessionUtil onlineState:self.memberId detail:NO];
    NSString *title = [NSString stringWithFormat:@"[%@] %@",state,member.showName];
    self.textLabel.text = title;
}


@end
