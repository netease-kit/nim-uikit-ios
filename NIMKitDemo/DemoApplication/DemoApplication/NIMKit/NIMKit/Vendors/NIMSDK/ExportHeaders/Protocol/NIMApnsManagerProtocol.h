//
//  NIMApnsManager.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NIMPushNotificationSetting;

/**
 *  更新推送回调
 *
 *  @param error 错误信息，成功则error为nil
 */
typedef void(^NIMApnsHandler)(NSError *error);

/**
 *  推送协议
 */
@protocol NIMApnsManager <NSObject>
/**
 *  获取当前的推送设置
 *
 *  @return 推送设置
 */
- (NIMPushNotificationSetting *)currentSetting;

/**
 *  更新推送设置
 *
 *  @param setting    推送设置
 *  @param completion 完成的回调
 */
- (void)updateApnsSetting:(NIMPushNotificationSetting *)setting
               completion:(NIMApnsHandler)completion;
@end
