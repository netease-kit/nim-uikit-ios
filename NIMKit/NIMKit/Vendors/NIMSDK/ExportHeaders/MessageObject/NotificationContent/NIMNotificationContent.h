//
//  NIMNotificationContent.h
//  NIMLib
//
//  Created by amao on 7/22/15.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  通知类型
 */
typedef NS_ENUM(NSInteger, NIMNotificationType){
    /**
     *  群通知
     */
    NIMNotificationTypeTeam            = 1,
    /**
     *  网络电话通知
     */
    NIMNotificationTypeNetCall         = 2,
};



/**
 *  系统通知内容基类
 */
@interface NIMNotificationContent : NSObject
/**
 *  通知内容类型
 *
 *  @return 通知内容类型
 */
- (NIMNotificationType)notificationType;
@end

