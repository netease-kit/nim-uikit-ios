//
//  NIMPushNotificationSetting.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  推送消息显示类型
 */
typedef NS_ENUM(NSInteger, NIMPushNotificationDisplayType){
    /**
     *  显示详情
     */
    NIMPushNotificationDisplayTypeDetail = 1,
    /**
     *  不显示详情
     */
    NIMPushNotificationDisplayTypeNoDetail = 2,
};


/**
 *  消息推送参数设置
 */
@interface NIMPushNotificationSetting : NSObject
/**
 *  推送消息显示类型
 */
@property (nonatomic,assign)    NIMPushNotificationDisplayType     type;

/**
 *  推送消息是否开启免打扰 YES表示开启免打扰
 */
@property (nonatomic,assign)    BOOL    noDisturbing;

/**
 *  免打扰开始时间:小时
 */
@property (nonatomic) NSUInteger noDisturbingStartH;

/**
 *  免打扰开始时间:分
 */
@property (nonatomic) NSUInteger noDisturbingStartM;

/**
 *  免打扰结束时间:小时
 */
@property (nonatomic) NSUInteger noDisturbingEndH;

/**
 *  免打扰结束时间:分
 */
@property (nonatomic) NSUInteger noDisturbingEndM;

@end
