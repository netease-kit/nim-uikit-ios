//
//  NTESNetChatViewController.h
//  NIM
//
//  Created by chris on 15/5/18.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTESTimerHolder.h"
#import "NTESRecordSelectView.h"

@class NTESNetCallChatInfo;
@class AVAudioPlayer;


@interface NTESNetChatViewController : UIViewController<NIMNetCallManagerDelegate,NTESTimerHolderDelegate,NTESRecordSelectViewDelegate>

@property (nonatomic,strong) NTESNetCallChatInfo *callInfo;

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

- (void)onCalleeBusy;

//开始语音对话录制
- (BOOL)startAudioRecording;
//开始本地录制
- (BOOL)startLocalRecording;
//开始对方录制
- (BOOL)startOtherSideRecording;
//结束语音对话录制
-(void)stopAudioRecording;
//结束本地录制
- (BOOL)stopLocalRecording;
//结束对方录制
- (BOOL)stopOtherSideRecording;
//结束所有录制任务
- (void)stopRecordTaskWithVideo:(BOOL)isVideo;
//所有录制是否结束
- (BOOL)allRecordsStopped;

//低空间警告
- (void)udpateLowSpaceWarning:(BOOL)show;

//选择类型进行录制
- (void)recordWithAudioConversation:(BOOL)audioConversationOn myMedia:(BOOL)myMediaOn otherSideMedia:(BOOL)otherSideMediaOn video:(BOOL)isVideo;

//显示录制选择框
-(void)showRecordSelectView:(BOOL)isVideo;


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
