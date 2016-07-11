//
//  NIMNetCallMeeting.h
//  NIMLib
//
//  Created by fenric on 16/4/19.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMGlobalDefs.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  多人音视频会议
 */
@interface NIMNetCallMeeting : NSObject

/**
 *  会议名称
 *
 *  @discussion 相同的会议名称, 只在会议使用完以后才可以重复使用, 开发者需要保证不会出现重复预订某会议名称而不使用的情况
 */
@property (nonatomic,copy)    NSString          *name;


/**
 *  会议对应的当前通话 call id
 */
@property (nonatomic, readonly) UInt64          callID;

/**
 *  扩展信息
 *  @discussion 用于在会议的创建和加入之间传递额外信息, 仅在创建会议时设置有效
 */
@property (nullable,nonatomic,copy)      NSString        *ext;

/**
 *  加入会议的音视频类型
 */
@property (nonatomic,assign)    NIMNetCallType   type;


/**
 *  以发言者的角色加入, 非发言者 (观众)不发送音视频数据
 */
@property (nonatomic, assign)   BOOL             actor;

/**
 *  期望的发送视频质量
 *
 *  @discussion SDK 可能会根据具体机型运算性能和协商结果调整为更合适的清晰度, 导致该设置无效
 */
@property (nonatomic,assign)    NIMNetCallVideoQuality   preferredVideoQuality;

/**
 *  禁用视频裁剪
 *  @discussion 不禁用时, SDK 可能会根据对端机型屏幕宽高比将本端画面裁剪后再发送, 以节省运算量和网络带宽
 */
@property (nonatomic,assign)    BOOL                     disableVideoCropping;

/**
 *  启用服务器录制音频 (该开关仅在服务器开启录制作功能时才有效), 预留字段, 暂不支持
 */
@property (nonatomic, assign)   BOOL                     serverRecordAudio;

/**
 *  启用服务器录制视频 (该开关仅在服务器开启录制作功能时才有效), 预留字段, 暂不支持
 */
@property (nonatomic, assign)   BOOL                     serverRecordVideo;

/**
 *  自动旋转远端画面, 默认为 YES
 *  @discussion 开启该选项, 以在远端设备旋转时在本端自动调整角度
 */
@property (nonatomic, assign)   BOOL                     autoRotateRemoteVideo;

@end

NS_ASSUME_NONNULL_END