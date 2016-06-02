//
//  NIMNetCallManagerProtocol.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMGlobalDefs.h"

NS_ASSUME_NONNULL_BEGIN

@class NIMNetCallOption;
@class NIMNetCallMeeting;
@class NIMNetCallRecordingInfo;

/**
 *  发起通话Block
 *
 *  @param error 发起通话结果, 如果成功error为nil
 *  @param callID 发起通话的call id, 如果发起失败则为0
 */
typedef void(^NIMNetCallStartHandler)(NSError * __nullable error, UInt64 callID);

/**
 *  响应通话请求Block
 *
 *  @param error  响应通话请求结果, 如果成功error为nil
 *  @param callID 响应通话的call id
 */
typedef void(^NIMNetCallResponseHandler)(NSError * __nullable error, UInt64 callID);


/**
 *  预订或者加入多人会议请求Handler
 *
 *  @param meeting 预订或者加入的多人会议
 *  @param error   预订或者加入多人会议请求结果, 如果成功 error 为 nil
 */
typedef void(^NIMNetCallMeetingHandler)(NIMNetCallMeeting *meeting, NSError *error);

/**
 *  网络通话状态
 */
typedef NS_ENUM(NSInteger, NIMNetCallStatus){
    /**
     *  已连接
     */
    NIMNetCallStatusConnect,
    /**
     *  已断开
     */
    NIMNetCallStatusDisconnect,
};

/**
 *  网络通话的网络状态
 */
typedef NS_ENUM(NSInteger, NIMNetCallNetStatus){
    /**
     *  网络非常好
     */
    NIMNetCallNetStatusVeryGood = 0,
    /**
     *  网络好
     */
    NIMNetCallNetStatusGood     = 1,
    /**
     *  网络差
     */
    NIMNetCallNetStatusBad      = 2,
    /**
     *  网络非常差
     */
    NIMNetCallNetStatusVeryBad  = 3,
};

/**
 *  网络通话控制类型
 */
typedef NS_ENUM(NSInteger, NIMNetCallControlType){
    /**
     *  开启了音频
     */
    NIMNetCallControlTypeOpenAudio      = 1,
    /**
     *  关闭了音频
     */
    NIMNetCallControlTypeCloseAudio     = 2,
    /**
     *  开启了视频
     */
    NIMNetCallControlTypeOpenVideo      = 3,
    /**
     *  关闭了视频
     */
    NIMNetCallControlTypeCloseVideo     = 4,
    /**
     *  切换到视频模式
     */
    NIMNetCallControlTypeToVideo        = 5,
    /**
     *  同意切换到视频模式，用于切到视频模式需要对方同意的场景
     */
    NIMNetCallControlTypeAgreeToVideo   = 6,
    /**
     *  拒绝切换到视频模式，用于切到视频模式需要对方同意的场景
     */
    NIMNetCallControlTypeRejectToVideo  = 7,
    /**
     *  切换到音频模式
     */
    NIMNetCallControlTypeToAudio        = 8,
    /**
     *  占线
     */
    NIMNetCallControlTypeBusyLine       = 9,
    /**
     *  没有可用摄像头
     */
    NIMNetCallControlTypeNoCamera       = 10,
    /**
     *  应用切换到了后台
     */
    NIMNetCallControlTypeBackground     = 11,
    /**
     *  收到呼叫请求的反馈，通常用于被叫告诉主叫可以播放回铃音了
     */
    NIMNetCallControlTypeFeedabck       = 12,
    
    /**
     *  开始本地录制
     */
    NIMNetCallControlTypeStartLocalRecord = 13,
    
    /**
     *  结束本地录制
     */
    NIMNetCallControlTypeStopLocalRecord = 14,

};

/**
 *  视频通话使用的摄像头
 */
typedef NS_ENUM(NSInteger, NIMNetCallCamera){
    /**
     *  前置摄像头
     */
    NIMNetCallCameraFront,
    /**
     *  后置摄像头
     */
    NIMNetCallCameraBack,
};

/**
 *  音视频聊天相关回调
 */
@protocol NIMNetCallManagerDelegate <NSObject>

@optional

/**
 *  被叫收到呼叫（振铃）
 *
 *  @param callID call id
 *  @param caller 主叫帐号
 *  @param type   呼叫类型
 *  @param extendMessage   扩展消息, 透传主叫发起通话时携带的该信息
 */
- (void)onReceive:(UInt64)callID
             from:(NSString *)caller
             type:(NIMNetCallType)type
          message:(nullable NSString *)extendMessage;

/**
 *  主叫收到被叫响应
 *
 *  @param callID   call id
 *  @param callee 被叫帐号
 *  @param accepted 是否接听
 */
- (void)onResponse:(UInt64)callID
              from:(NSString *)callee
          accepted:(BOOL)accepted;

/**
 *  对方挂断电话
 *
 *  @param callID call id
 *  @param user   对方帐号
 */
- (void)onHangup:(UInt64)callID
              by:(NSString *)user;

/**
 *  这通呼入通话已经被该帐号其他端处理
 *
 *  @param callID   呼入通话的call id
 *  @param accepted 是否被接听
 */
- (void)onResponsedByOther:(UInt64)callID
                  accepted:(BOOL)accepted;

/**
 *  收到对方网络通话控制信息，用于方便通话双方沟通信息
 *
 *  @param callID  相关网络通话的call id
 *  @param user    对方帐号
 *  @param control 控制类型
 */
- (void)onControl:(UInt64)callID
             from:(NSString *)user
             type:(NIMNetCallControlType)control;

/**
 *  当前通话状态
 *
 *  @param callID 相关网络通话的call id
 *  @param status 通话状态, 收到NIMNetCallStatusDisconnect时无需调用hangup:挂断该通话
 */
- (void)onCall:(UInt64)callID
        status:(NIMNetCallStatus)status;
/**
 *  当前通话网络状态
 *
 *  @param callID 相关网络通话的call id
 *  @param status 网络状态
 */
- (void)onCall:(UInt64)callID
     netStatus:(NIMNetCallNetStatus)status;

/**
 *  本地摄像头预览就绪
 *
 *  @param layer 本地摄像头预览层
 */
- (void)onLocalPreviewReady:(CALayer *)layer;

/**
 *  远程视频YUV数据就绪
 *
 *  @param yuvData  远程视频YUV数据, 紧凑型 (stride 等于 width)
 *  @param width    远程视频画面宽度
 *  @param height   远程视频画面长度
 *  @param user     远程视频画面属于的用户
 *
 *  @discussion 将YUV数据直接渲染在OpenGL上比UIImageView贴图占用更少的cpu
 */
- (void)onRemoteYUVReady:(NSData *)yuvData
                   width:(NSUInteger)width
                  height:(NSUInteger)height
                    from:(NSString *)user;

/**
 *  远程视频画面就绪
 *
 *  @param image 远程视频画面
 *
 *  @discussion 如果你已经使用onRemoteYUVReady:width:height:得到的YUV数据渲染画面, 不要实现该委托以优化性能
 */
- (void)onRemoteImageReady:(CGImageRef)image;

/**
 *  本地录制成功开始
 *
 *  @param callID  录制的相关网络通话的call id
 *  @param fileURL 录制的文件路径
 */
- (void)onLocalRecordStarted:(UInt64)callID
                     fileURL:(NSURL *)fileURL;

/**
 *  本地录制发生了错误
 *
 *  @param error  错误
 *  @param callID 录制错误相关网络通话的call id
 */
- (void)onLocalRecordError:(NSError *)error
                    callID:(UInt64)callID;

/**
 *  本地录制成功结束
 *
 *  @param callID  录制的相关网络通话的call id
 *  @param fileURL 录制的文件路径
 */
- (void) onLocalRecordStopped:(UInt64)callID
                      fileURL:(NSURL *)fileURL;

/**
 *  网络通话服务器录制信息
 *
 *  @param info 录制信息
 */
- (void)onNetCallRecordingInfo:(NIMNetCallRecordingInfo *)info;

/**
 *  用户加入了多人会议
 *
 *  @param uid     用户 id
 *  @param meeting 用户加入的会议
 */
- (void)onUserJoined:(NSString *)uid
             meeting:(NIMNetCallMeeting *)meeting;

/**
 *  用户离开了多人会议
 *
 *  @param uid    用户 id
 *  @param meeting 用户离开的会议
 */
- (void)onUserLeft:(NSString *)uid
           meeting:(NIMNetCallMeeting *)meeting;

@end

/**
 *  网络通话协议
 */
@protocol NIMNetCallManager <NSObject>

/**
 *  主叫发起通话 - 新接口
 *
 *  @param callees    被叫帐号列表, 现在只支持传入一个被叫
 *  @param type       呼叫类型
 *  @param option     开始通话附带的选项, 可以为空
 *  @param completion 发起通话结果回调
 */
- (void)start:(NSArray<NSString *> *)callees
         type:(NIMNetCallType)type
       option:(nullable NIMNetCallOption *)option
   completion:(nullable NIMNetCallStartHandler)completion;

/**
 *  被叫响应呼叫
 *
 *  @param callID      call id
 *  @param accept      是否接听
 *  @param option      开始通话附带的选项, 可以为空
 *  @param completion  响应呼叫结果回调
 *
 *  @discussion 被叫拒绝接听时, 主叫不需要再调用hangup:接口
 */
- (void)response:(UInt64)callID
          accept:(BOOL)accept
          option:(nullable NIMNetCallOption *)option
      completion:(nullable NIMNetCallResponseHandler)completion;

/**
 *  挂断通话
 *
 *  @param callID 需要挂断电话的call id, 如果尚未获取到call id就填0
 *
 *  @discussion 被叫在响应呼叫之前不要调用挂断接口
 */
- (void)hangup:(UInt64)callID;


/**
 *  预订多人会议
 *
 *  @param meeting    预订的多人会议
 *  @param completion 预订会议结果
 */
- (void)reserveMeeting:(NIMNetCallMeeting *)meeting
            completion:(nullable NIMNetCallMeetingHandler)completion;

/**
 *  加入多人会议
 *
 *  @param meeting    需要加入的多人会议
 *  @param completion 加入会议结果
 */
- (void)joinMeeting:(NIMNetCallMeeting *)meeting
         completion:(nullable NIMNetCallMeetingHandler)completion;

/**
 *  离开多人会议
 *
 *  @param meeting 需要离开的多人会议
 * 
 *  @discussion 当所有加入的人都离开了某会议, 该会议对应的名称才可以被重复预订
 *
 */
- (void)leaveMeeting:(NIMNetCallMeeting *)meeting;


/**
 *  改变自己在会议中的角色
 *
 *  @param actor 是否为发言者角色, 发言者发送音视频数据, 非发言者不发送音视频数据
 *
 *  @return 设置是否成功
 */
- (BOOL)setMeetingRole:(BOOL)actor;

/**
 *  指定某用户设置是否对其静音
 *
 *  @param mute 是否静音, 静音后将听不到该用户的声音
 *  @param uid  用户 uid
 *
 *  @return 是否设置成功. 如果用户尚未加入, 则无法设置
 */
- (BOOL)setAudioMute:(BOOL)mute forUser:(NSString *)uid;

/**
 *  指定某用户设置是否接收其视频
 *
 *  @param mute 是否拒绝视频, 拒绝后将没有该用户视频数据回调
 *  @param uid  用户uid
 *
 *  @return 是否设置成功. 如果用户尚未加入, 则无法设置
 */
- (BOOL)setVideoMute:(BOOL)mute forUser:(NSString *)uid;


/**
 *  发送网络通话的控制信息，用于方便通话双方沟通信息
 *
 *  @param callID 控制信息相关通话的call id
 *  @param type   控制类型
 */
- (void)control:(UInt64)callID
           type:(NIMNetCallControlType)type;

/**
 *  设置网络通话静音模式
 *
 *  @param mute 是否开启静音
 *
 *  @return 开启静音是否成功
 *
 *  @discussion 切换网络通话类型将丢失该设置
 */
- (BOOL)setMute:(BOOL)mute;

/**
 *  设置网络通话扬声器模式
 *
 *  @param useSpeaker 是否开启扬声器
 *
 *  @return 开启扬声器是否成功
 *
 *  @discussion 切换网络通话类型将丢失该设置
 */
- (BOOL)setSpeaker:(BOOL)useSpeaker;

/**
 *  切换网络通话摄像头
 *
 *  @param camera 选择的摄像头
 *
 *  @discussion 切换网络通话类型将丢失该设置
 */
- (void)switchCamera:(NIMNetCallCamera)camera;

/**
 *  设置摄像头关闭
 *
 *  @param disable 是否关闭
 *
 *  @return 设置是否成功
 *
 *  @discussion 仅支持当前为视频模式时进行此设置, 切换网络通话类型将丢失该设置
 */
- (BOOL)setCameraDisable:(BOOL)disable;

/**
 *  切换网络通话类型
 *
 *  @param type 通话类型
 *
 *  @discussion 切换通话类型会丢失这些设置: 静音模式, 扬声器模式, 摄像头关闭, 切换摄像头
 */
- (void)switchType:(NIMNetCallType)type;


/**
 *  获得当前视频通话的本地预览层
 *
 *  @return 预览层
 */
- (nullable CALayer *)localPreviewLayer;

/**
 *  获取正在进行中的网络通话call id
 *
 *  @return call id, 如果没有正在进行中的通话则返回0
 */
- (UInt64)currentCallID;

/**
 *  获取当前网络通话的网络状态
 *
 *  @return 网络状态
 */
- (NIMNetCallNetStatus)netStatus;


/**
 *  开始本地MP4文件录制, 录制通话过程中自己的音视频内容到MP4文件
 *
 *  @param filePath     录制文件路径, SDK不负责创建目录, 请确保文件路径的合法性,
 *                      也可以传入nil, 由SDK自己选择文件路径
 *  @param videoBitrate 录制文件视频码率设置, 可以不指定, 由SDK自己选择合适的码率
 *
 *  @return 是否允许开始录制
 *
 *  @discussion 只有通话连接建立以后才允许开始录制
 */
- (BOOL)startLocalRecording:(nullable NSURL *)filePath
               videoBitrate:(UInt32)videoBitrate;

/**
 *  停止本地MP4文件录制
 *
 *  @return 是否接受停止录制请求
 */
- (BOOL)stopLocalRecording;

/**
 *  添加网络通话委托
 *
 *  @param delegate 网络通话委托
 */
- (void)addDelegate:(id<NIMNetCallManagerDelegate>)delegate;

/**
 *  移除网络通话委托
 *
 *  @param delegate 网络通话委托
 */
- (void)removeDelegate:(id<NIMNetCallManagerDelegate>)delegate;
@end

NS_ASSUME_NONNULL_END
