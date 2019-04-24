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


@interface NIMSessionInteractorImpl()<NIMLocationViewControllerDelegate,NIMMediaManagerDelegate>

@property (nonatomic,strong) NIMSession  *session;

@property (nonatomic,strong) id<NIMSessionConfig> sessionConfig;

@property (nonatomic,strong) NIMKitMediaFetcher *mediaFetcher;

@property (nonatomic,strong) NSMutableArray *pendingChatroomModels;

@property (nonatomic,strong) NSMutableArray *pendingAudioMessages;

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
        [models addObject:model];
    }
    NIMSessionMessageOperateResult *result = [self.dataSource insertMessageModels:models];
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
    }
    return model;
}

- (NIMMessageModel *)updateMessage:(NIMMessage *)message
{
    NIMMessageModel *model = [self findMessageModel:message];
    if (model)
    {
        NIMSessionMessageOperateResult *result = [self.dataSource updateMessageModel:model];
        NSInteger index = [result.indexpaths.firstObject row];
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

- (NSInteger)findMessageIndex:(NIMMessage *)message {
    if ([message isKindOfClass:[NIMMessage class]]) {
        NIMMessageModel *model = [[NIMMessageModel alloc] initWithMessage:message];
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
            [self.layout update:indexPath];
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
            [wself.layout layoutAfterRefresh];
            NSInteger firstRow = [self findMessageIndex:messages[0]] - 1;
            [wself.layout adjustOffset:firstRow];
            
            if (![self.sessionConfig respondsToSelector:@selector(autoFetchAttachment)]
                || self.sessionConfig.autoFetchAttachment) {
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
            if (![self.sessionConfig respondsToSelector:@selector(autoFetchAttachment)]
                || self.sessionConfig.autoFetchAttachment) {
                [wself.dataSource checkAttachmentState:messages];
            }
        }
        if (handler) {
            handler(messages, error);
        }
    }];
}

- (void)resetMessages:(void (^)(NSError *error))handler
{
    __weak typeof(self) weakSelf = self;
    [self.dataSource resetMessages:^(NSError *error) {
        if([weakSelf.delegate respondsToSelector:@selector(didFetchMessageData)])
        {
            [weakSelf.delegate didFetchMessageData];
            if (handler) {
                handler(error);
            }
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
                
                if (![self.sessionConfig respondsToSelector:@selector(autoFetchAttachment)]
                    || self.sessionConfig.autoFetchAttachment) {
                    [weakSelf.dataSource checkAttachmentState:weakSelf.items];
                }
            }
        }];
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
}

- (void)sendMessage:(NIMMessage *)message completion:(void(^)(NSError *))completion
{
    [[NIMSDK sharedSDK].chatManager sendMessage:message toSession:_session completion:^(NSError *err) {
        if(completion) {
            completion(err);
        }
    }];
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
                    [[NIMSDK sharedSDK].chatManager sendMessage:message toSession:weakSelf.session error:nil];
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
                    
                    [[NIMSDK sharedSDK].chatManager sendMessage:message toSession:weakSelf.session error:nil];
                }
            }
                break;
            case PHAssetMediaTypeVideo:
            {
                NIMMessage *message = [NIMMessageMaker msgWithVideo:path];
                [[NIMSDK sharedSDK].chatManager sendMessage:message toSession:weakSelf.session error:nil];
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


#pragma mark - NIMSessionLayoutDelegate
- (void)onRefresh
{
    __weak typeof(self) wself = self;
    [self loadMessages:^(NSArray *messages, NSError *error) {
        [wself.layout layoutAfterRefresh];
        if (messages.count) {
            NSInteger row = [self findMessageIndex:messages[0]] - 1;
            [wself.layout adjustOffset:row];
        }
        if (messages.count)
        {
            [wself checkReceipts:nil];
            [wself markRead];
        }
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
    if (self.session.sessionType == NIMSessionTypeTeam) {
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




@end
