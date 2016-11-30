//
//  NIMSessionInteraciton.m
//  NIMKit
//
//  Created by chris on 2016/11/7.
//  Copyright © 2016年 NetEase. All rights reserved.
//

#import "NIMSessionInteractorImpl.h"
#import "NIMSDK.h"
#import "NIMMessageModel.h"
#import "NIMKitUIConfig.h"
#import "NIMSessionTableAdapter.h"
#import "NIMKitMediaFetcher.h"
#import "NIMMessageMaker.h"
#import "NIMLocationViewController.h"

static const void * const NTESDispatchMessageDataPrepareSpecificKey = &NTESDispatchMessageDataPrepareSpecificKey;
dispatch_queue_t NTESMessageDataPrepareQueue()
{
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("nim.demo.message.queue", 0);
        dispatch_queue_set_specific(queue, NTESDispatchMessageDataPrepareSpecificKey, (void *)NTESDispatchMessageDataPrepareSpecificKey, NULL);
    });
    return queue;
}


@interface NIMSessionInteractorImpl()<NIMChatManagerDelegate,NIMConversationManagerDelegate,NIMLocationViewControllerDelegate>

@property (nonatomic,strong) NIMSession  *session;

@property (nonatomic,strong) id<NIMSessionConfig> sessionConfig;

@property (nonatomic,strong) NIMKitMediaFetcher *mediaFetcher;

@property (nonatomic,strong) NSMutableArray *pendingChatroomModels;
@end

@implementation NIMSessionInteractorImpl

- (instancetype)initWithSession:(NIMSession *)session
                         config:(id<NIMSessionConfig>)sessionConfig;
{
    self = [super init];
    if (self) {
        _session   = session;
        _sessionConfig = sessionConfig;
        [self addListener];
    }
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSArray *)items
{
    return [self.dataSource items];
}

- (void)addMessages:(NSArray *)messages
{
    NIMMessage *message = messages.firstObject;
    if (message.session.sessionType == NIMSessionTypeChatroom) {
        [self addChatroomMessages:messages];
    }else{
        [self addNormalMessages:messages];
    }
}

- (void)addNormalMessages:(NSArray *)messages
{
    NSMutableArray *models = [[NSMutableArray alloc] init];
    for (NIMMessage *message in messages) {
        NIMMessageModel *model = [[NIMMessageModel alloc] initWithMessage:message];
        [models addObject:model];
    }
    NIMSessionMessageOperateResult *result = [self.dataSource addMessageModels:models];
    for (NIMMessageModel *model in result.messageModels) {
        [self.layout layoutConfig:model];
    }
    [self.layout insert:result.indexpaths animated:YES];
}

- (void)addChatroomMessages:(NSArray *)messages
{
    if (!self.pendingChatroomModels) {
        self.pendingChatroomModels = [[NSMutableArray alloc] init];
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(NTESMessageDataPrepareQueue(), ^{
        NSMutableArray *models = [[NSMutableArray alloc] init];
        for (NIMMessage *message in messages)
        {
            NIMMessageModel *model = [[NIMMessageModel alloc] initWithMessage:message];
            [weakSelf.layout layoutConfig:model];
            [models addObject:model];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.pendingChatroomModels addObjectsFromArray:models];
            [weakSelf processChatroomMessageModels];
        });
    });
}

- (NIMMessageModel *)deleteMessage:(NIMMessage *)message
{
    NIMMessageModel *model = [self findMessageModel:message];
    if (model) {
        NIMSessionMessageOperateResult *result = [self.dataSource deleteMessageModel:model];
        [self.layout remove:result.indexpaths];
    }
    return model;
}

- (NIMMessageModel *)updateMessage:(NIMMessage *)message
{
    NIMMessageModel *model = [self findMessageModel:message];
    if (model) {
        NIMSessionMessageOperateResult *result = [self.dataSource updateMessageModel:model];
        NSInteger index = [result.indexpaths.firstObject row];
        [self checkLayoutConfig:model];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.layout update:indexPath];
    }
    return model;
}

- (NIMMessageModel *)findMessageModel:(NIMMessage *)message
{
    if ([message isKindOfClass:[NIMMessage class]]) {
        return [self.dataSource findModel:message];
    }
    return nil;
}

- (NIMMessageModel *)makeMessageModel:(NIMMessage *)message
{
    NIMMessageModel *model = [self.dataSource findModel:message];
    if (!model) {
        model = [[NIMMessageModel alloc] initWithMessage:message];
    }
    [self checkLayoutConfig:model];
    return model;
}

- (void)checkReceipt
{
    NSDictionary *models = [self.dataSource checkReceipt];
    for (NSNumber *index in models.allKeys) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index.integerValue inSection:0];
        [self.layout update:indexPath];
    }
}

- (void)markAllMessagesRead
{
    [[NIMSDK sharedSDK].conversationManager markAllMessagesReadInSession:self.session];
}

- (void)sendMessageReceipt:(NSArray *)messages
{
    [self.dataSource sendMessageReceipt:messages];
}

- (void)resetLayout
{
    [self.layout resetLayout];
}

- (void)changeLayout:(CGFloat)inputHeight
{
    [self.layout changeLayout:inputHeight];
}

- (void)cleanCache
{
    [self.dataSource cleanCache];
}

- (void)checkLayoutConfig:(NIMMessageModel *)messageModel
{
    messageModel.sessionConfig = self.sessionConfig;
    [self.layout layoutConfig:messageModel];
}

- (void)loadMessages:(void (^)(NSArray *messages, NSError *error))handler
{
    __weak typeof(self) wself = self;
    [self.dataSource loadHistoryMessagesWithComplete:^(NSInteger index, NSArray *messages, NSError *error) {
        if (handler) {
            handler(messages,error);
        }
        if (messages.count) {
            [wself.layout layoutAfterRefresh];
            [wself.dataSource checkAttachmentState:messages];
        }
    }];
}

- (void)resetMessages
{
    __weak typeof(self) weakSelf = self;
    [self.dataSource resetMessages:^(NSError *error) {
        if([weakSelf.delegate respondsToSelector:@selector(didFetchMessageData)])
        {
            [weakSelf.delegate didFetchMessageData];
        }
    }];
}

- (void)autoFetchMessages
{
    if (![self.sessionConfig respondsToSelector:@selector(autoFetchWhenOpenSession)]
        || self.sessionConfig.autoFetchWhenOpenSession) {
        __weak typeof(self) weakSelf = self;
        [self.dataSource resetMessages:^(NSError *error) {
            if([weakSelf.delegate respondsToSelector:@selector(didFetchMessageData)])
            {
                [weakSelf.delegate didFetchMessageData];
            }
        }];
    }
}


- (void)setDataSource:(id<NIMSessionDataSource>)dataSource
{
    _dataSource = dataSource;
    [self.dataSource checkAttachmentState:self.items];
    [self autoFetchMessages];
}


#pragma mark - 消息收发接口
- (void)sendMessage:(NIMMessage *)message
{
    [[[NIMSDK sharedSDK] chatManager] sendMessage:message toSession:_session error:nil];
}


#pragma mark - Notifitcation
- (void)vcBecomeActive:(NSNotification *)notification
{
    NSArray *models = [self.dataSource items];
    [self sendMessageReceipt:models];
}

- (void)onUserInfoHasUpdatedNotification:(NSNotification *)notification {
    [self.delegate didRefreshMessageData];
}

- (void)onTeamMembersHasUpdatedNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    extern NSString *NIMKitInfoKey;
    NSArray *teamIds = userInfo[NIMKitInfoKey];
    if (self.session.sessionType == NIMSessionTypeTeam
        && ([teamIds containsObject:self.session.sessionId] || [teamIds containsObject:[NSNull null]])) {
        [self.delegate didRefreshMessageData];
    }
}

- (void)onTeamInfoHasUpdatedNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    extern NSString *NIMKitInfoKey;
    NSArray *teamIds = userInfo[NIMKitInfoKey];
    
    if (self.session.sessionType == NIMSessionTypeTeam
        && ([teamIds containsObject:self.session.sessionId] || [teamIds containsObject:[NSNull null]])) {
        [self.delegate didRefreshMessageData];
    }
}

#pragma mark - NIMSessionTableDataDelegate

- (void)didRefreshMessageData
{
    if ([self.delegate respondsToSelector:@selector(didRefreshMessageData)]) {
        [self.delegate didRefreshMessageData];
    }
}


#pragma mark - NIMMeidaButton
- (void)mediaPicturePressed
{
    __weak typeof(self) weakSelf = self;
    [self.mediaFetcher fetchPhotoFromLibrary:^(NSString *path, PHAssetMediaType type) {
        NIMMessage *message;
        switch (type) {
            case PHAssetMediaTypeImage:
                message = [NIMMessageMaker msgWithImagePath:path];
                break;
            case PHAssetMediaTypeVideo:
                message = [NIMMessageMaker msgWithVideo:path];
                break;
            default:
                return;
        }
        [[NIMSDK sharedSDK].chatManager sendMessage:message toSession:weakSelf.session error:nil];
    }];
}

- (void)mediaShootPressed
{
    __weak typeof(self) weakSelf = self;
    [self.mediaFetcher fetchMediaFromCamera:^(NSString *path, UIImage *image) {
        NIMMessage *message;
        if (image) {
            message = [NIMMessageMaker msgWithImage:image];
        }else{
            message = [NIMMessageMaker msgWithVideo:path];
        }
        [[NIMSDK sharedSDK].chatManager sendMessage:message toSession:weakSelf.session error:nil];
    }];
}

- (void)mediaLocationPressed
{
    NIMLocationViewController *vc = [[NIMLocationViewController alloc] initWithNibName:nil bundle:nil];
    vc.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:nav animated:YES completion:nil];
}

- (void)onSendLocation:(NIMKitLocationPoint *)locationPoint{ 
    NIMMessage *message = [NIMMessageMaker msgWithLocation:locationPoint];
    [[NIMSDK sharedSDK].chatManager sendMessage:message toSession:self.session error:nil];
}



#pragma mark - Private
- (NIMKitMediaFetcher *)mediaFetcher
{
    if (!_mediaFetcher) {
        _mediaFetcher = [[NIMKitMediaFetcher alloc] init];
    }
    return _mediaFetcher;
}

- (void)addListener
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(vcBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    if (self.session.sessionType == NIMSessionTypeTeam) {
        extern NSString *const NIMKitTeamInfoHasUpdatedNotification;
        extern NSString *const NIMKitTeamMembersHasUpdatedNotification;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTeamInfoHasUpdatedNotification:) name:NIMKitTeamInfoHasUpdatedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTeamMembersHasUpdatedNotification:) name:NIMKitTeamMembersHasUpdatedNotification object:nil];
    }
    
    extern NSString *const NIMKitUserInfoHasUpdatedNotification;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoHasUpdatedNotification:) name:NIMKitUserInfoHasUpdatedNotification object:nil];
}

- (void)processChatroomMessageModels
{
    NSInteger pendingMessageCount = self.pendingChatroomModels.count;
    if (pendingMessageCount == 0) {
        return;
    }
    if ([self.layout canInsertChatroomMessages])
    {
        static NSInteger NTESMaxInsert = 2;
        NSArray *insert = nil;
        NSRange range;
        if (pendingMessageCount > NTESMaxInsert)
        {
            range = NSMakeRange(0, NTESMaxInsert);
        }
        else
        {
            range = NSMakeRange(0, pendingMessageCount);
        }
        insert = [self.pendingChatroomModels subarrayWithRange:range];
        [self.pendingChatroomModels removeObjectsInRange:range];
        NSUInteger leftPendingMessageCount = self.pendingChatroomModels.count;
        BOOL animated = leftPendingMessageCount== 0;
        NIMSessionMessageOperateResult *result = [self.dataSource addMessageModels:insert];
        [self.layout insert:result.indexpaths animated:animated];
        [self processChatroomMessageModels];
    }
    else
    {
        //不能插入是为了保证界面流畅，比如滑动，此时暂停处理
        __weak typeof(self) weakSelf = self;
        NSTimeInterval delay = 1;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf processChatroomMessageModels];
        });
    }
}



@end
