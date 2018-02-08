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
#import "NIMGlobalMacro.h"
#import "NIMKit.h"

@interface NIMSessionMsgDatasource()

@property (nonatomic,strong) id<NIMKitMessageProvider> dataProvider;

@property (nonatomic,strong) NSMutableDictionary *msgIdDict;

@end

@implementation NIMSessionMsgDatasource
{
    NIMSession *_currentSession;
    dispatch_queue_t _messageQueue;
}

- (instancetype)initWithSession:(NIMSession*)session
                         config:(id<NIMSessionConfig>)sessionConfig
{
    if (self = [self init]) {
        _currentSession    = session;
        _sessionConfig     = sessionConfig;
        id<NIMKitMessageProvider> dataProvider = [_sessionConfig respondsToSelector:@selector(messageDataProvider)] ? [_sessionConfig messageDataProvider] : nil;
        
        NSInteger limit = [NIMKit sharedKit].config.messageLimit;
        NSTimeInterval showTimestampInterval = [NIMKit sharedKit].config.messageInterval;
        
        _dataProvider      = dataProvider;
        _messageLimit      = limit;
        _showTimeInterval  = showTimestampInterval;
        _items             = [NSMutableArray array];
        _msgIdDict         = [NSMutableDictionary dictionary];
    }
    return self;
}


- (void)resetMessages:(void(^)(NSError *error)) handler
{
    self.items              = [NSMutableArray array];
    self.msgIdDict         = [NSMutableDictionary dictionary];
    if ([self.dataProvider respondsToSelector:@selector(pullDown:handler:)])
    {
        __weak typeof(self) wself = self;
        [self.dataProvider pullDown:nil handler:^(NSError *error, NSArray<NIMMessage *> *messages) {
            NIMKit_Dispatch_Async_Main(^{
                [wself appendMessageModels:[self modelsWithMessages:messages]];
                if (handler) {
                    handler(error);
                }
            });
        }];
    }
    else
    {
        NSArray<NIMMessage *> *messages = [[[NIMSDK sharedSDK] conversationManager] messagesInSession:_currentSession
                                                                                   message:nil
                                                                                     limit:_messageLimit];
        [self appendMessageModels:[self modelsWithMessages:messages]];
        if (handler) {
            handler(nil);
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
    NSInteger count = self.items.count;
    for (NIMMessage *message in messages.reverseObjectEnumerator.allObjects) {
        [self insertMessage:message];
    }
    NSInteger currentIndex = self.items.count - 1;
    return currentIndex - count;
}

/**
 *  从后插入消息
 *
 *  @param models 消息集合
 *
 *  @return 插入的消息的index
 */
- (NSArray *)appendMessageModels:(NSArray *)models{
    if (!models.count) {
        return @[];
    }
    NSMutableArray *append = [[NSMutableArray alloc] init];
    for (NIMMessageModel *model in models) {
        if ([self modelIsExist:model]) {
            continue;
        }
        NSArray *result = [self insertMessageModel:model index:self.items.count];
        [append addObjectsFromArray:result];
    }
    return append;
}


/**
 *  从中间插入消息
 *
 *  @param models 消息集合
 *
 *  @return 插入消息的index
 */
- (NSArray *)insertMessageModels:(NSArray *)models{
    if (!models.count) {
        return @[];
    }
    NSMutableArray *insert = [[NSMutableArray alloc] init];
    //由于找到插入位置后会直接插入，所以这里按时间戳大小先排个序，避免造成先插了时间大的，再插了时间小的，导致之前时间大的消息的位置还需要后移的情况.
    NSArray *sortModels = [models sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NIMMessageModel *first  = obj1;
        NIMMessageModel *second = obj2;
        return first.messageTime < second.messageTime ? NSOrderedAscending : NSOrderedDescending;
    }];
    for (NIMMessageModel *model in sortModels) {
        if ([self modelIsExist:model]) {
            continue;
        }
        NSInteger i = [self findInsertPosistion:model];
        NSArray *result = [self insertMessageModel:model index:i];
        [insert addObjectsFromArray:result];
    }
    return insert;
}


- (NSInteger)indexAtModelArray:(NIMMessageModel *)model
{
    __block NSInteger index = -1;
    if (![_msgIdDict objectForKey:model.message.messageId]) {
        return index;
    }
    [self.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
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

- (BOOL)modelIsExist:(NIMMessageModel *)model
{
    return [_msgIdDict objectForKey:model.message.messageId] != nil;
}


- (void)loadHistoryMessagesWithComplete:(void(^)(NSInteger index, NSArray *messages , NSError *error))handler
{
    __block NIMMessageModel *currentOldestMsg = nil;
    [self.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NIMMessageModel class]]) {
            currentOldestMsg = (NIMMessageModel*)obj;
            *stop = YES;
        }
    }];
    NSInteger index = 0;
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

- (void)loadPullUpMessagesWithComplete:(void (^)(NSInteger, NSArray *, NSError *))handler {
    __block NIMMessageModel *currentNewestMsg = self.items.lastObject;
    __block NSInteger index = 0;
    NIMMessageSearchOption *option = [NIMMessageSearchOption new];
    option.startTime = currentNewestMsg.messageTime - 0.1;
    option.limit = [NIMKit sharedKit].config.messageLimit;
    option.allMessageTypes = YES;
    option.order = NIMMessageSearchOrderAsc;
    __weak typeof(self) wself = self;
    [[NIMSDK sharedSDK].conversationManager searchMessages:_currentSession
                                                    option:option
                                                    result:^(NSError * _Nullable error, NSArray<NIMMessage *> * _Nullable messages) {
                                                        index = [wself appendMessageModels:[self modelsWithMessages:messages]].count;
                                                        if (handler) {
                                                            NIMKit_Dispatch_Async_Main(^{
                                                                handler(index,messages,nil);
                                                            });
                                                        }
                                                    }];
}

- (NSArray*)deleteMessageModel:(NIMMessageModel *)msgModel
{
    NSMutableArray *dels = [NSMutableArray array];
    NSInteger delTimeIndex = -1;
    NSInteger delMsgIndex = [self.items indexOfObject:msgModel];
    if (delMsgIndex > 0) {
        BOOL delMsgIsSingle = (delMsgIndex == self.items.count-1 || [self.items[delMsgIndex+1] isKindOfClass:[NIMTimestampModel class]]);
        if ([self.items[delMsgIndex-1] isKindOfClass:[NIMTimestampModel class]] && delMsgIsSingle) {
            delTimeIndex = delMsgIndex-1;
            [self.items removeObjectAtIndex:delTimeIndex];
            [dels addObject:@(delTimeIndex)];
        }
    }
    if (delMsgIndex > -1) {
        [self.items removeObject:msgModel];
        [_msgIdDict removeObjectForKey:msgModel.message.messageId];
        [dels addObject:@(delMsgIndex)];
    }
    return dels;
}

- (NSArray<NSIndexPath *> *)deleteModels:(NSRange)range
{
    NSArray *models = [self.items subarrayWithRange:range];
    NSMutableArray *dels = [NSMutableArray array];
    NSMutableArray *all = [NSMutableArray arrayWithArray:self.items];
    for (NIMMessageModel *model in models) {
        if ([model isKindOfClass:[NIMTimestampModel class]]) {
            continue;
        }
        NSInteger delTimeIndex = -1;
        NSInteger delMsgIndex = [all indexOfObject:model];
        if (delMsgIndex > 0) {
            BOOL delMsgIsSingle = (delMsgIndex == all.count-1 || [all[delMsgIndex+1] isKindOfClass:[NIMTimestampModel class]]);
            if ([all[delMsgIndex-1] isKindOfClass:[NIMTimestampModel class]] && delMsgIsSingle) {
                delTimeIndex = delMsgIndex-1;
                [self.items removeObjectAtIndex:delTimeIndex];
                NSIndexPath *indexpath = [NSIndexPath indexPathForRow:delTimeIndex inSection:0];
                [dels addObject:indexpath];
            }
        }
        if (delMsgIndex > -1) {
            [self.items removeObject:model];
            [_msgIdDict removeObjectForKey:model.message.messageId];
            NSIndexPath *indexpath = [NSIndexPath indexPathForRow:delMsgIndex inSection:0];
            [dels addObject:indexpath];
        }
    }
    return dels;
}

- (void)cleanCache
{
    for (id item in self.items)
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
    NSTimeInterval firstTimeInterval = [self firstTimeInterval];
    if (firstTimeInterval && firstTimeInterval - model.messageTime < self.showTimeInterval) {
        //此时至少有一条消息和时间戳（如果有的话）
        //干掉时间戳（如果有的话）
        if ([self.items.firstObject isKindOfClass:[NIMTimestampModel class]]) {
            [self.items removeObjectAtIndex:0];
        }
    }
    [self.items insertObject:model atIndex:0];
    if (![self.dataProvider respondsToSelector:@selector(needTimetag)] || self.dataProvider.needTimetag) {
        //这种情况下必须要插入时间戳
        NIMTimestampModel *timeModel = [[NIMTimestampModel alloc] init];
        timeModel.messageTime = model.messageTime;
        [self.items insertObject:timeModel atIndex:0];
    }
    [self.msgIdDict setObject:model forKey:model.message.messageId];
}


- (NSArray *)insertMessageModel:(NIMMessageModel *)model index:(NSInteger)index{
    NSMutableArray *inserts = [[NSMutableArray alloc] init];
    if (![self.dataProvider respondsToSelector:@selector(needTimetag)] || self.dataProvider.needTimetag)
    {
        if ([self shouldInsertTimestamp:model]) {
            NIMTimestampModel *timeModel = [[NIMTimestampModel alloc] init];
            timeModel.messageTime = model.messageTime;
            [self.items insertObject:timeModel atIndex:index];
            [inserts addObject:@(index)];
            index++;
        }
    }
    [self.items insertObject:model atIndex:index];
    [self.msgIdDict setObject:model forKey:model.message.messageId];
    [inserts addObject:@(index)];
    return inserts;
}

- (void)subHeadMessages:(NSInteger)count
{
    NSInteger catch = 0;
    NSArray *modelArray = [NSArray arrayWithArray:self.items];
    for (NIMMessageModel *model in modelArray) {
        if ([model isKindOfClass:[NIMMessageModel class]]) {
            catch++;
            [self deleteMessageModel:model];
        }
        if (catch == count) {
            break;
        }
    }
}

- (NSArray<NIMMessageModel *> *)modelsWithMessages:(NSArray<NIMMessage *> *)messages
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (NIMMessage *message in messages) {
        NIMMessageModel *model = [[NIMMessageModel alloc] initWithMessage:message];
        [array addObject:model];
    }
    return array;
}


- (NSInteger)findInsertPosistion:(NIMMessageModel *)model
{
    return [self findInsertPosistion:self.items model:model];
}

- (NSInteger)findInsertPosistion:(NSArray *)array model:(NIMMessageModel *)model
{
    if (array.count == 0) {
        //即初始什么消息都没的情况下，调用了插入消息，放在第一个就好了。
        return 0;
    }
    if (array.count == 1) {
        //递归出口
        NIMMessageModel *obj = array.firstObject;
        NSInteger index = [self.items indexOfObject:obj];
        return obj.messageTime > model.messageTime? index : index+1;
    }
    NSInteger sep = (array.count+1) / 2;
    NIMMessageModel *center = array[sep];
    NSTimeInterval timestamp = [center messageTime];
    NSArray *half;
    if (timestamp <= [model messageTime]) {
        half = [array subarrayWithRange:NSMakeRange(sep, array.count - sep)];
    }else{
        half = [array subarrayWithRange:NSMakeRange(0, sep)];
    }
    return [self findInsertPosistion:half model:model];
}


- (BOOL)shouldInsertTimestamp:(NIMMessageModel *)model
{
    NSTimeInterval lastTimeInterval = [self lastTimeInterval];
    return model.messageTime - lastTimeInterval > self.showTimeInterval;
}

- (NSTimeInterval)firstTimeInterval
{
    if (!self.items.count) {
        return 0;
    }
    NIMMessageModel *model;
    if (![self.dataProvider respondsToSelector:@selector(needTimetag)] || self.dataProvider.needTimetag) {
        model = self.items[1];
    }else
    {
        model = self.items[0];
    }
    return model.messageTime;
}

- (NSTimeInterval)lastTimeInterval
{
    NIMMessageModel *model = self.items.lastObject;
    return model.messageTime;
}

@end
