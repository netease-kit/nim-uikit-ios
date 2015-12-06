//
//  NIMMessageSearchOption.h
//  NIMLib
//
//  Created by amao on 6/30/15.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMGlobalDefs.h"

@class NIMMessage;


/*
 * 搜索顺序
 */
typedef enum : NSUInteger {
    /*
     * 从新消息往旧消息查询
     */
    NIMMessageSearchOrderDesc       =   0,
    /*
     * 从旧消息往新消息查询
     */
    NIMMessageSearchOrderAsc        =   1,
    
} NIMMessageSearchOrder;


/**
 *  本地搜索选项
 *  @discussion 搜索条件: 时间在(startTime,endTime)内(不包含)，类型为messageType，且 匹配searchContent或fromIds 的一定数量(limit)消息
 */
@interface NIMMessageSearchOption : NSObject

/**
 *  起始时间,默认为0
 */
@property (nonatomic,assign)    NSTimeInterval startTime;


/**
 *  结束时间,默认为0
 *  @discussion 搜索的结束时间,0表示最大时间戳
 */
@property (nonatomic,assign)    NSTimeInterval endTime;

/**
 *  检索条数
 *  @discussion 默认100条,设置为0表示无条数限制
 */
@property (nonatomic,assign)    NSUInteger limit;

/**
 *  检索顺序
 */
@property (nonatomic,assign)    NIMMessageSearchOrder order;

/**
 *  查询的消息类型,默认为NIMMessageTypeText
 *  @discussion 只有在messageType为Text时searchContent才起效
 */
@property (nonatomic,assign)    NIMMessageType  messageType;

/**
 *  检索文本
 */
@property (nonatomic,copy)      NSString *searchContent;

/**
 *  消息发出者帐号列表
 */
@property (nonatomic,strong)    NSArray *fromIds;

@end


/**
 *  检索服务器历史消息选项
 */
@interface NIMHistoryMessageSearchOption : NSObject

/**
 *  检索消息起始时间
 *  @discussion 需要检索的起始时间,没有则传入0
 */
@property (nonatomic,assign)      NSTimeInterval  startTime;

/**
 *  检索消息终止时间
 *  @discussion 当前最早的时间,没有则传入0
 */
@property (nonatomic,assign)      NSTimeInterval  endTime;

/**
 *  检索消息的当前参考消息,返回的消息结果集里不会包含这条消息
 *  @discussion 传入最早时间,没有则传入nil
 */
@property (nonatomic,strong)      NIMMessage      *currentMessage;

/**
 *  检索条数
 *  @discussion 最大限制100条
 */
@property (nonatomic,assign)      NSUInteger       limit;

/**
 *  检索顺序
 */
@property (nonatomic,assign)      NIMMessageSearchOrder             order;

/**
 *  是否需要同步到DB
 */
@property (nonatomic,assign)      BOOL            sync;


@end