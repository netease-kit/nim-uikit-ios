//
//  NIMSessionInteraciton.m
//  NIMKit
//
//  Created by chris on 2016/11/7.
//  Copyright © 2016年 NetEase. All rights reserved.
//

#import "NIMSessionInteractorImpl.h"
#import <NIMSDK/NIMSDK.h>
#import "NIMMessageModel.h"
#import "NIMSessionTableAdapter.h"
#import "NIMKitMediaFetcher.h"
#import "NIMMessageMaker.h"
#import "NIMLocationViewController.h"
#import "NIMKitAudioCenter.h"
#import "NIMMessageModel.h"
#import "NIMKitQuickCommentUtil.h"

static const void * const NTESDispatchMessageDataPrepareSpecificKey = &NTESDispatchMessageDataPrepareSpecificKey;

typedef void(^NIMSessionInteractorHandler) (BOOL success, id result);

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


@interface NIMSessionInteractorImpl()<NIMLocationViewControllerDelegate,NIMMediaManagerDelegate>

@property (nonatomic,strong) NIMSession  *session;

@property (nonatomic,strong) id<NIMSessionConfig> sessionConfig;

@property (nonatomic,strong) NIMKitMediaFetcher *mediaFetcher;

@property (nonatomic,strong) NSMutableArray *pendingChatroomModels;

@property (nonatomic,strong) NSMutableArray *pendingAudioMessages;

@property (nonatomic,assign) NIMKitSessionState sessionState;

@property (nonatomic,strong) NIMMessage *referenceMessage;

@end

@implementation NIMSessionInteractorImpl

- (instancetype)initWithSession:(NIMSession *)session
                         config:(id<NIMSessionConfig>)sessionConfig
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
    [[NIMSDK sharedSDK].mediaManager stopPlay];
    [self removeListenner];
}

- (NSArray *)items
{
    return [self.dataSource items];
}

- (void)markRead
{
    if ([self shouldAutoMarkRead])
    {
        [[NIMSDK sharedSDK].conversationManager markAllMessagesReadInSession:self.session];
        
        if ([self shouldHandleReceipt])
        {
            [self sendMessageReceipt:self.items];
        }
    }
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

- (void)insertMessages:(NSArray *)messages
{
    NSMutableArray *models = [[NSMutableArray alloc] init];
    for (NIMMessage *message in messages) {
        NIMMessageModel *model = [[NIMMessageModel alloc] initWithMessage:message];
        model.shouldShowSelect = (_sessionState == NIMKitSessionStateSelect);
        if ([_sessionConfig respondsToSelector:@selector(disableSelectedForMessage:)]) {
            model.disableSelected = [_sessionConfig disableSelectedForMessage:model.message];;
        }
        
        if ([_sessionConfig respondsToSelector:@selector(needShowReplyContent)]) {
            model.enableRepliedContent = [_sessionConfig needShowReplyContent];
        }
        
        if ([_sessionConfig respondsToSelector:@selector(needShowQuickComments)]) {
            model.enableQuickComments = [_sessionConfig needShowQuickComments];
        }
        [models addObject:model];
    }
    
    NIMSessionMessageOperateResult *result = [self.dataSource insertMessageModels:models];
    [self refreshAllChatExtendDatasByModels:models completion:nil];
    [self.layout insert:result.indexpaths animated:YES];
}

- (void)addNormalMessages:(NSArray *)messages
{
    NSMutableArray *models = [[NSMutableArray alloc] init];
    for (NIMMessage *message in messages) {
        if (message.isDeleted)
        {
            continue;
        }        
        NIMMessageModel *model = [[NIMMessageModel alloc] initWithMessage:message];
        model.shouldShowSelect = (_sessionState == NIMKitSessionStateSelect);
        if ([_sessionConfig respondsToSelector:@selector(disableSelectedForMessage:)]) {
            model.disableSelected = [_sessionConfig disableSelectedForMessage:model.message];;
        }
        
        if ([_sessionConfig respondsToSelector:@selector(needShowReplyContent)]) {
            model.enableRepliedContent = [_sessionConfig needShowReplyContent];
        }
        
        if ([_sessionConfig respondsToSelector:@selector(needShowQuickComments)]) {
            model.enableQuickComments = [_sessionConfig needShowQuickComments];
        }
        
        
        // 聊天扩展相关
        [self refreshAllChatExtendDatasByMessage:[self threadMessageOfMessage:message]]; // 刷新父消息
        [self refreshAllChatExtendDatasByModel:model completion:nil]; // 刷新本条消息
        
        [models addObject:model];
    }
    NIMSessionMessageOperateResult *result = [self.dataSource addMessageModels:models];
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
            if (message.isDeleted)
            {
                continue;
            }
            NIMMessageModel *model = [[NIMMessageModel alloc] initWithMessage:message];
            model.shouldShowSelect = (_sessionState == NIMKitSessionStateSelect);
            if ([_sessionConfig respondsToSelector:@selector(disableSelectedForMessage:)]) {
                model.disableSelected = [_sessionConfig disableSelectedForMessage:model.message];;
            }
            if ([_sessionConfig respondsToSelector:@selector(needShowReplyContent)]) {
                model.enableRepliedContent = [_sessionConfig needShowReplyContent];
            }
            
            if ([_sessionConfig respondsToSelector:@selector(needShowQuickComments)]) {
                model.enableQuickComments = [_sessionConfig needShowQuickComments];
            }
            
            [weakSelf.layout calculateContent:model];
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
        
        // 聊天扩展相关
        [self refreshAllChatExtendDatasBySubModel:model completion:nil];
    }
    return model;
}

- (NIMMessageModel *)updateMessage:(NIMMessage *)message
{
    if (!message)
    {
        return nil;
    }
    
    NIMMessageModel *model = [self findMessageModel:message];
    if (model)
    {
        // 聊天扩展相关
        [self refreshAllChatExtendDatasByMessage:[self threadMessageOfMessage:message]];
        [self refreshAllChatExtendDatasByModel:model
                                  completion:nil];
        NIMSessionMessageOperateResult *result = [self.dataSource updateMessageModel:model];
        NSInteger index = [result.indexpaths.firstObject row];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self safelyReloadRowAtIndexPath:indexPath];
    }
    return model;
}

- (void)addPinForMessage:(NIMMessage *)message
{
    __weak typeof(self) wself = self;
    [self.dataSource addPinForMessage:message callback:^(NSError *error) {
        [wself updateMessage:message];
    }];
}

- (void)removePinForMessage:(NIMMessage *)message
{
    __weak typeof(self) wself = self;
    [self.dataSource removePinForMessage:message callback:^(NSError *error) {
        [wself updateMessage:message];
    }];
}

- (void)setSessionState:(NIMKitSessionState)sessionState {
    if (_sessionState != sessionState) {
        [self.dataSource refreshMessageModelShowSelect:(sessionState == NIMKitSessionStateSelect)];
        [self.layout reloadTable];
        _sessionState = sessionState;
    }
}

- (NIMMessageModel *)findMessageModel:(NIMMessage *)message
{
    if ([message isKindOfClass:[NIMMessage class]]) {
        return [self.dataSource findModel:message];
    }
    return nil;
}

- (NSInteger)findMessageIndex:(NIMMessage *)message {
    if ([message isKindOfClass:[NIMMessage class]]) {
        NIMMessageModel *model = [[NIMMessageModel alloc] initWithMessage:message];
        model.shouldShowSelect = (_sessionState == NIMKitSessionStateSelect);
        if ([_sessionConfig respondsToSelector:@selector(disableSelectedForMessage:)]) {
            model.disableSelected = [_sessionConfig disableSelectedForMessage:model.message];;
        }
        if ([_sessionConfig respondsToSelector:@selector(needShowReplyContent)]) {
            model.enableRepliedContent = [_sessionConfig needShowReplyContent];
        }
        if ([_sessionConfig respondsToSelector:@selector(needShowQuickComments)]) {
            model.enableQuickComments = [_sessionConfig needShowQuickComments];
        }
        
        return [self.dataSource indexAtModelArray:model];
    }
    return -1;
}

- (void)checkReceipts:(NSArray<NIMMessageReceipt *> *)receipts
{
    if ([self shouldHandleReceipt])
    {
        NSDictionary *models = [self.dataSource checkReceipts:receipts];
        for (NSNumber *index in models.allKeys) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index.integerValue inSection:0];
            [self safelyReloadRowAtIndexPath:indexPath];
        }
    }
}

- (BOOL)shouldHandleReceipt
{
    return    [self.sessionConfig respondsToSelector:@selector(shouldHandleReceipt)] &&
    [self.sessionConfig shouldHandleReceipt];
}

- (void)markAllMessagesRead
{
    [[NIMSDK sharedSDK].conversationManager markAllMessagesReadInSession:self.session];
}

- (void)sendMessageReceipt:(NSArray *)messages
{
    [self.dataSource sendMessageReceipt:messages];
}

- (void)addQuickComment:(NIMQuickComment *)comment
             completion:(void(^)(NSError *error))completion
{
    NIMMessage *message = self.referenceMessage;
    if (message)
    {
        [self addQuickComment:comment
                    toMessage:message
                   completion:^(NSError *error)
        {
            if (completion)
            {
                completion(error);
            }
        }];
        self.referenceMessage = nil;
    }
}

- (void)addQuickComment:(NIMQuickComment *)comment
              toMessage:(NIMMessage *)message
             completion:(void(^)(NSError *error))completion
{
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].chatExtendManager addQuickComment:comment
                                                toMessage:message
                                               completion:^(NSError * _Nullable error)
    {
        [weakSelf refreshQuickComments:message completion:nil];
        if (completion)
        {
            completion(error);
        }
    }];
}

- (void)delQuickComment:(NIMQuickComment *)comment
          targetMessage:(NIMMessage *)message
             completion:(void(^)(NSError *error))completion
{
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].chatExtendManager deleteQuickComment:comment
                                                  completion:^(NSError * _Nullable error)
    {
        weakSelf.referenceMessage = nil;
        [weakSelf refreshQuickComments:message completion:nil];
        if (completion)
        {
            completion(error);
        }
    }];
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


- (void)loadMessages:(void (^)(NSArray *messages, NSError *error))handler
{
    __weak typeof(self) wself = self;
    [self.dataSource loadHistoryMessagesWithComplete:^(NSInteger index, NSArray *messages, NSError *error) {
        if (messages.count) {
            
            if (wself.session.sessionType != NIMSessionTypeChatroom) {
                [wself refreshAllAfterFetchCommentsByMessages:messages];
            }
            
            if (![wself.sessionConfig respondsToSelector:@selector(autoFetchAttachment)]
                || wself.sessionConfig.autoFetchAttachment) {
                [wself.dataSource checkAttachmentState:messages];
            }
        }
        if (handler) {
            handler(messages,error);
        }
    }];
}

- (void)pullUp {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didPullUpMessageData)]) {
        [self.delegate didPullUpMessageData];
    }
}

- (void)pullUpMessages:(void(^)(NSArray *messages, NSError *error))handler {
    __weak typeof(self) wself = self;
    [self.dataSource loadNewMessagesWithComplete:^(NSInteger index, NSArray *messages, NSError *error) {
        if (messages.count) {
            [wself.layout layoutAfterRefresh];
            if (![wself.sessionConfig respondsToSelector:@selector(autoFetchAttachment)]
                || wself.sessionConfig.autoFetchAttachment) {
                [wself.dataSource checkAttachmentState:messages];
            }
        }
        
        [wself refreshAllAfterFetchCommentsByMessages:messages];
        
        if (handler) {
            handler(messages, error);
        }
    }];
}

- (void)resetMessages:(void (^)(NSError *error))handler
{
    __weak typeof(self) weakSelf = self;
    __block NSError *e = nil;
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    [self.dataSource enhancedResetMessages:^(NSError *error, NSArray *models) {
        [weakSelf refreshAllAfterFetchCommentsByModels:models];

        e = error;
        dispatch_group_leave(group);
    }];
    
    dispatch_group_enter(group);
    [self loadMessagePins:^(NSError *error) {
        dispatch_group_leave(group);
    }];
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        
        if([weakSelf.delegate respondsToSelector:@selector(didFetchMessageData)])
        {
            [weakSelf.delegate didFetchMessageData];
            if (handler) {
                handler(e);
            }
        }
    });
    
    
    
}

- (void)autoFetchMessages
{
    if (![self.sessionConfig respondsToSelector:@selector(autoFetchWhenOpenSession)]
        || self.sessionConfig.autoFetchWhenOpenSession) {
        __weak typeof(self) weakSelf = self;
        dispatch_group_t group = dispatch_group_create();
        
        dispatch_group_enter(group);
        [self.dataSource enhancedResetMessages:^(NSError *error, NSArray *models) {
            [weakSelf refreshAllAfterFetchCommentsByModels:models];
            dispatch_group_leave(group);
        }];
        
        dispatch_group_enter(group);
        [self loadMessagePins:^(NSError *error) {
            dispatch_group_leave(group);
        }];
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            if([weakSelf.delegate respondsToSelector:@selector(didFetchMessageData)])
            {
                [weakSelf.delegate didFetchMessageData];
                
                if (![weakSelf.sessionConfig respondsToSelector:@selector(autoFetchAttachment)]
                    || weakSelf.sessionConfig.autoFetchAttachment) {
                    [weakSelf.dataSource checkAttachmentState:weakSelf.items];
                }
            }
        });
        
    }
}

- (void)setDataSource:(id<NIMSessionDataSource>)dataSource
{
    _dataSource = dataSource;
    [self autoFetchMessages];
}


#pragma mark - 消息收发接口
- (void)sendMessage:(NIMMessage *)message
{    
    [[[NIMSDK sharedSDK] chatManager] sendMessage:message toSession:_session error:nil];
    [self.layout dismissReplyContent];
}

- (void)sendMessage:(NIMMessage *)message toMessage:(NIMMessage *)toMessage
{
    if (toMessage)
    {
        [[[NIMSDK sharedSDK] chatExtendManager] reply:message
                                                   to:toMessage
                                                error:nil];
    }
    else if ([self.sessionConfig respondsToSelector:@selector(threadMessage)] && [self.sessionConfig threadMessage])
    {
        NIMMessage *threadMessage = [self.sessionConfig threadMessage];
        [[[NIMSDK sharedSDK] chatExtendManager] reply:message
                                                   to:threadMessage
                                                error:nil];
        
        if ([self.sessionConfig respondsToSelector:@selector(clearThreadMessageAfterSent)])
        {
            if ([self.sessionConfig clearThreadMessageAfterSent])
            {
                [self.sessionConfig cleanThreadMessage];
            }
        }
    }
    else if (!toMessage)
    {
        [self sendMessage:message];
    }
    
    [self.layout dismissReplyContent];
}

- (void)sendMessage:(NIMMessage *)message completion:(void(^)(NSError *))completion
{
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].chatManager sendMessage:message toSession:_session completion:^(NSError *err) {
        if(completion) {
            completion(err);
        }
        [weakSelf.layout dismissReplyContent];
    }];
}

- (void)sendMessage:(NIMMessage *)message
          toMessage:(NIMMessage *)toMessage
         completion:(void(^)(NSError * error))completion
{
    __weak typeof(self) weakSelf = self;
   if (toMessage)
    {
        [[NIMSDK sharedSDK].chatExtendManager reply:message
                                                to:toMessage
                                        completion:^(NSError * _Nullable error)
         {
            if (completion)
            {
                completion(error);
            }
            [weakSelf refreshAllChatExtendDatasByMessage:[self threadMessageOfMessage:toMessage]];

        }];
    }
    else if ([self.sessionConfig respondsToSelector:@selector(threadMessage)] && [self.sessionConfig threadMessage])
    {
        NIMMessage *threadMessage = [self.sessionConfig threadMessage];
        [[[NIMSDK sharedSDK] chatExtendManager] reply:message
                                                   to:threadMessage
                                           completion:^(NSError * _Nullable error) {
            if ([weakSelf.sessionConfig respondsToSelector:@selector(clearThreadMessageAfterSent)])
            {
                if ([weakSelf.sessionConfig clearThreadMessageAfterSent])
                {
                    [weakSelf.sessionConfig cleanThreadMessage];
                }
            }
            
            if (completion)
            {
                completion(error);
            }
            [weakSelf refreshAllChatExtendDatasByMessage:[weakSelf threadMessageOfMessage:toMessage]];
        }];
    }
    else if (!toMessage)
    {
        [self sendMessage:message completion:completion];
    }
    
    [self.layout dismissReplyContent];
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
    if ((self.session.sessionType == NIMSessionTypeTeam || self.session.sessionType == NIMSessionTypeSuperTeam)
        && ([teamIds containsObject:self.session.sessionId] || [teamIds containsObject:[NSNull null]])) {
        [self.delegate didRefreshMessageData];
    }
}

- (void)onTeamInfoHasUpdatedNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    extern NSString *NIMKitInfoKey;
    NSArray *teamIds = userInfo[NIMKitInfoKey];
    
    if ((self.session.sessionType == NIMSessionTypeTeam || self.session.sessionType == NIMSessionTypeSuperTeam)
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
- (void)mediaAudioPressed:(NIMMessageModel *)messageModel
{
    if (![[NIMSDK sharedSDK].mediaManager isPlaying]) {
        [[NIMSDK sharedSDK].mediaManager switchAudioOutputDevice:NIMAudioOutputDeviceSpeaker];
        self.pendingAudioMessages = [self findRemainAudioMessages:messageModel.message];
        [[NIMKitAudioCenter instance] play:messageModel.message];
        
    } else {
        self.pendingAudioMessages = nil;
        [[NIMSDK sharedSDK].mediaManager stopPlay];
    }
}

- (void)mediaPicturePressed
{
    __weak typeof(self) weakSelf = self;
    [self.mediaFetcher fetchPhotoFromLibrary:^(NSArray *images, NSString *path, PHAssetMediaType type) {
        switch (type) {
            case PHAssetMediaTypeImage:
            {
                for (UIImage *image in images) {
                    NIMMessage *message = [NIMMessageMaker msgWithImage:image];
                    [weakSelf sendMessage:message toMessage:nil];
                }
                if (path) {
                    NIMMessage *message;
                    if ([path.pathExtension isEqualToString:@"HEIC"])
                    {
                        //iOS 11 苹果采用了新的图片格式 HEIC ，如果采用原图会导致其他设备的兼容问题，在上层做好格式的兼容转换,压成 jpeg
                        UIImage *image = [UIImage imageWithContentsOfFile:path];
                        message = [NIMMessageMaker msgWithImage:image];
                    }
                    else
                    {
                        message = [NIMMessageMaker msgWithImagePath:path];
                    }
                    
                    [weakSelf sendMessage:message toMessage:nil];
                }
            }
                break;
            case PHAssetMediaTypeVideo:
            {
                NIMMessage *message = [NIMMessageMaker msgWithVideo:path];
                [weakSelf sendMessage:message toMessage:nil];
            }
                break;
            default:
                return;
        }
        
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
        [weakSelf sendMessage:message toMessage:nil];
    }];
}

- (void)mediaLocationPressed
{
    NIMLocationViewController *vc = [[NIMLocationViewController alloc] initWithNibName:nil bundle:nil];
    vc.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    rootVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [rootVC presentViewController:nav animated:YES completion:nil];
}

- (void)onSendLocation:(NIMKitLocationPoint *)locationPoint{ 
    NIMMessage *message = [NIMMessageMaker msgWithLocation:locationPoint];
    [self sendMessage:message toMessage:nil];
}


- (void)onViewWillAppear
{
    //fix bug: 竖屏进入会话界面，然后右上角进入群信息，再横屏，左上角返回，横屏的会话界面显示的就是竖屏时的大小
    [self cleanCache];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.layout reloadTable];
    });

    [[NIMSDK sharedSDK].mediaManager addDelegate:self];
}

- (void)onViewDidDisappear
{
    [[NIMSDK sharedSDK].mediaManager removeDelegate:self];
}

- (BOOL)messageCanBeSelected:(NIMMessage *)message {
    return YES;
}

- (void)loadMessagePins:(void (^)(NSError *))handler
{
    [self.dataSource loadMessagePins:handler];
}

- (void)willDisplayMessageModel:(NIMMessageModel *)model
{
    [self.dataSource willDisplayMessageModel:model];
}

#pragma mark - NIMSessionLayoutDelegate
- (void)onRefresh
{
    __weak typeof(self) wself = self;
    [self loadMessages:^(NSArray *messages, NSError *error) {
        [wself.layout layoutAfterRefresh];
        if (messages.count) {
            [wself insertMessages:messages];
        }
        if (messages.count)
        {
            [wself checkReceipts:nil];
            [wself markRead];
        }
        
        [wself refreshAllChatExtendDatasByMessages:messages];
    }];
}

#pragma mark - NIMMediaManagerDelegate

- (void)playAudio:(NSString *)filePath didCompletedWithError:(nullable NSError *)error
{
    if (!error)
    {
        BOOL disable = [self.sessionConfig respondsToSelector:@selector(disableAutoPlayAudio)] && [self.sessionConfig disableAutoPlayAudio];
        if (!disable)
        {
            [self playNextAudio];
        }
    }
}

- (void)stopPlayAudio:(NSString *)filePath didCompletedWithError:(nullable NSError *)error
{
    if (!error)
    {
        BOOL disable = [self.sessionConfig respondsToSelector:@selector(disableAutoPlayAudio)] && [self.sessionConfig disableAutoPlayAudio];
        if (!disable)
        {
            [self playNextAudio];
        }
    }
}

- (void)playNextAudio
{
    NIMMessage *message = self.pendingAudioMessages.lastObject;
    if (self.pendingAudioMessages.count) {
        [self.pendingAudioMessages removeLastObject];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NIMKitAudioCenter instance] play:message];
        });
    }
}


#pragma mark - Private

//是否需要开启自动设置所有消息已读 ： 某些场景不需要自动设置消息已读，如使用 3D touch 的场景预览会话界面内容
- (BOOL)shouldAutoMarkRead
{
    BOOL should = YES;
    if ([self.sessionConfig respondsToSelector:@selector(disableAutoMarkMessageRead)]) {
        should = ![self.sessionConfig disableAutoMarkMessageRead];
    }
    return should;
}

- (NIMKitMediaFetcher *)mediaFetcher
{
    if (!_mediaFetcher) {
        _mediaFetcher = [[NIMKitMediaFetcher alloc] init];
    }
    return _mediaFetcher;
}

- (void)addListener
{
    //声音的监听放在 viewWillApear 回调里，不在这里添加
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(vcBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    if (self.session.sessionType == NIMSessionTypeTeam || self.session.sessionType == NIMSessionTypeSuperTeam) {
        extern NSString *const NIMKitTeamInfoHasUpdatedNotification;
        extern NSString *const NIMKitTeamMembersHasUpdatedNotification;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTeamInfoHasUpdatedNotification:) name:NIMKitTeamInfoHasUpdatedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTeamMembersHasUpdatedNotification:) name:NIMKitTeamMembersHasUpdatedNotification object:nil];
    }
    
    extern NSString *const NIMKitUserInfoHasUpdatedNotification;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoHasUpdatedNotification:) name:NIMKitUserInfoHasUpdatedNotification object:nil];
}

- (void)removeListenner
{
    //声音的监听放在 viewDidDisappear 回调里，不在这里移除
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSMutableArray *)findRemainAudioMessages:(NIMMessage *)message
{
    if (message.isPlayed || [message.from isEqualToString:[NIMSDK sharedSDK].loginManager.currentAccount]) {
        //如果这条音频消息被播放过了 或者这条消息是属于自己的消息，则不进行轮播
        return nil;
    }
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    [self.dataSource.items enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NIMMessageModel class]]) {
            NIMMessageModel *model = (NIMMessageModel *)obj;
            BOOL isFromMe = [model.message.from isEqualToString:[[NIMSDK sharedSDK].loginManager currentAccount]];
            if ([model.message.messageId isEqualToString:message.messageId])
            {
                *stop = YES;
            }
            else if (model.message.messageType == NIMMessageTypeAudio && !isFromMe && !model.message.isPlayed)
            {
                [messages addObject:model.message];
            }
        }
    }];
    return messages;
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
        
        //聊天室消息最大保存消息量，超过这个消息量则把消息列表的前一半挪出内存。
        static NSInteger NTESMaxChatroomMessageCount = 200;
        NSInteger count = self.dataSource.items.count;
        if (count > NTESMaxChatroomMessageCount) {
            NSRange deleteRange = NSMakeRange(0, count/2);
            NSArray *delete = [self.dataSource deleteModels:deleteRange];
            [self.layout remove:delete];
        }

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

#pragma mark - 聊天扩展相关

- (void)refreshAllChatExtendDatasByMessage:(NIMMessage *)message
{
    NIMMessageModel *model = [self findMessageModel:message];
    if (model)
    {
        [self refreshAllChatExtendDatasByModel:model completion:nil];
    }
}

- (void)refreshAllChatExtendDatasByMessages:(NSArray<NIMMessage *> *)messages
{
    for (NIMMessage *message in messages)
    {
        [self refreshAllChatExtendDatasByMessage:message];
    }
}

- (void)refreshAllAfterFetchCommentsByMessages:(NSArray<NIMMessage *> *)messages
{
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].chatExtendManager fetchQuickComments:messages
                                                  completion:^(NSError * error, NSMapTable<NIMMessage *,NSArray<NIMQuickComment *> *> * result,NSArray *failedMessages)
    {
        [weakSelf refreshAllChatExtendDatasByMessages:messages];
    }];
}

- (void)refreshAllAfterFetchCommentsByModels:(NSArray<NIMMessageModel *> *)models
{
    NSMutableArray *messages = [NSMutableArray array];
    for(NIMMessageModel *model in models)
    {
        [messages addObject:model.message];
    }
    
    [self refreshAllAfterFetchCommentsByMessages:messages];
}

- (void)refreshAllChatExtendDatasBySubModel:(NIMMessageModel *)model
                                 completion:(NIMSessionInteractorHandler)completion
{
    NIMMessage *message = model.message;
    NIMMessage *threadMessage = [self threadMessageOfMessage:message];
    NIMMessageModel *threadMessageModel = [self findMessageModel:threadMessage];
    if (threadMessage)
    {
        [self refreshAllChatExtendDatasByModel:threadMessageModel completion:completion];
    }
    else
    {
       if (completion)
        {
            completion(NO, nil);
        }
    }
}

- (void)refreshAllChatExtendDatasByModel:(NIMMessageModel *)model
                              completion:(NIMSessionInteractorHandler)completion

{
    
    // Thread & 被回复消息
    __weak typeof(self) weakSelf = self;
    [self loadThreadAndRepliedMessages:model completion:^(BOOL success, id result)
    {
        if (success)
        {
            [weakSelf uiReloadMessageCell:model.message];
        }
        
        if (completion)
        {
            completion(success, result);
        }
    }];
    
    // 该消息的子消息
    [self loadChildMessages:model completion:^(BOOL success, id result)
    {
        if (success)
        {
            [weakSelf uiReloadMessageCell:model.message];
        }
        
        if (completion)
        {
            completion(success, result);
        }
    }];
    
    // 该消息的快捷回复
    [self loadQuickComments:model completion:^(BOOL success, id result)
    {
        if (success)
        {
            [weakSelf uiReloadMessageCell:model.message];
        }
        
        if (completion)
        {
            completion(success, result);
        }
    }];
}


- (void)refreshAllChatExtendDatasByModels:(NSArray<NIMMessageModel *> *)models
                               completion:(NIMSessionInteractorHandler)completion
{
    for (NIMMessageModel *model in models)
    {
        [self refreshAllChatExtendDatasByModel:model completion:nil];
    }
}

- (void)refreshQuickComments:(NIMMessage *)message
                  completion:(NIMSessionInteractorHandler)completion
{
   NIMMessageModel *model = [self findMessageModel:message];
    if (model)
    {
        __weak typeof(self) weakSelf = self;
        [self loadQuickComments:model completion:^(BOOL success, id result) {
            [weakSelf uiReloadMessageCell:message];
            if (completion)
            {
                completion(success, result);
            }
        }];
    }
    else
    {
        if (completion)
        {
            completion(NO, nil);
        }
    }
}

- (void)loadThreadAndRepliedMessages:(NIMMessageModel *)model
                          completion:(NIMSessionInteractorHandler)completion
{
    NIMMessage *message = model.message;
    if (!model.enableRepliedContent || !message)
    {
        if (completion)
        {
            completion(NO, nil);
        }
        return;
    }
    
    // 父消息
    NIMMessage *threadMessage = nil;
    if (message.threadMessageId.length > 0)
    {
       threadMessage = [[[NIMSDK sharedSDK].conversationManager messagesInSession:message.session messageIds:@[message.threadMessageId]] firstObject];
       model.parentMessage = threadMessage;
        if (!threadMessage)
        {
            NIMChatExtendBasicInfo *key = [[NIMChatExtendBasicInfo alloc] init];
            key.messageID = message.threadMessageId;
            key.fromAccount = message.threadMessageFrom;
            key.toAccount = message.threadMessageTo;
            key.serverID = message.threadMessageServerId;
            key.timestamp = message.threadMessageTime;
            key.type = message.session.sessionType;
            
            if (key.messageID.length == 0)
            {
                if (completion)
                {
                    completion(NO, nil);
                }
                return;
            }
            
            [self fetchMessageInfo:key completion:^(BOOL success, NIMMessage *result) {
                model.parentMessage = result;
                
                if (completion)
                {
                    completion(success, nil);
                }
            }];
        }
        else
        {
            if (completion)
            {
                completion(YES, nil);
            }
        }
    }
    
    // 被回复消息
    NIMMessage *repliedMessage = nil;
    if (message.repliedMessageId.length > 0)
    {
       repliedMessage = [[[NIMSDK sharedSDK].conversationManager messagesInSession:message.session
                                                                        messageIds:@[message.repliedMessageId]] firstObject];
        if (!repliedMessage)
        {
            NIMChatExtendBasicInfo *key = [[NIMChatExtendBasicInfo alloc] init];
            key.messageID = message.repliedMessageId;
            key.fromAccount = message.repliedMessageFrom;
            key.toAccount = message.repliedMessageTo;
            key.serverID = message.repliedMessageServerId;
            key.timestamp = message.repliedMessageTime;
            key.type = message.session.sessionType;
            
            if (!key)
            {
                if (completion)
                {
                    completion(NO, nil);
                }
                return;
            }
            
            [self fetchMessageInfo:key completion:^(BOOL success, NIMMessage *result) {
                model.repliedMessage = result;
                
                if (completion)
                {
                    completion(success, nil);
                }
            }];
        }
        else
        {
            model.repliedMessage = repliedMessage;
            if (completion)
            {
                completion(YES, nil);
            }
        }
    }
}

- (void)fetchMessageInfo:(NIMChatExtendBasicInfo *)info
              completion:(NIMSessionInteractorHandler)completion
{
    if (!info)
    {
        if (completion)
        {
            completion(NO, nil);
        }
        return;
    }
    
    [[NIMSDK sharedSDK].chatExtendManager fetchHistoryMessages:@[info]
                                                      syncToDB:YES
                                                    completion:^(NSError * error, NSMapTable<NIMChatExtendBasicInfo *,NIMMessage *> * result)
    {
        if (error)
        {
            if (completion)
            {
                completion(NO, nil);
            }
            return;
        }
        
        completion(YES, [result objectForKey:info]);
    }];
}

- (void)loadChildMessages:(NIMMessageModel *)model
               completion:(NIMSessionInteractorHandler)completion
{
    NIMMessage *message = model.message;
    if (!model.enableSubMessages || !message)
    {
        if (completion)
        {
            completion(NO, nil);
        }
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray *subMessages = [[NIMSDK sharedSDK].chatExtendManager subMessages:message];
        model.childMessages = subMessages;
        model.childMessagesCount = [[NIMSDK sharedSDK].chatExtendManager subMessagesCount:message];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion)
            {
                completion(YES, subMessages);
            }
        });
        
    });
}

- (void)loadQuickComments:(NIMMessageModel *)model
               completion:(NIMSessionInteractorHandler)completion
{
    NIMMessage *message = model.message;
    if (!model.enableQuickComments || !message)
    {
        if (completion)
        {
            completion(NO, nil);
        }
        return;
    }
    
    [[NIMSDK sharedSDK].chatExtendManager quickCommentsByMessage:message
                                                      completion:^(NSError * _Nullable error, NSMapTable<NSNumber *,NIMQuickComment *> * _Nullable result)
    {
        if (completion)
        {
            model.quickComments = result;
            if (result.count > 0)
            {
                model.emoticonsContainerSize = [NIMKitQuickCommentUtil containerSizeWithComments:result];
            }
            else
            {
                model.emoticonsContainerSize = CGSizeZero;
            }
            if (error) {
                completion(NO, nil);
            } else {
                completion(YES, result);
            }
        }
    }];
}

- (void)uiReloadThreadMessageBySubMessage:(NIMMessageModel *)model
{
    NIMMessage *message = model.message;
    NIMMessage *threadMessage = [self threadMessageOfMessage:message];
    if (threadMessage)
    {
        [self uiReloadMessageCell:threadMessage];
    }
}

- (void)uiReloadMessageCell:(NIMMessage *)message
{
    if (!message)
    {
        return;
    }
    NIMMessageModel *model = [self findMessageModel:message];
    if (model)
    {
        NIMSessionMessageOperateResult *result = [self.dataSource updateMessageModel:model];
        NSInteger index = [result.indexpaths.firstObject row];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self safelyReloadRowAtIndexPath:indexPath];
    }
    return;
}


- (NIMMessage *)threadMessageOfMessage:(NIMMessage *)message
{
    NIMSession *session = message.session;
    NSString *messageID = message.threadMessageId;
    if (messageID.length == 0)
    {
        return nil;
    }
    return [[[NIMSDK sharedSDK].conversationManager messagesInSession:session messageIds:@[messageID]] firstObject];
}

- (void)safelyReloadRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.dataSource.items.count != [self.layout numberOfRows]) {
        NSLog(@"Error: trying to reload message while cell count: %zd is not equal to item count %zd.", [self.layout numberOfRows], self.dataSource.items.count);
        return;
    }
    [self.layout update:indexPath];
}


@end
