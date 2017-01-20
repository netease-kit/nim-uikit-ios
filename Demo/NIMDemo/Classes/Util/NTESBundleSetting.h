//
//  NTESBundleSetting.h
//  NIM
//
//  Created by chris on 15/7/1.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMGlobalDefs.h"
#import "NIMAVChatDefs.h"

//部分API提供了额外的选项，如删除消息会有是否删除会话的选项,为了测试方便提供配置参数
//上层开发只需要按照策划需求选择一种适合自己项目的选项即可，这个设置只是为了方便测试不同的case下API的正确性

@interface NTESBundleSetting : NSObject

+ (instancetype)sharedConfig;

- (BOOL)removeSessionWheDeleteMessages;             //删除消息时是否同时删除会话项

- (BOOL)localSearchOrderByTimeDesc;                 //本地搜索消息顺序 YES表示按时间戳逆序搜索,NO表示按照时间戳顺序搜索

- (BOOL)autoRemoveRemoteSession;                    //删除会话时是不是也同时删除服务器会话 (防止漫游)

- (BOOL)autoRemoveSnapMessage;                      //阅后即焚消息在看完后是否删除

- (BOOL)needVerifyForFriend;                        //添加好友是否需要验证

- (BOOL)showFps;                                    //是否显示Fps

- (BOOL)disableProximityMonitor;                    //贴耳的时候是否需要自动切换成听筒模式

- (BOOL)enableRotate;                               //支持旋转(仅组件部分，其他部分可能会显示不正常，谨慎开启)

- (BOOL)usingAmr;                                   //使用amr作为录音

- (NSArray *)ignoreTeamNotificationTypes;           //需要忽略的群通知类型

#pragma mark - 网络通话和白板
- (BOOL)serverRecordAudio;                          //服务器录制语音

- (BOOL)serverRecordVideo;                          //服务器录制视频

- (BOOL)serverRecordWhiteboardData;                 //服务器录制白板数据


- (BOOL)videochatDisableAutoCropping;               //禁用自动裁剪画面

- (BOOL)videochatAutoRotateRemoteVideo;             //自动旋转视频聊天远端画面

- (NIMNetCallVideoQuality)preferredVideoQuality;    //期望的视频发送清晰度

- (BOOL)startWithBackCamera;                        //使用后置摄像头开始视频通话

- (NIMNetCallVideoCodec)perferredVideoEncoder;      //期望的视频编码器

- (NIMNetCallVideoCodec)perferredVideoDecoder;      //期望的视频解码器

- (NSUInteger)videoMaxEncodeKbps;                   //最大发送视频编码码率

- (NSUInteger)localRecordVideoKbps;                 //本地录制视频码率

- (BOOL)autoDeactivateAudioSession;                 //自动结束AudioSession

- (BOOL)audioDenoise;                               //降噪开关

- (BOOL)voiceDetect;                                //语音检测开关

- (BOOL)preferHDAudio;                              //期望高清语音

@end
