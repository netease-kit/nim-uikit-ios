//
//  NIMSessionLayout.m
//  NIMKit
//
//  Created by chris on 2016/11/8.
//  Copyright © 2016年 NetEase. All rights reserved.
//

#import "NIMSessionLayoutImpl.h"
#import "UITableView+NIMScrollToBottom.h"
#import "NIMMessageCell.h"
#import "NIMGlobalMacro.h"
#import "NIMSessionTableAdapter.h"
#import "UIView+NIM.h"
#import "NIMKitKeyboardInfo.h"

@interface NIMSessionLayoutImpl(){
    NSMutableArray *_inserts;
    CGFloat _inputViewHeight;
}

@property (nonatomic,strong)  UIRefreshControl *refreshControl;

@property (nonatomic,strong)  NIMSession  *session;

@property (nonatomic,strong)  id<NIMSessionConfig> sessionConfig;

@property (nonatomic,weak)    id<NIMSessionLayoutDelegate> delegate;

@end

@implementation NIMSessionLayoutImpl

- (instancetype)initWithSession:(NIMSession *)session
                         config:(id<NIMSessionConfig>)sessionConfig
{
    self = [super init];
    if (self) {
        _sessionConfig = sessionConfig;
        _session       = session;
        _inserts       = [[NSMutableArray alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuDidHide:) name:UIMenuControllerDidHideMenuNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:NIMKitKeyboardWillChangeFrameNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadTable
{
    [self.tableView reloadData];
}

- (void)setTableView:(UITableView *)tableView
{
    BOOL change = _tableView != tableView;
    if (change)
    {
        _tableView = tableView;
        [self setupRefreshControl];
    }
}

- (void)resetLayout
{
    [self adjustInputView];
    [self adjustTableView];
}

- (void)layoutAfterRefresh
{
    [self.refreshControl endRefreshing];
    
    CGFloat offset  = self.tableView.contentSize.height - self.tableView.contentOffset.y;
    [self.tableView reloadData];
    CGFloat offsetYAfterLoad = self.tableView.contentSize.height - offset;
    CGPoint point  = self.tableView.contentOffset;
    point.y = offsetYAfterLoad;
    [self.tableView setContentOffset:point animated:NO];
}


- (void)changeLayout:(CGFloat)inputViewHeight
{
    BOOL change = _inputViewHeight != inputViewHeight;
    if (change)
    {
        _inputViewHeight = inputViewHeight;
        [self adjustInputView];
        [self adjustTableView];
    }
}


- (void)adjustInputView
{
    UIView *superView = self.inputView.superview;
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *))
    {
        safeAreaInsets = superView.safeAreaInsets;
    }
    self.inputView.nim_bottom = superView.nim_height - safeAreaInsets.bottom;
}

- (void)adjustTableView
{
    //输入框是否弹起
    BOOL inputViewUp = NO;
    switch (self.inputView.status)
    {
        case NIMInputStatusText:
            inputViewUp = [NIMKitKeyboardInfo instance].isVisiable;
            break;
        case NIMInputStatusAudio:
            inputViewUp = NO;
            break;
        case NIMInputStatusMore:
        case NIMInputStatusEmoticon:
            inputViewUp = YES;
        default:
            break;
    }
    self.tableView.userInteractionEnabled = !inputViewUp;
    CGRect rect = self.tableView.frame;
    
    //tableview 的位置
    UIView *superView = self.tableView.superview;
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *))
    {
        safeAreaInsets = superView.safeAreaInsets;
    }
    
    CGFloat containerSafeHeight = self.tableView.superview.frame.size.height - safeAreaInsets.bottom;
    
    rect.size.height = containerSafeHeight - self.inputView.toolBar.nim_height;
    
    
    //tableview 的内容 inset
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    CGFloat visiableHeight = 0;
    if (@available(iOS 11.0, *))
    {
        contentInsets = self.tableView.adjustedContentInset;
    }
    else
    {
        contentInsets = self.tableView.contentInset;
        visiableHeight = [self fixVisiableHeightBelowIOS11:visiableHeight];
    }
    
    //如果气泡过少，少于总高度，输入框视图需要顶到最后一个气泡的下面。
    visiableHeight = visiableHeight + self.tableView.contentSize.height + contentInsets.top + contentInsets.bottom;
    visiableHeight = MIN(visiableHeight, rect.size.height);
    
    
    
    rect.origin.y    = containerSafeHeight - visiableHeight - self.inputView.nim_height;
    rect.origin.y    = rect.origin.y > 0? 0 : rect.origin.y;
    
    
    BOOL tableChanged = !CGRectEqualToRect(self.tableView.frame, rect);
    if (tableChanged)
    {
        [self.tableView setFrame:rect];
        [self.tableView nim_scrollToBottom:YES];
    }
}


- (CGFloat)fixVisiableHeightBelowIOS11:(CGFloat)visiableHeight
{
    //iOS11 以下，当插入数据后不会立即改变 contentSize 的大小，所以需要手动添加最后一个数据的高度
    NSInteger section = self.tableView.numberOfSections - 1;
    NSInteger row     = [self.tableView numberOfRowsInSection:section] - 1;
    if (section >=0 && row >=0)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
        CGFloat height = [self.tableView.delegate tableView:self.tableView heightForRowAtIndexPath:indexPath];
        return visiableHeight + height;
    }
    else
    {
        return visiableHeight;
    }
}


#pragma mark - Notification
- (void)menuDidHide:(NSNotification *)notification
{
    [UIMenuController sharedMenuController].menuItems = nil;
}


- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    if (!self.tableView.window)
    {
        //如果当前视图不是顶部视图，则不需要监听
        return;
    }
    [self.inputView sizeToFit];
}




#pragma mark - Private

- (void)calculateContent:(NIMMessageModel *)model{
    [model contentSize:self.tableView.nim_width];
}

- (void)setupRefreshControl
{
    self.refreshControl = [[UIRefreshControl alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];

    
    if (@available(iOS 10.0, *))
    {
        self.tableView.refreshControl = self.refreshControl;
    }
    else
    {
        [self.tableView addSubview: self.refreshControl];
    }
    
    [self.refreshControl addTarget:self action:@selector(headerRereshing:) forControlEvents:UIControlEventValueChanged];
}

- (void)headerRereshing:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(onRefresh)])
    {
        [self.delegate onRefresh];
    }
}



- (void)insert:(NSArray<NSIndexPath *> *)indexPaths animated:(BOOL)animated
{
    if (!indexPaths.count)
    {
        return;
    }

    NSMutableArray *addIndexPathes = [NSMutableArray array];
    [indexPaths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[obj integerValue] inSection:0];
        [addIndexPathes addObject:indexPath];
    }];
    
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:addIndexPathes withRowAnimation:UITableViewRowAnimationBottom];
    [self.tableView endUpdates];
    

    [UIView animateWithDuration:0.25 delay:0 options:7 animations:^{
        [self resetLayout];
    } completion:nil];
    [self.tableView nim_scrollToBottom:YES];
}

- (void)remove:(NSArray<NSIndexPath *> *)indexPaths
{
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}


- (void)update:(NSIndexPath *)indexPath
{
    NIMMessageCell *cell = (NIMMessageCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        CGFloat scrollOffsetY = self.tableView.contentOffset.y;
        [self.tableView setContentOffset:CGPointMake(self.tableView.contentOffset.x, scrollOffsetY) animated:NO];
    }
}

- (BOOL)canInsertChatroomMessages
{
    return !self.tableView.isDecelerating && !self.tableView.isDragging;
}

@end
