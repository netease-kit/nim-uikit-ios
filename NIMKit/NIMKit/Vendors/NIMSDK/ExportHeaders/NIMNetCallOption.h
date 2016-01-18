//
//  NIMNetCallOption.h
//  NIMLib
//
//  Created by fenric on 16/1/4.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMGlobalDefs.h"

/**
 *  网络通话选项
 */
@interface NIMNetCallOption : NSObject

/**
 *  附带消息, 仅在发起网络通话时有效, 用于推送显示等
 */
@property (nonatomic, copy) NSString *message;

/**
 *  扩展消息, 仅在发起网络通话时有效, 用于开发者自己沟通额外信息, 被叫收到呼叫时会携带该信息
 */
@property (nonatomic, copy) NSString *extendMessage;

/**
 *  期望的发送视频质量. SDK可能会根据具体机型运算性能和协商结果调整为更合适的清晰度, 导致该设置无效(该情况通常发生在通话一方有低性能机器时)
 */
@property (nonatomic, assign) NIMNetCallVideoQuality preferredVideoQuality;

/**
 *  禁用视频裁剪. 不禁用时, SDK可能会根据对端机型屏幕宽高比将本端画面裁剪后再发送, 以节省运算量和网络带宽
 */
@property (nonatomic, assign) BOOL disableVideoCropping;

@end
