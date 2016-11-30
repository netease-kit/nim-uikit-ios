//
//  NIMSessionTableData.m
//  NIMKit
//
//  Created by chris on 2016/11/7.
//  Copyright © 2016年 NetEase. All rights reserved.
//

#import "NIMSessionDataSourceImpl.h"
#import "NIMSessionMsgDatasource.h"

@interface NIMSessionDataSourceImpl()

@property (nonatomic,strong) NIMSession *session;

@property (nonatomic,strong) NIMSessionMsgDatasource *dataSource;

@property (nonatomic,strong) NSMutableArray *pendingMessages;   //缓存的插入消息,聊天室需要在另外个线程计算高度,减少UI刷新

@property (nonatomic,strong) id<NIMSessionConfig> sessionConfig;

@end

@implementation NIMSessionDataSourceImpl

- (instancetype)initWithSession:(NIMSession *)session
                         config:(id<NIMSessionConfig>)sessionConfig
{
    self = [super init];
    if (self) {
        _session = session;
        _sessionConfig = sessionConfig;
        _pendingMessages = [[NSMutableArray alloc] init];
        _dataSource = [[NIMSessionMsgDatasource alloc] initWithSession:_session config:_sessionConfig];
    }
    return self;
}

- (NSArray *)items
{
    return self.dataSource.items;
}

- (NIMSessionMessageOperateResult *)addMessageModels:(NSArray *)models
{
    for (NIMMessageModel *model in models)
    {
        model.sessionConfig = self.sessionConfig;
    }
    NSArray *indexpaths = [self.dataSource addMessageModels:models];
    NIMSessionMessageOperateResult *result = [[NIMSessionMessageOperateResult alloc] init];
    result.indexpaths = indexpaths;
    result.messageModels = models;
    return result;
}

- (NIMSessionMessageOperateResult *)deleteMessageModel:(NIMMessageModel *)model
{
    NSArray *indexs = [self.dataSource deleteMessageModel:model];
    NIMSessionMessageOperateResult *result = [[NIMSessionMessageOperateResult alloc] init];
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    for (NSNumber *index in indexs) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index.integerValue inSection:0];
        [indexPaths addObject:indexPath];
    }
    result.indexpaths    = indexPaths;
    result.messageModels = @[model];
    return result;
}

- (NIMSessionMessageOperateResult *)updateMessageModel:(NIMMessageModel *)model
{
    NSInteger index = [self.dataSource indexAtModelArray:model];
    [[self.dataSource items] replaceObjectAtIndex:index withObject:model];
    NIMSessionMessageOperateResult *result = [[NIMSessionMessageOperateResult alloc] init];
    NSIndexPath *indexpath = [NSIndexPath indexPathForRow:index inSection:0];
    result.indexpaths = @[indexpath];
    result.messageModels = @[model];
    return result;
}

- (NSInteger)indexAtModelArray:(NIMMessageModel *)model
{
    return [self.dataSource indexAtModelArray:model];
}

- (NSArray *)deleteModels:(NSRange)range
{
    return [self.dataSource deleteModels:range];
}

- (NIMMessageModel *)findModel:(NIMMessage *)message{
    NIMMessageModel *model;
    for (NIMMessageModel *item in self.dataSource.items.reverseObjectEnumerator.allObjects) {
        if ([item isKindOfClass:[NIMMessageModel class]] && [item.message.messageId isEqual:message.messageId]) {
            model = item;
            //防止那种进了会话又退出去再进来这种行为，防止SDK里回调上来的message和会话持有的message不是一个，导致刷界面刷跪了的情况
            model.message = message;
        }
    }
    return model;
}

- (void)cleanCache
{
    [self.dataSource cleanCache];
}

- (void)resetMessages:(void(^)(NSError *error))handler{
    [self.dataSource resetMessages:handler];
}

- (void)loadHistoryMessagesWithComplete:(void(^)(NSInteger index, NSArray *messages , NSError *error))handler{
    [self.dataSource loadHistoryMessagesWithComplete:handler];
}

- (void)checkAttachmentState:(NSArray *)messages{
    for (id item in messages) {
        NIMMessage *message;
        if ([item isKindOfClass:[NIMMessage class]]) {
            message = item;
        }
        if ([item isKindOfClass:[NIMMessageModel class]]) {
            message = [(NIMMessageModel *)item message];
        }
        if (message && message.attachmentDownloadState == NIMMessageAttachmentDownloadStateNeedDownload) {
            [[NIMSDK sharedSDK].chatManager fetchMessageAttachment:message error:nil];
        }
    }
}

- (NSDictionary *)checkReceipt
{
    BOOL hasConfig = self.sessionConfig && [self.sessionConfig respondsToSelector:@selector(shouldHandleReceiptForMessage:)];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    BOOL findLastReceipt = NO;
    
    for (NSInteger i = [[self.dataSource items] count] - 1; i >= 0; i--) {
        id item = [[self.dataSource items] objectAtIndex:i];
        if ([item isKindOfClass:[NIMMessageModel class]]) {
            NIMMessageModel *model = (NIMMessageModel *)item;
            NIMMessage *message = [model message];
            if (message.isOutgoingMsg) {
                
                if (!findLastReceipt) {
                    
                    if (message.isRemoteRead && hasConfig && [self.sessionConfig shouldHandleReceiptForMessage:message])
                    {
                        if (model.shouldShowReadLabel) {
                            break;  //当前没有变化
                        }else{
                            dict[@(i)] = model;
                            model.shouldShowReadLabel = YES;
                            findLastReceipt = YES;
                        }
                    }
                }
                else {
                    if (model.shouldShowReadLabel) {
                        dict[@(i)] = model;
                        model.shouldShowReadLabel = NO;
                        break;  //理论上只有一个已读标记在UI上,所以找到就可以跳出循环
                    }
                }
            }
        }
    }
    return dict;
}


- (void)sendMessageReceipt:(NSArray *)messages
{
    //只有在当前 Application 是激活的状态下才发送已读回执
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
    {
        //找到最后一个需要发送已读回执的消息标记为已读
        for (NSInteger i = [messages count] - 1; i >= 0; i--) {
            id item = [messages objectAtIndex:i];
            NIMMessage *message = nil;
            if ([item isKindOfClass:[NIMMessage class]])
            {
                message = item;
            }
            else if ([item isKindOfClass:[NIMMessageModel class]])
            {
                message = [(NIMMessageModel *)item message];
            }
            if (message)
            {
                if (!message.isOutgoingMsg &&
                    self.sessionConfig &&
                    [self.sessionConfig respondsToSelector:@selector(shouldHandleReceiptForMessage:)] &&
                    [self.sessionConfig shouldHandleReceiptForMessage:message])
                {
                    
                    NIMMessageReceipt *receipt = [[NIMMessageReceipt alloc] initWithMessage:message];
                    
                    [[[NIMSDK sharedSDK] chatManager] sendMessageReceipt:receipt
                                                              completion:nil];  //忽略错误,如果失败下次再发即可
                    return;
                }
            }
        }
    }
}


@end


@implementation NIMSessionMessageOperateResult

@end
