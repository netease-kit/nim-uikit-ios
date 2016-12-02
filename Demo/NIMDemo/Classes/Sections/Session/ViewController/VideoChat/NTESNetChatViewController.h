//
//  NTESNetChatViewController.h
//  NIM
//
//  Created by chris on 15/5/18.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTESTimerHolder.h"
@class NetCallChatInfo;
@class AVAudioPlayer;


@interface NTESNetChatViewController : UIViewController<NIMNetCallManagerDelegate,NTESTimerHolderDelegate>

@property (nonatomic,strong) NetCallChatInfo *callInfo;

@property (nonatomic,strong) AVAudioPlayer *player; //播放提示音

@property (nonatomic, strong) NSString *peerUid;

//主叫方是自己，发起通话，初始化方法
- (instancetype)initWithCallee:(NSString *)callee;
//被叫方是自己，接听界面，初始化方法
- (instancetype)initWithCaller:(NSString *)caller
                        callId:(uint64_t)callID;


//主叫方开始界面回调
- (void)startByCaller;
//被叫方开始界面回调
- (void)startByCallee;
//同意后正在进入聊天界面
- (void)waitForConnectiong;
//双方开始通话
- (void)onCalling;
//挂断
- (void)hangup;
//接受/拒接通话
- (void)response:(BOOL)accept;
//退出界面
- (void)dismiss:(void (^)(void))completion;

//开始本地录制
- (BOOL)startLocalRecording;
//结束本地录制
- (BOOL)stopLocalRecording;
//低空间警告
- (void)udpateLowSpaceWarning:(BOOL)show;


#pragma mark - Ring
//铃声 - 正在呼叫请稍后
- (void)playConnnetRing;
//铃声 - 对方暂时无法接听
- (void)playHangUpRing;
//铃声 - 对方正在通话中
- (void)playOnCallRing;
//铃声 - 对方无人接听
- (void)playTimeoutRing;
//铃声 - 接收方铃声
- (void)playReceiverRing;
//铃声 - 拨打方铃声
- (void)playSenderRing;

@end
