//
//  NIMSessionViewController.m
//  NIMKit
//
//  Created by NetEase.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMSessionViewController.h"
#import "NIMInputView.h"
#import "NIMInputTextView.h"
#import "NIMSessionViewLayoutManager.h"
#import "UIView+NIM.h"
#import "NIMMessageCellProtocol.h"
#import "NIMMessageModel.h"
#import "NIMKitUtil.h"
#import "NIMCustomLeftBarView.h"
#import "NIMBadgeView.h"
#import "UITableView+NIMScrollToBottom.h"
#import "NIMMessageMaker.h"
#import "NIMDefaultValueMaker.h"
#import "NIMTimestampModel.h"
#import "NIMTimestampConfig.h"
#import "NIMMessageCellMaker.h"
#import "NIMUIConfig.h"

@interface NIMSessionViewController ()
<UITableViewDataSource,
UITableViewDelegate,
NIMChatManagerDelegate,
NIMConversationManagerDelegate,
NIMTeamManagerDelegate,
NIMMediaManagerDelgate,
NIMMessageCellDelegate>

@property (nonatomic,strong,readwrite) UITableView *tableView;

@property (nonatomic,strong) NIMInputView *sessionInputView;
@property (nonatomic,strong) NIMSessionViewLayoutManager *layoutManager;
@property (nonatomic,strong) NIMSessionMsgDatasource *sessionDatasource;
@property (nonatomic,readwrite)   NIMMessage *messageForMenu;

@end

@implementation NIMSessionViewController

- (instancetype)initWithSession:(NIMSession *)session{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _session = session;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self makeUI];
    [self makeHandlerAndDataSource];
}

-(void)dealloc
{
    _tableView.delegate = nil;
    _tableView.dataSource = nil;
    [[NIMSDK sharedSDK].chatManager removeDelegate:self];
    [[NIMSDK sharedSDK].conversationManager removeDelegate:self];
    [[NIMSDK sharedSDK].teamManager removeDelegate:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)makeUI
{
    self.navigationItem.title = [self sessionTitle];
    NIMCustomLeftBarView *leftBarView = [[NIMCustomLeftBarView alloc] init];
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithCustomView:leftBarView];
    self.navigationItem.leftBarButtonItem = leftItem;
    self.navigationItem.leftItemsSupplementBackButton = YES;

    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.backgroundColor = NIMKit_UIColorFromRGB(0xe4e7ec);
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    
    _refreshControl = [[UIRefreshControl alloc] init];
    [self.tableView addSubview:_refreshControl];
    [self.refreshControl addTarget:self action:@selector(headerRereshing:) forControlEvents:UIControlEventValueChanged];
    
    CGRect inputViewRect = CGRectMake(0, 0, self.view.nim_width, [NIMUIConfig topInputViewHeight]);
    BOOL disableInputView = NO;
    if ([self.sessionConfig respondsToSelector:@selector(disableInputView)]) {
        disableInputView = [self.sessionConfig disableInputView];
    }
    if (!disableInputView) {
        self.sessionInputView = [[NIMInputView alloc] initWithFrame:inputViewRect];
        [self.sessionInputView setInputConfig:[self sessionConfig]];
        [self.sessionInputView setInputActionDelegate:self];
        [self.view addSubview:self.sessionInputView];
    }
}

- (void)makeHandlerAndDataSource
{
    _layoutManager = [[NIMSessionViewLayoutManager alloc] initWithInputView:self.sessionInputView tableView:self.tableView];
    
    //数据
    id<NIMKitMessageProvider> dataProvider = [self.sessionConfig respondsToSelector:@selector(messageDataProvider)] ? [self.sessionConfig messageDataProvider] : nil;
    NSInteger limit = [NIMUIConfig messageLimit];
    if ([self.sessionConfig respondsToSelector:@selector(messageLimit)]) {
        limit = self.sessionConfig.messageLimit;
    }
    NSTimeInterval showTimestampInterval = [NIMUIConfig messageTimeInterval];
    if ([self.sessionConfig respondsToSelector:@selector(showTimeInterval)]) {
        showTimestampInterval = [self.sessionConfig showTimestampInterval];
    }
    _sessionDatasource = [[NIMSessionMsgDatasource alloc] initWithSession:_session dataProvider:dataProvider showTimeInterval:showTimestampInterval limit:limit];
    _sessionDatasource.delegate = self;
    [_sessionDatasource resetMessages:nil];

    [[[NIMSDK sharedSDK] chatManager] addDelegate:self];
    [[[NIMSDK sharedSDK] conversationManager] addDelegate:self];
    if (self.session.sessionType == NIMSessionTypeTeam) {
        [[[NIMSDK sharedSDK] teamManager] addDelegate:self];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.sessionInputView endEditing:YES];
}


- (void)viewDidLayoutSubviews{
    [self changeLeftBarBadge:[[NIMSDK sharedSDK] conversationManager].allUnreadCount];
    [_layoutManager setViewRect:self.view.frame];
    [self.tableView nim_scrollToBottom:NO];
    self.sessionInputView.nim_bottom = self.view.nim_height;
}

#pragma mark - UITableViewDataSource & UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.sessionDatasource msgCount];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    id model = [[_sessionDatasource modelArray] objectAtIndex:indexPath.row];
    if ([model isKindOfClass:[NIMMessageModel class]]) {
        cell = [NIMMessageCellMaker cellInTable:tableView
                                 forMessageMode:model];
        [(NIMMessageCell *)cell setMessageDelegate:self];
    }
    else if ([model isKindOfClass:[NIMTimestampModel class]])
    {
        cell = [NIMMessageCellMaker cellInTable:tableView
                                   forTimeModel:model];
    }
    else
    {
        NSAssert(0, @"not support model");
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellHeight = 0;
    id modelInArray = [[_sessionDatasource modelArray] objectAtIndex:indexPath.row];
    if ([modelInArray isKindOfClass:[NIMMessageModel class]])
    {
        NIMMessageModel *model = (NIMMessageModel *)modelInArray;
        NSAssert([model respondsToSelector:@selector(contentSize)], @"config must have a cell height value!!!");
        [self layoutConfig:model];
        CGSize size = model.contentSize;
        UIEdgeInsets contentViewInsets = model.contentViewInsets;
        UIEdgeInsets bubbleViewInsets  = model.bubbleViewInsets;
        cellHeight = size.height + contentViewInsets.top + contentViewInsets.bottom + bubbleViewInsets.top + bubbleViewInsets.bottom;
    }
    else if ([modelInArray isKindOfClass:[NIMTimestampModel class]])
    {
        cellHeight = [modelInArray height];
    }
    else
    {
        NSAssert(0, @"not support model");
    }
    return cellHeight;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
}

#pragma mark - 消息收发接口
- (void)sendMessage:(NIMMessage *)message
{
    [[[NIMSDK sharedSDK] chatManager] sendMessage:message toSession:_session error:nil];
}

//发送消息
- (void)willSendMessage:(NIMMessage *)message
{
    if ([message.session isEqual:_session]) {
        if ([self findModel:message]) {
            [self uiUpdateMessage:message];
        }else{
            [self uiAddMessages:@[message]];
        }

    }
}

//发送结果
- (void)sendMessage:(NIMMessage *)message didCompleteWithError:(NSError *)error
{
    if ([message.session isEqual:_session]) {
        NIMMessageModel *model = [self makeModel:message];
        NSInteger index = [self.sessionDatasource indexAtModelArray:model];
        [self.layoutManager updateCellAtIndex:index model:model];
    }
}

//发送进度
-(void)sendMessage:(NIMMessage *)message progress:(CGFloat)progress
{
    if ([message.session isEqual:_session]) {
        NIMMessageModel *model = [self makeModel:message];
        [_layoutManager updateCellAtIndex:[self.sessionDatasource indexAtModelArray:model] model:model];
    }
}

//接收消息
- (void)onRecvMessages:(NSArray *)messages
{
    NIMSession *session = [[messages firstObject] session];
    if (![session isEqual:self.session] || !messages.count){
        return;
    }
    [self uiAddMessages:messages];
    [[NIMSDK sharedSDK].conversationManager markAllMessageReadInSession:self.session];
}


- (void)fetchMessageAttachment:(NIMMessage *)message progress:(CGFloat)progress
{
    if ([message.session isEqual:_session]) {
        NIMMessageModel *model = [self makeModel:message];
        [_layoutManager updateCellAtIndex:[self.sessionDatasource indexAtModelArray:model] model:model];
    }
}

- (void)fetchMessageAttachment:(NIMMessage *)message didCompleteWithError:(NSError *)error
{
    if ([message.session isEqual:_session]) {
        NIMMessageModel *model = [self makeModel:message];
        [_layoutManager updateCellAtIndex:[self.sessionDatasource indexAtModelArray:model] model:model];
    }
}


#pragma mark - NIMConversationManagerDelegate
- (void)messagesDeletedInSession:(NIMSession *)session{
    [self.sessionDatasource resetMessages:nil];
    [self.tableView reloadData];
}

- (void)didAddRecentSession:(NIMRecentSession *)recentSession
           totalUnreadCount:(NSInteger)totalUnreadCount{
    [self changeUnreadCount:recentSession totalUnreadCount:totalUnreadCount];
}

- (void)didUpdateRecentSession:(NIMRecentSession *)recentSession
              totalUnreadCount:(NSInteger)totalUnreadCount{
    [self changeUnreadCount:recentSession totalUnreadCount:totalUnreadCount];
}

- (void)didRemoveRecentSession:(NIMRecentSession *)recentSession
              totalUnreadCount:(NSInteger)totalUnreadCount{
    [self changeUnreadCount:recentSession totalUnreadCount:totalUnreadCount];
}


- (void)changeUnreadCount:(NIMRecentSession *)recentSession
         totalUnreadCount:(NSInteger)totalUnreadCount{
    if ([recentSession.session isEqual:self.session]) {
        return;
    }
    [self changeLeftBarBadge:totalUnreadCount];
}

- (void)changeLeftBarBadge:(NSInteger)unreadCount{
    NIMCustomLeftBarView *leftBarView = (NIMCustomLeftBarView*)self.navigationItem.leftBarButtonItem.customView;
    leftBarView.badgeView.badgeValue = @(unreadCount).stringValue;
    leftBarView.badgeView.hidden = !unreadCount;
}

#pragma mark - NIMTeamManagerDelegate
- (void)onTeamUpdated:(NIMTeam *)team
{
    if (self.session.sessionType == NIMSessionTypeTeam &&
        [self.session.sessionId isEqualToString:team.teamId]) {
        self.navigationItem.title = [self sessionTitle];
    }
}

- (void)onTeamMemberChanged:(NIMTeam *)team{
    if (self.session.sessionType == NIMSessionTypeTeam &&
        [team.teamId isEqualToString:self.session.sessionId]) {
        [self.tableView reloadData];
        self.navigationItem.title = [self sessionTitle];
    }
}


#pragma mark - Touch Event
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [_sessionInputView endEditing:YES];
}

#pragma mark - Private

- (void)layoutConfig:(NIMMessageModel *)model{
    if (model.layoutConfig) {
        return;
    }
    id<NIMCellLayoutConfig> layoutConfig;
    if ([self.sessionConfig respondsToSelector:@selector(layoutConfigWithMessage:)]) {
        layoutConfig = [self.sessionConfig layoutConfigWithMessage:model.message];
    }
    if (!layoutConfig) {
        layoutConfig = [NIMDefaultValueMaker sharedMaker].cellLayoutDefaultConfig;
    }
    model.layoutConfig = layoutConfig;
    [model calculateContent:self.tableView.nim_width];
}


- (NIMMessageModel *)makeModel:(NIMMessage *)message{
    NIMMessageModel *model = [self findModel:message];
    if (!model) {
        model = [[NIMMessageModel alloc] initWithMessage:message];
    }
    [self layoutConfig:model];
    return model;
}

- (NIMMessageModel *)findModel:(NIMMessage *)message{
    NIMMessageModel *model;
    for (NIMMessageModel *item in self.sessionDatasource.modelArray.reverseObjectEnumerator.allObjects) {
        if ([item isKindOfClass:[NIMMessageModel class]] && [item.message isEqual:message]) {
           model = item;
           //防止那种进了会话又退出去再进来这种行为，防止SDK里回调上来的message和会话持有的message不是一个，导致刷界面刷跪了的情况
           model.message = message;
        }
    }
    return model;
}


- (void)headerRereshing:(id)sender
{
    __weak NIMSessionViewLayoutManager *layoutManager = self.layoutManager;
    __weak UIRefreshControl *refreshControl = self.refreshControl;
    [self.sessionDatasource loadHistoryMessagesWithComplete:^(NSInteger index, NSError *error) {
        [layoutManager reloadDataToIndex:index withAnimation:NO];
        [refreshControl endRefreshing];
    }];
}
#pragma marlk - 通知
- (void)messageDataIsReady{
    [self.tableView reloadData];
    [self.tableView nim_scrollToBottom:NO];
}


#pragma mark - 会话title
- (NSString *)sessionTitle
{
    NSString *title = @"";
    NIMSessionType type = self.session.sessionType;
    switch (type) {
        case NIMSessionTypeTeam:{
            NIMTeam *team = [[[NIMSDK sharedSDK] teamManager] teamById:self.session.sessionId];
            title = [NSString stringWithFormat:@"%@(%zd)",[team teamName],[team memberNumber]];
        }
            break;
        case NIMSessionTypeP2P:{
            if ([self.session.sessionId isEqualToString:[NIMSDK sharedSDK].loginManager.currentAccount]) {
                title = @"我的电脑";
            }else{
                title = [NIMKitUtil showNick:self.session.sessionId inSession:self.session];
            }
        }
            break;
        default:
            break;
    }
    return title;
}

#pragma mark - NIMMediaManagerDelegate
- (void)recordAudio:(NSString *)filePath didBeganWithError:(NSError *)error {
    if (filePath && error == nil) {
        _sessionInputView.recording = YES;
    }
    else{
        [self onRecordFailed:error];
    }
}

- (void)recordAudio:(NSString *)filePath didCompletedWithError:(NSError *)error {
    if(!error) {
        if ([self recordFileCanBeSend:filePath]) {
            [self sendMessage:[NIMMessageMaker msgWithAudio:filePath]];
        }else{
            [self showRecordFileNotSendReason];
        }
    } else {
        [self onRecordFailed:error];
    }
    _sessionInputView.recording = NO;
}

- (void)recordAudioDidCancelled {
    _sessionInputView.recording = NO;
}

- (void)recordAudioProgress:(NSTimeInterval)currentTime {
    [_sessionInputView updateAudioRecordTime:currentTime];
}

- (void)recordAudioInterruptionBegin {
    [[NIMSDK sharedSDK].mediaManager cancelRecord];
}

#pragma mark - 录音相关接口
- (void)onRecordFailed:(NSError *)error{}

- (BOOL)recordFileCanBeSend:(NSString *)filepath
{
    return YES;
}

- (void)showRecordFileNotSendReason{}


#pragma mark - NIMInputActionDelegate
- (void)onTapMediaItem:(NIMMediaItem *)item{}

- (void)onTextChanged:(id)sender{}

- (void)onSendText:(NSString *)text
{
    NIMMessage *message = [NIMMessageMaker msgWithText:text];
    [self sendMessage:message];
}

- (void)onSelectChartlet:(NSString *)chartletId
                 catalog:(NSString *)catalogId{}

- (void)onCancelRecording
{
    [[NIMSDK sharedSDK].mediaManager cancelRecord];
}

- (void)onStopRecording
{
    [[NIMSDK sharedSDK].mediaManager stopRecord];
}

- (void)onStartRecording
{
    [[NIMSDK sharedSDK].mediaManager recordAudioForDuration:60.f
                                               withDelegate:self];
}

#pragma mark - CellActionDelegate
- (void)onTapCell:(NIMKitEvent *)message{}

- (void)onRetryMessage:(NIMMessage *)message
{
    if (message.isReceivedMsg) {
        [[[NIMSDK sharedSDK] chatManager] fetchMessageAttachment:message
                                                           error:nil];
    }else{
        [[[NIMSDK sharedSDK] chatManager] resendMessage:message
                                                  error:nil];
    }
}

- (void)onLongPressCell:(NIMMessage *)message
                 inView:(UIView *)view
{
    NSArray *items = [self menusItems:message];
    if ([items count] && [self becomeFirstResponder]) {
        UIMenuController *controller = [UIMenuController sharedMenuController];
        controller.menuItems = items;
        _messageForMenu = message;
        [controller setTargetRect:view.bounds inView:view];
        [controller setMenuVisible:YES animated:YES];
        
    }
}

#pragma mark - 配置项
- (id<NIMSessionConfig>)sessionConfig
{
    return nil;
}

#pragma mark - 菜单
- (NSArray *)menusItems:(NIMMessage *)message
{
    NSMutableArray *items = [NSMutableArray array];
    
    if (message.messageType == NIMMessageTypeText) {
        [items addObject:[[UIMenuItem alloc] initWithTitle:@"复制"
                                                    action:@selector(copyText:)]];
    }
    [items addObject:[[UIMenuItem alloc] initWithTitle:@"删除"
                                                action:@selector(deleteMsg:)]];
    return items;
    
}

- (NIMMessage *)messageForMenu
{
    return _messageForMenu;
}


- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    NSArray *items = [[UIMenuController sharedMenuController] menuItems];
    for (UIMenuItem *item in items) {
        if (action == [item action]){
            return YES;
        }
    }
    return NO;
}


- (void)copyText:(id)sender
{
    NIMMessage *message = [self messageForMenu];
    if (message.text.length) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        [pasteboard setString:message.text];
    }
}

- (void)deleteMsg:(id)sender
{
    NIMMessage *message    = [self messageForMenu];
    NIMMessageModel *model = [self makeModel:message];
    [self.layoutManager deleteCellAtIndexs:[self.sessionDatasource deleteMessageModel:model]];
    [[[NIMSDK sharedSDK] conversationManager] deleteMessage:model.message];
}


#pragma mark - 操作接口
- (void)uiAddMessages:(NSArray *)messages{
    NSArray *insert = [self.sessionDatasource addMessages:messages];
    for (NIMMessage *message in messages) {
        NIMMessageModel *model = [[NIMMessageModel alloc] initWithMessage:message];
        [self layoutConfig:model];
    }
    [self.layoutManager insertTableViewCellAtRows:insert];
}

- (void)uiDeleteMessage:(NIMMessage *)message{
    NIMMessageModel *model = [self makeModel:message];
    NSArray *indexs = [self.sessionDatasource deleteMessageModel:model];
    [self.layoutManager deleteCellAtIndexs:indexs];
}

- (void)uiUpdateMessage:(NIMMessage *)message{
    NIMMessageModel *model = [self makeModel:message];
    NSInteger index = [self.sessionDatasource indexAtModelArray:model];
    [self.sessionDatasource.modelArray replaceObjectAtIndex:index withObject:model];
    [self.layoutManager updateCellAtIndex:index model:model];
}


@end
