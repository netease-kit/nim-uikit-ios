//
//  NTESVideoChatViewController.h
//  NIM
//
//  Created by chris on 15/5/5.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESNetChatViewController.h"

@class NetCallChatInfo;
@class NTESVideoChatNetStatusView;

@interface NTESVideoChatViewController : NTESNetChatViewController

//通话过程中，从语音聊天切到视频聊天
- (instancetype)initWithCallInfo:(NetCallChatInfo *)callInfo;

@property (weak, nonatomic) IBOutlet UIImageView *bigVideoView;


@property (weak, nonatomic) IBOutlet UIView *smallVideoView;

@property (nonatomic,strong) IBOutlet UIButton *hungUpBtn;   //挂断按钮

@property (nonatomic,strong) IBOutlet UIButton *acceptBtn; //接通按钮

@property (nonatomic,strong) IBOutlet UIButton *refuseBtn;   //拒接按钮

@property (nonatomic,strong) IBOutlet UILabel  *durationLabel;//通话时长

@property (nonatomic,strong) IBOutlet UIButton *muteBtn;     //静音按钮

@property (nonatomic,strong) IBOutlet UIButton *switchModelBtn; //模式转换按钮

@property (nonatomic,strong) IBOutlet UIButton *switchCameraBtn; //切换前后摄像头

@property (nonatomic,strong) IBOutlet UIButton *disableCameraBtn; //禁用摄像头按钮

@property (weak, nonatomic) IBOutlet UIButton *localRecordBtn; //录制

@property (nonatomic,strong) IBOutlet UILabel  *connectingLabel;  //等待对方接听

@property (nonatomic,strong) IBOutlet NTESVideoChatNetStatusView *netStatusView;//网络状况

@property (weak, nonatomic) IBOutlet UIView *localRecordingView;

@property (weak, nonatomic) IBOutlet UIView *localRecordingRedPoint;

@property (weak, nonatomic) IBOutlet UIView *lowMemoryView;

@property (weak, nonatomic) IBOutlet UIView *lowMemoryRedPoint;

@end
