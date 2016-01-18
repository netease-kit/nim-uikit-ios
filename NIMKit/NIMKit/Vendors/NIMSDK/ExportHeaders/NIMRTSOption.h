//
//  NIMRTSOption.h
//  NIMLib
//
//  Created by Netease on 15/7/20.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  实时会话的附带选项, 用于发起和响应
 */
@interface NIMRTSOption : NSObject

/**
 *  附带消息, 仅在发起会话时有效, 用于推送显示等
 */
@property (nonatomic, copy) NSString *message;

/**
 *  扩展消息, 仅在发起会话时有效, 用于开发者自己沟通额外信息
 */
@property (nonatomic, copy) NSString *extendMessage;

/**
 *  禁用服务器录制
 */
@property (nonatomic, assign) BOOL disableRecord;


@end
