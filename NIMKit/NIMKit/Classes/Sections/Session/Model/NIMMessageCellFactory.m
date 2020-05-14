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
#import "NIMSessionAudioContentView.h"
#import "NIMKit.h"
#import "NIMKitAudioCenter.h"
#import "UIView+NIM.h"

@interface NIMMessageCellFactory()

@end

@implementation NIMMessageCellFactory

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    
}

- (NIMMessageCell *)cellInTable:(UITableView*)tableView
                 forMessageMode:(NIMMessageModel *)model
{
    id<NIMCellLayoutConfig> layoutConfig = [[NIMKit sharedKit] layoutConfig];
    NSString *identity = [layoutConfig cellContent:model];
    NIMMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:identity];
    if (!cell) {
        NSString *clz = @"NIMAdvancedMessageCell";
        [tableView registerClass:NSClassFromString(clz) forCellReuseIdentifier:identity];
        cell = [tableView dequeueReusableCellWithIdentifier:identity];
    }    
    return (NIMMessageCell *)cell;
}

- (NIMSessionTimestampCell *)cellInTable:(UITableView *)tableView
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
