//
//  NIMNetCallOption.h
//  NIMLib
//
//  Created by Netease.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMGlobalDefs.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  网络通话选项
 */
@interface NIMNetCallOption : NSObject

/**
 *  期望的发送视频质量
 *  @discussion SDK可能会根据具体机型运算性能和协商结果调整为更合适的清晰度，导致该设置无效（该情况通常发生在通话一方有低性能机器时）
 */
@property (nonatomic,assign)    NIMNetCallVideoQuality   preferredVideoQuality;

/**
 *  禁用视频裁剪
 *  @discussion 不禁用时，SDK可能会根据对端机型屏幕宽高比将本端画面裁剪后再发送，以节省运算量和网络带宽
 */
@property (nonatomic,assign)    BOOL          disableVideoCropping;


/**
 *  自动旋转远端画面, 默认为 YES
 *  @discussion 开启该选项, 以在远端设备旋转时在本端自动调整角度
 */
@property (nonatomic, assign)   BOOL          autoRotateRemoteVideo;

/**
 *  服务器录制音频开关 (该开关仅在服务器开启录制功能时才有效)
 */
@property (nonatomic, assign)   BOOL           serverRecordAudio;

/**
 *  服务器录制视频开关 (该开关仅在服务器开启录制功能时才有效)
 */
@property (nonatomic, assign)   BOOL           serverRecordVideo;

/**
 *  扩展消息
 *  @discussion 仅在发起网络通话时有效，用于在主被叫之间传递额外信息，被叫收到呼叫时会携带该信息
 */
@property (nullable,nonatomic,copy)      NSString      *extendMessage;

/**
 *  网络通话请求是否附带推送
 *  @discussion 默认为YES。将这个字段设为NO，网络通话请求将不再有苹果推送通知。
 */
@property (nonatomic,assign)    BOOL          apnsInuse;

/**
 *  推送是否需要角标计数
 *  @discussion 默认为YES。将这个字段设为NO，网络通话请求将不再对角标计数。
 */
@property (nonatomic,assign)    BOOL          apnsBadge;

/**
 *  推送是否需要带前缀(一般为昵称)
 *  @discussion 默认为YES。将这个字段设为NO，推送消息将不带有前缀(xx:)。
 */
@property (nonatomic,assign)    BOOL          apnsWithPrefix;

/**
 *  apns推送文案
 *  @discussion 默认为nil，用户可以设置当前通知的推送文案
 */
@property (nullable,nonatomic,copy)      NSString      *apnsContent;

/**
 *  apns推送声音文件
 *  @discussion 默认为nil，用户可以设置当前通知的推送声音。该设置会覆盖apnsPayload中的sound设置
 */
@property (nullable,nonatomic,copy)      NSString      *apnsSound;

/**
 *  apns推送Payload
 *  @discussion 可以通过这个字段定义自定义通知的推送Payload,支持字段参考苹果技术文档,最多支持2K
 */
@property (nullable,nonatomic,copy)      NSDictionary   *apnsPayload;

@end

NS_ASSUME_NONNULL_END