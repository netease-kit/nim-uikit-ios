//
//  NIMSessionMsgDatasource.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMSessionMsgDatasource.h"
#import "UITableView+NIMScrollToBottom.h"
#import "NIMMessageModel.h"
#import "NIMTimestampModel.h"

@interface NIMSessionMsgDatasource()

@property (nonatomic,strong) id<NIMKitMessageProvider> dataProvider;

@property (nonatomic,strong) NSMutableDictionary *msgIdDict;

//因为插入消息之后，消息到发送完毕后会改成服务器时间，所以不能简单和前一条消息对比时间戳去插时间
//这里记下来插消息时的本地时间，按这个去比
@property (nonatomic,assign) NSTimeInterval firstTimeInterval;

@property (nonatomic,assign) NSTimeInterval lastTimeInterval;

@end

@implementation NIMSessionMsgDatasource
{
    NIMSession *_currentSession;
    dispatch_queue_t _messageQueue;
}

- (instancetype)initWithSession:(NIMSession*)session
                   dataProvider:(id<NIMKitMessageProvider>)dataProvider
               showTimeInterval:(NSTimeInterval)timeInterval
                          limit:(NSInteger)limit
{
    if (self = [self init]) {
        _currentSession    = session;
        _dataProvider      = dataProvider;
        _messageLimit      = limit;
        _showTimeInterval  = timeInterval;
        _firstTimeInterval = 0;
        _lastTimeInterval  = 0;
        [[[NIMSDK sharedSDK] conversationManager] markAllMessagesReadInSession:_currentSession];
    }
    return self;
}


- (void)resetMessages:(void(^)(NSError *error)) handler
{
    self.modelArray        = [NSMutableArray array];
    self.msgIdDict         = [NSMutableDictionary dictionary];
    self.firstTimeInterval = 0;
    self.lastTimeInterval  = 0;
    if ([self.dataProvider respondsToSelector:@selector(pullDown:handler:)])
    {
        __weak typeof(self) wself = self;
        [self.dataProvider pullDown:nil handler:^(NSError *error, NSArray *messages) {
            NIMKit_Dispatch_Async_Main(^{
                [wself appendMessages:messages];
                wself.firstTimeInterval = [messages.firstObject timestamp];
                wself.lastTimeInterval  = [messages.lastObject timestamp];
                if ([self.delegate respondsToSelector:@selector(messageDataIsReady)]) {
                    [self.delegate messageDataIsReady];
                }
            });
        }];
    }
    else
    {
        NSArray *messages = [[[NIMSDK sharedSDK] conversationManager] messagesInSession:_currentSession
                                                                                   message:nil
                                                                                     limit:_messageLimit];
        [self appendMessages:messages];
        self.firstTimeInterval = [messages.firstObject timestamp];
        self.lastTimeInterval  = [messages.lastObject timestamp];
        if ([self.delegate respondsToSelector:@selector(messageDataIsReady)]) {
            [self.delegate messageDataIsReady];
        }
    }
}


/**
 *  从头插入消息
 *
 *  @param messages 消息
 *
 *  @return 插入后table要滑动到的位置
 */
- (NSInteger)insertMessages:(NSArray *)messages{
    NSInteger count = self.modelArray.count;
    for (NIMMessage *message in messages.reverseObjectEnumerator.allObjects) {
        [self insertMessage:message];
    }
    return self.modelArray.count - count;
}


/**
 *  从后插入消息
 *
 *  @param messages 消息集合
 *
 *  @return 插入的消息的index
 */
- (NSArray *)appendMessages:(NSArray *)messages{
    if (!messages.count) {
        return @[];
    }
    NSInteger count = self.modelArray.count;
    for (NIMMessage *message in messages) {
        [self appendMessage:message];
    }
    NSMutableArray *append = [[NSMutableArray alloc] init];
    for (NSInteger i = count; i < self.modelArray.count; i++) {
        [append addObject:@(i)];
    }
    return append;
}


- (NSInteger)indexAtModelArray:(NIMMessageModel *)model
{
    __block NSInteger index = -1;
    if (![_msgIdDict objectForKey:model.message.messageId]) {
        return index;
    }
    [_modelArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NIMMessageModel class]]) {
            if ([model isEqual:obj]) {
                index = idx;
                *stop = YES;
            }
        }
    }];
    return index;
}

#pragma mark - msg
- (NSInteger)msgCount
{
    return [_modelArray count];
}

- (NSArray*)addMessages:(NSArray*)messages
{
    return [self appendMessages:messages];
}

- (BOOL)modelIsExist:(NIMMessageModel *)model
{
    return [_msgIdDict objectForKey:model.message.messageId] != nil;
}


- (void)loadHistoryMessagesWithComplete:(void(^)(NSInteger index, NSArray *messages , NSError *error))handler
{
    __block NIMMessageModel *currentOldestMsg = nil;
    [_modelArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NIMMessageModel class]]) {
            currentOldestMsg = (NIMMessageModel*)obj;
            *stop = YES;
        }
    }];
    NSInteger index = 0;
    if (currentOldestMsg) {
        if ([self.dataProvider respondsToSelector:@selector(pullDown:handler:)])
        {
            __weak typeof(self) wself = self;
            [self.dataProvider pullDown:currentOldestMsg.message handler:^(NSError *error, NSArray *messages) {
                NIMKit_Dispatch_Async_Main(^{
                    NSInteger index = [wself insertMessages:messages];
                    if (handler) {
                        handler(index,messages,error);
                    }
                });
            }];
            return;
        }
        else
        {
            NSArray *messages = [[[NIMSDK sharedSDK] conversationManager] messagesInSession:_currentSession
                                                                                    message:currentOldestMsg.message
                                                                                      limit:self.messageLimit];
            index = [self insertMessages:messages];
            if (handler) {
                NIMKit_Dispatch_Async_Main(^{
                    handler(index,messages,nil);
                });
            }
        }
    }
    if (handler) {
        NIMKit_Dispatch_Async_Main(^{
            handler(index,nil,nil);
        });
    }
}

- (NSArray*)deleteMessageModel:(NIMMessageModel *)msgModel
{
    NSMutableArray *dels = [NSMutableArray array];
    NSInteger delTimeIndex = -1;
    NSInteger delMsgIndex = [_modelArray indexOfObject:msgModel];
    if (delMsgIndex > 0) {
        BOOL delMsgIsSingle = (delMsgIndex == _modelArray.count-1 || [_modelArray[delMsgIndex+1] isKindOfClass:[NIMTimestampModel class]]);
        if ([_modelArray[delMsgIndex-1] isKindOfClass:[NIMTimestampModel class]] && delMsgIsSingle) {
            delTimeIndex = delMsgIndex-1;
            [_modelArray removeObjectAtIndex:delTimeIndex];
            [dels addObject:@(delTimeIndex)];
        }
    }
    if (delMsgIndex > -1) {
        [_modelArray removeObject:msgModel];
        [_msgIdDict removeObjectForKey:msgModel.message.messageId];
        [dels addObject:@(delMsgIndex)];
    }
    return dels;
}

- (void)cleanCache
{
    for (id item in _modelArray)
    {
        if ([item isKindOfClass:[NIMMessageModel class]])
        {
            NIMMessageModel *model = (NIMMessageModel *)item;
            [model cleanCache];
        }
    }
}

#pragma mark - private methods
- (void)insertMessage:(NIMMessage *)message{
    NIMMessageModel *model = [[NIMMessageModel alloc] initWithMessage:message];
    if ([self modelIsExist:model]) {
        return;
    }
    if (self.firstTimeInterval && self.firstTimeInterval - model.message.timestamp < self.showTimeInterval) {
        //此时至少有一条时间戳和一条消息
        //干掉时间戳
        [self.modelArray removeObjectAtIndex:0];
    }
    [self.modelArray insertObject:model atIndex:0];
    NIMTimestampModel *timeModel = [[NIMTimestampModel alloc] init];
    timeModel.messageTime = model.message.timestamp;
    [self.modelArray insertObject:timeModel atIndex:0];
    self.firstTimeInterval = model.message.timestamp;
    [self.msgIdDict setObject:model forKey:model.message.messageId];
}


- (void)appendMessage:(NIMMessage *)message{
    NIMMessageModel *model = [[NIMMessageModel alloc] initWithMessage:message];
    if ([self modelIsExist:model]) {
        return;
    }
    if (model.message.timestamp - self.lastTimeInterval > self.showTimeInterval) {
        NIMTimestampModel *timeModel = [[NIMTimestampModel alloc] init];
        timeModel.messageTime = model.message.timestamp;
        [self.modelArray addObject:timeModel];
    }
    [self.modelArray addObject:model];
    self.lastTimeInterval = model.message.timestamp;
    [self.msgIdDict setObject:model forKey:model.message.messageId];
}


@end
