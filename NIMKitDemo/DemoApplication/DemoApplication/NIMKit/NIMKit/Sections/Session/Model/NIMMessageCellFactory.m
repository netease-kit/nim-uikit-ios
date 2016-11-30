//
//  NIMMessageCellMaker.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMMessageCellFactory.h"
#import "NIMMessageModel.h"
#import "NIMTimestampModel.h"
#import "NIMKit.h"

@implementation NIMMessageCellFactory

+ (NIMMessageCell *)cellInTable:(UITableView*)tableView
                 forMessageMode:(NIMMessageModel *)model
{
    id<NIMCellLayoutConfig> layoutConfig = [[NIMKit sharedKit] layoutConfig];
    NSString *identity = [layoutConfig cellContent:model];
    NIMMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:identity];
    if (!cell) {
        NSString *clz = @"NIMMessageCell";
        [tableView registerClass:NSClassFromString(clz) forCellReuseIdentifier:identity];
        cell = [tableView dequeueReusableCellWithIdentifier:identity];
    }
    [cell refreshData:model];
    return (NIMMessageCell *)cell;
}

+ (NIMSessionTimestampCell *)cellInTable:(UITableView *)tableView
                            forTimeModel:(NIMTimestampModel *)model
{
    NSString *identity = @"time";
    NIMSessionTimestampCell *cell = [tableView dequeueReusableCellWithIdentifier:identity];
    if (!cell) {
        NSString *clz = @"NIMSessionTimestampCell";
        [tableView registerClass:NSClassFromString(clz) forCellReuseIdentifier:identity];
        cell = [tableView dequeueReusableCellWithIdentifier:identity];
    }
    [cell refreshData:model];
    return (NIMSessionTimestampCell *)cell;
    
    
}

@end
