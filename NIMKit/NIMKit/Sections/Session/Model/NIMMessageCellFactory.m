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

@interface NIMMessageCellFactory()<NIMMediaManagerDelgate>

@property (nonatomic,copy) NSString *currentPlayingPath;

@end

@implementation NIMMessageCellFactory

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NIMSDK sharedSDK].mediaManager addDelegate:self];
    }
    return self;
}

- (void)dealloc
{
    [[NIMSDK sharedSDK].mediaManager removeDelegate:self];
}

- (NIMMessageCell *)cellInTable:(UITableView*)tableView
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
    [self checkPlayState:model cell:cell];
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

- (void)checkPlayState:(NIMMessageModel *)model cell:(NIMMessageCell *)cell
{
    NIMSessionAudioContentView *content = (NIMSessionAudioContentView *)cell.bubbleView;
    if ([content isKindOfClass:[NIMSessionAudioContentView class]]) {
        NIMAudioObject *object = (NIMAudioObject *)model.message.messageObject;
        if ([object isKindOfClass:[NIMAudioObject class]]) {
            [content setPlaying:[object.path isEqualToString:self.currentPlayingPath]];
        }
    }
}

#pragma mark - NIMMediaManagerDelgate
- (void)playAudio:(NSString *)filePath didBeganWithError:(NSError *)error {
    if (!error) {
        self.currentPlayingPath = filePath;
    }
}

- (void)playAudio:(NSString *)filePath didCompletedWithError:(NSError *)error
{
    self.currentPlayingPath = nil;
}

@end
