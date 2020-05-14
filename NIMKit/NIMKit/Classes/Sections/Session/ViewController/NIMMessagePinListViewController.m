//
//  NIMPinMessageViewController.m
//  NIM
//
//  Created by 丁文超 on 2020/3/18.
//  Copyright © 2020 Netease. All rights reserved.
//

#import "NIMMessagePinListViewController.h"
#import "NIMMessagePinItemCell.h"
#import "NIMMessageModel.h"
#import "NIMMessageMaker.h"
#import "NIMLoadMoreFooterView.h"
#import "NIMSessionViewController.h"
#import "UIView+NIMToast.h"
#import "NIMKit.h"
#import "NSString+NIMKit.h"
#import "NIMKitInfoFetchOption.h"
#import "NSString+NIMKit.h"
#import "NIMMessageCellFactory.h"
#import "NIMKitAudioCenter.h"

@interface NIMMessagePinListViewController () <UITableViewDataSource,UITableViewDelegate,NIMMessageCellDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSString *,NIMMessageModel *> *messageDic;
@property (nonatomic, strong) NSMutableArray<NIMMessagePinItem *> *pinList;
@property (nonatomic, strong) NIMMessageCellFactory *cellFactory;

@property (nonatomic, weak) NIMSession *session;
@property (nonatomic, weak) NIMSessionViewController *sessionViewController;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *emptyView;

- (void)showOperationsForMessage:(NIMMessage *)message;
- (void)showOrHideEmptyView;

@end

@implementation NIMMessagePinListViewController

- (instancetype)initWithSession:(NIMSession *)session
{
    self = [super init];
    if (self) {
        self.title = @"标记消息".nim_localized;
        self.session = session;
        self.messageDic = NSMutableDictionary.dictionary;
        self.pinList = NSMutableArray.array;
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
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.sectionHeaderHeight = 20;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = UIView.new;
    [self.tableView registerClass:NIMMessagePinItemCell.class forCellReuseIdentifier:@"Cell"];
    [self.view addSubview:self.tableView];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self beginLoading];
}

- (void)dealloc
{
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.pinList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NIMMessagePinItem *pinItem = self.pinList[indexPath.row];
    NIMMessageModel *messageModel = self.messageDic[pinItem.messageId];
    NIMMessageCell *cell = [self.cellFactory cellInTable:tableView forMessageMode:messageModel];
    cell.delegate = self;
    [cell refreshData:messageModel];
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return UIView.new;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NIMMessagePinItem *pinItem = self.pinList[indexPath.row];
    NIMMessageModel *model = self.messageDic[pinItem.messageId];
    CGSize size = [model contentSize:tableView.frame.size.width];
    CGFloat avatarMarginY = [model avatarMargin].y;
    CGFloat cellHeight = 0;
    CGFloat pinHeight = 22;
    UIEdgeInsets contentViewInsets = model.contentViewInsets;
    UIEdgeInsets bubbleViewInsets  = model.bubbleViewInsets;
    cellHeight = size.height + contentViewInsets.top + contentViewInsets.bottom + bubbleViewInsets.top + bubbleViewInsets.bottom + pinHeight;
    cellHeight = cellHeight > (model.avatarSize.height + avatarMarginY) ? cellHeight : model.avatarSize.height + avatarMarginY;
    return cellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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

- (void)beginLoading
{
    __weak typeof(self) wself = self;
    [NIMSDK.sharedSDK.chatExtendManager loadMessagePinsForSession:self.session completion:^(NSError * _Nullable error, NSArray<NIMMessagePinItem *> * _Nullable items) {
        __weak typeof(self) sself = wself;
        if (!sself) {
            return;
        }
        NSArray<NSString *> *messageIds = [items valueForKey:@"messageId"];
        NSArray<NIMMessage *> *messages = [NIMSDK.sharedSDK.conversationManager messagesInSession:self.session messageIds:messageIds];
        for (NIMMessage *message in messages) {
            if (message.isDeleted) {
                // 过滤已经删除的消息
                continue;
            }
            NIMMessageModel *model = [[NIMMessageModel alloc] initWithMessage:message];
            model.enableRepliedContent = NO;
            model.enableQuickComments = NO;
            model.enableSubMessages = NO;
            model.shouldShowPinContent = YES;
            sself.messageDic[model.message.messageId] = model;
        }
        // 给所有的model添加pinUserName
        NIMKitInfoFetchOption *option = [[NIMKitInfoFetchOption alloc] init];
        option.session = self.session;
        for (NIMMessagePinItem *item in items) {
            if (!sself.messageDic[item.messageId]) {
                // 过滤已经删除的消息所对应的PIN
                continue;
            }
            NSString *accID = item.accountID ?: NIMSDK.sharedSDK.loginManager.currentAccount;
            NIMMessageModel *model = sself.messageDic[item.messageId];
            model.pinUserName = [NIMKit.sharedKit infoByUser:accID option:option].showName;
            [sself.pinList addObject:item];
        }
        [sself.tableView reloadData];
        [sself showOrHideEmptyView];
    }];
    
}

- (void)showOperationsForMessage:(NIMMessage *)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:@"跳转至指定位置".nim_localized style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController popViewControllerAnimated:YES];
        if (self.delegate && [self.delegate respondsToSelector:@selector(pinListViewController:didRequestViewMessage:)]) {
            [self.delegate pinListViewController:self didRequestViewMessage:message];
        }
    }]];
    if (message.messageType == NIMMessageTypeText) {
        [alertController addAction:[UIAlertAction actionWithTitle:@"复制".nim_localized style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIPasteboard.generalPasteboard.string = message.text;
            [self.view nim_showToast:@"已复制".nim_localized duration:1.5];
        }]];
    }
    [alertController addAction:[UIAlertAction actionWithTitle:@"转发".nim_localized style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [NIMKit.sharedKit.chatUIManager forwardMessage:message fromViewController:self];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Un-Pin" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSInteger index = [self.pinList indexOfObjectPassingTest:^BOOL(NIMMessagePinItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj.messageId isEqualToString:message.messageId];
        }];
        NIMMessagePinItem *item = self.pinList[index];
        __weak typeof(self) wself = self;
        [NIMSDK.sharedSDK.chatExtendManager removeMessagePin:item completion:^(NSError * _Nullable error, NIMMessagePinItem * _Nullable item) {
            __strong typeof(self) sself = wself;
            if (!sself) {
                return;
            }
            if (error) {
                [sself.view nim_showToast:error.localizedDescription duration:2.0];
                return;
            }
            sself.messageDic[message.messageId] = nil;
            [sself.pinList removeObjectAtIndex:index];
            [sself.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [sself showOrHideEmptyView];
            if (sself.delegate && [sself.delegate respondsToSelector:@selector(pinListViewController:didRemovePinItem:forMessage:)]) {
                [sself.delegate pinListViewController:sself didRemovePinItem:item forMessage:message];
            }
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

- (void)showOrHideEmptyView
{
    self.emptyView.hidden = self.pinList.count > 0;
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
        textLabel.text = @"暂无PIN消息".nim_localized;
        [_emptyView addSubview:textLabel];
    }
    return _emptyView;
}


@end
