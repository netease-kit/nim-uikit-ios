//
//  NIMCollectMessageListViewController.m
//  NIMKit
//
//  Created by 丁文超 on 2020/3/19.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import "NIMCollectMessageListViewController.h"
#import "NIMLoadMoreFooterView.h"
#import "NIMCollectMessageCell.h"
#import "NIMMessageModel.h"
#import "NIMKit.h"
#import "NIMMessageMaker.h"
#import <NIMSDK/NIMSDK.h>
#import "NSString+NIMKit.h"
#import "NIMKitAudioCenter.h"
#import "NIMMessageCellFactory.h"

@interface NIMCollectMessageListViewController () <UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, strong) NSMutableArray<NIMMessageModel *> *messageList;
@property (nonatomic, strong) NSMutableArray<NIMCollectInfo *> *collectList;

@property (nonatomic, assign) BOOL noMoreData;
@property (nonatomic, readonly, getter=isLoading) BOOL loading;
@property (nonatomic, strong) NIMCollectQueryOptions *queryOptions;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NIMLoadMoreFooterView *loadMoreFooter;
@property (nonatomic, strong) UIView *emptyView;
@property (nonatomic, strong) NIMMessageCellFactory *cellFactory;

- (void)showOperationsForMessage:(NIMMessage *)message;
- (void)showOrHideEmptyView;

@end

@implementation NIMCollectMessageListViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.title = @"收藏消息".nim_localized;
        self.messageList = NSMutableArray.array;
        self.collectList = NSMutableArray.array;
        self.cellFactory = NIMMessageCellFactory.new;
    }
    return self;
}

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    view.backgroundColor = UIColor.whiteColor;
    self.view = view;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.backgroundColor = NIMKit.sharedKit.config.cellBackgroundColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = UIView.new;
    self.tableView.sectionHeaderHeight = 20;
    [self.view addSubview:self.tableView];
    
    self.loadMoreFooter = [[NIMLoadMoreFooterView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 50)];
    self.tableView.tableFooterView = self.loadMoreFooter;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self beginLoadingMore];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messageList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NIMMessageModel *messageModel = self.messageList[indexPath.row];
    NIMMessageCell *cell = [self.cellFactory cellInTable:tableView forMessageMode:messageModel];
    cell.delegate = self;
    [cell refreshData:messageModel];
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return UIView.new;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.messageList.count-1 && !self.isLoading && !self.noMoreData) {
        [self beginLoadingMore];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NIMMessageModel *model = self.messageList[indexPath.row];
    CGSize size = [model contentSize:tableView.frame.size.width];
    CGFloat avatarMarginY = [model avatarMargin].y;
    CGFloat cellHeight = 0;
    UIEdgeInsets contentViewInsets = model.contentViewInsets;
    UIEdgeInsets bubbleViewInsets  = model.bubbleViewInsets;
    cellHeight = size.height + contentViewInsets.top + contentViewInsets.bottom + bubbleViewInsets.top + bubbleViewInsets.bottom;
    cellHeight = cellHeight > (model.avatarSize.height + avatarMarginY) ? cellHeight : model.avatarSize.height + avatarMarginY;
    return cellHeight;
}

- (BOOL)onTapCell:(NIMKitEvent *)event
{
    BOOL handle = NO;
    if ([event.eventName isEqualToString:NIMKitEventNameTapAudio])
    {
        [self mediaAudioPressed:event.messageModel];
        handle = YES;
    }
    return handle;
}

- (BOOL)onLongPressCell:(NIMMessage *)message inView:(UIView *)view
{
    [self showOperationsForMessage:message];
    return YES;
}

- (void)showOperationsForMessage:(NIMMessage *)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:@"转发".nim_localized style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [NIMKit.sharedKit.chatUIManager forwardMessage:message fromViewController:self];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消收藏".nim_localized style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSInteger index = [self.messageList indexOfObjectPassingTest:^BOOL(NIMMessageModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj.message.messageId isEqualToString:message.messageId];
        }];
        NIMCollectInfo *collect = self.collectList[index];
        __weak typeof(self) wself = self;
        [NIMSDK.sharedSDK.chatExtendManager removeCollect:@[collect] completion:^(NSError * _Nullable error, NSInteger total_removed) {
            __strong typeof(self) sself = wself;
            if (!sself) {
                return;
            }
            [sself.messageList removeObjectAtIndex:index];
            [sself.collectList removeObjectAtIndex:index];
            [sself.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [sself showOrHideEmptyView];
        }];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消".nim_localized style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)mediaAudioPressed:(NIMMessageModel *)messageModel
{
    if (![[NIMSDK sharedSDK].mediaManager isPlaying]) {
        [[NIMSDK sharedSDK].mediaManager switchAudioOutputDevice:NIMAudioOutputDeviceSpeaker];
        [[NIMKitAudioCenter instance] play:messageModel.message];
    } else {
        [[NIMSDK sharedSDK].mediaManager stopPlay];
    }
}

- (BOOL)isLoading
{
    return self.loadMoreFooter.isAnimating;
}

- (void)beginLoadingMore
{
    if (self.isLoading || self.noMoreData) {
        return;
    }
    [self.loadMoreFooter startAnimation];
    self.queryOptions.toTime = self.collectList.lastObject.createTime;
    self.queryOptions.excludeId = self.collectList.lastObject.id;
    __weak typeof(self) wself = self;
    [NIMSDK.sharedSDK.chatExtendManager queryCollect:self.queryOptions completion:^(NSError * _Nullable error, NSArray<NIMCollectInfo *> * _Nullable collectInfos, NSInteger totalCount) {
        __strong typeof(self) sself = wself;
        if (!sself) {
            return;
        }
        [collectInfos enumerateObjectsUsingBlock:^(NIMCollectInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NIMMessage *message = [NIMSDK.sharedSDK.conversationManager decodeMessageFromData:[obj.data dataUsingEncoding:NSUTF8StringEncoding]];
            NIMMessageModel *model = [[NIMMessageModel alloc] initWithMessage:message];
            model.shouldShowPinContent = NO;
            model.enableQuickComments = NO;
            model.enableSubMessages = NO;
            model.enableRepliedContent = NO;
            [sself.messageList addObject:model];
            [sself.collectList addObject:obj];
        }];
        sself.noMoreData = totalCount == sself.messageList.count;
        [sself.tableView reloadData];
        [sself showOrHideEmptyView];
        [sself.loadMoreFooter stopAnimation];
    }];
}

- (NIMCollectQueryOptions *)queryOptions
{
    if (!_queryOptions) {
        _queryOptions = [[NIMCollectQueryOptions alloc] init];
        _queryOptions.limit = 50;
        _queryOptions.toTime = 0;
        _queryOptions.type = 1;
    }
    return _queryOptions;
}

- (void)showOrHideEmptyView
{
    self.emptyView.hidden = self.messageList.count > 0;
}

- (UIView *)emptyView
{
    if (!_emptyView) {
        _emptyView = [[UIView alloc] initWithFrame:self.view.bounds];
        _emptyView.backgroundColor = UIColor.clearColor;
        [self.view addSubview:_emptyView];
        UILabel *textLabel = [[UILabel alloc] initWithFrame:_emptyView.bounds];
        textLabel.font = [UIFont boldSystemFontOfSize:30];
        textLabel.textColor = UIColor.grayColor;
        textLabel.textAlignment = NSTextAlignmentCenter;
        textLabel.text = @"暂无收藏消息".nim_localized;
        [_emptyView addSubview:textLabel];
    }
    return _emptyView;
}

@end
