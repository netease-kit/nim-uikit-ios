//
//  NIMSessionViewLayoutManager.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMSessionViewLayoutManager.h"
#import "NIMInputView.h"
#import "UIView+NIM.h"
#import "UITableView+NIMScrollToBottom.h"
#import "NIMMessageCellProtocol.h"
#import "NIMMessageModel.h"
#import "NIMMessageCell.h"

@interface NIMSessionViewLayoutManager()<NIMInputDelegate>

@property (nonatomic,weak) NIMInputView *inputView;

@property (nonatomic,weak) UITableView *tableView;

@end

@implementation NIMSessionViewLayoutManager


-(instancetype)initWithInputView:(NIMInputView*)inputView tableView:(UITableView*)tableview
{
    if (self = [self init]) {
        _inputView = inputView;
        _inputView.inputDelegate = self;
        _tableView = tableview;
        _inputView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
        _tableView.nim_height -= _inputView.nim_height;
    }
    return self;
}

- (void)dealloc
{
    _inputView.inputDelegate = nil;
}

-(void)insertTableViewCellAtRows:(NSArray*)addIndexs
{
    if (!addIndexs.count) {
        return;
    }
    NSMutableArray *addIndexPathes = [NSMutableArray array];
    [addIndexs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [addIndexPathes addObject:[NSIndexPath indexPathForRow:[obj integerValue] inSection:0]];
    }];
    [_tableView beginUpdates];
    [_tableView insertRowsAtIndexPaths:addIndexPathes withRowAnimation:UITableViewRowAnimationNone];
    [_tableView endUpdates];
    
    NSTimeInterval scrollDelay = .01f;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(scrollDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_tableView scrollToRowAtIndexPath:[addIndexPathes lastObject] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    });
}

- (void)updateCellAtIndex:(NSInteger)index model:(NIMMessageModel *)model
{
    if (index > -1) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];

        NIMMessageCell *cell = (NIMMessageCell *)[_tableView cellForRowAtIndexPath:indexPath];
        [cell refreshData:model];
    }
}

-(void)deleteCellAtIndexs:(NSArray*)delIndexs
{
    NSMutableArray *delIndexPathes = [NSMutableArray array];
    [delIndexs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [delIndexPathes addObject:[NSIndexPath indexPathForRow:[obj integerValue] inSection:0]];
    }];
    [_tableView beginUpdates];
    [_tableView deleteRowsAtIndexPaths:delIndexPathes withRowAnimation:UITableViewRowAnimationFade];
    [_tableView endUpdates];
}

-(void)reloadDataToIndex:(NSInteger)index withAnimation:(BOOL)animated
{
    [_tableView reloadData];
    if (index > 0) {
        [_tableView beginUpdates];
        [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:animated];
        [_tableView endUpdates];
    }
}

#pragma mark - NTESInputViewDelegate
//更改tableview布局
- (void)showInputView
{
    [_tableView setUserInteractionEnabled:NO];
}

- (void)hideInputView
{
    [_tableView setUserInteractionEnabled:YES];
}

- (void)inputViewSizeToHeight:(CGFloat)toHeight showInputView:(BOOL)show
{
    [_tableView setUserInteractionEnabled:!show];
    [UIView animateWithDuration:0.3 animations:^{
        CGRect rect = [_tableView frame];
        rect.origin.y = 0;
        rect.size.height = self.viewRect.size.height - toHeight;
        [_tableView setFrame:rect];
        [_tableView nim_scrollToBottom:NO];
    }];
}

@end
