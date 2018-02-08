//
//  NIMSessionMsgDatasource.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMKitMessageProvider.h"
#import "NIMSessionConfig.h"

@class NIMMessageModel;

@interface NIMSessionMsgDatasource : NSObject

- (instancetype)initWithSession:(NIMSession*)session
                         config:(id<NIMSessionConfig>)sessionConfig;


@property (nonatomic, strong) NSMutableArray      *items;
@property (nonatomic, readonly) NSInteger         messageLimit;                //每页消息显示条数
@property (nonatomic, readonly) NSInteger         showTimeInterval;            //两条消息相隔多久显示一条时间戳
@property (nonatomic, weak) id<NIMSessionConfig> sessionConfig;


- (NSInteger)indexAtModelArray:(NIMMessageModel*)model;

//复位消息
- (void)resetMessages:(void(^)(NSError *error)) handler;

//数据对外接口
- (void)loadHistoryMessagesWithComplete:(void(^)(NSInteger index , NSArray *messages ,NSError *error))handler;

//数据load接口
- (void)loadPullUpMessagesWithComplete:(void(^)(NSInteger index, NSArray *messages, NSError *error))handler;

//添加消息，会根据时间戳插入到相应位置
- (NSArray<NSNumber *> *)insertMessageModels:(NSArray*)models;

//添加消息，直接插入消息列表末尾
- (NSArray<NSNumber *> *)appendMessageModels:(NSArray *)models;

//删除消息
- (NSArray<NSNumber *> *)deleteMessageModel:(NIMMessageModel*)model;

//根据范围批量删除消息
- (NSArray<NSNumber *> *)deleteModels:(NSRange)range;

//清理缓存数据
- (void)cleanCache;
@end
