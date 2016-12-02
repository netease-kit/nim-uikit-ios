//
//  NTESAudioChatViewController.h
//  NIM
//
//  Created by chris on 15/5/12.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESNetChatViewController.h"

@class NetCallChatInfo;
@class NTESVideoChatNetStatusView;

@interface NTESAudioChatViewController : NTESNetChatViewController

- (instancetype)initWithCallInfo:(NetCallChatInfo *)callInfo;

@property (nonatomic,strong) IBOutlet UILabel *durationLabel;

@property (nonatomic,strong) IBOutlet UIButton *switchVideoBtn;

@property (nonatomic,strong) IBOutlet UIButton *muteBtn;

@property (nonatomic,strong) IBOutlet UIButton *speakerBtn;

@property (nonatomic,strong) IBOutlet UIButton *hangUpBtn;

@property (nonatomic,strong) IBOutlet UILabel  *connectingLabel;

@property (nonatomic,strong) IBOutlet UIButton *refuseBtn;

@property (nonatomic,strong) IBOutlet UIButton *acceptBtn;

@property (nonatomic,strong) IBOutlet NTESVideoChatNetStatusView *netStatusView;

@property (weak, nonatomic) IBOutlet UIButton *localRecordBtn;


@property (weak, nonatomic) IBOutlet UIView *localRecordingView;

@property (weak, nonatomic) IBOutlet UIView *localRecordingRedPoint;

@property (weak, nonatomic) IBOutlet UIView *lowMemoryView;

@property (weak, nonatomic) IBOutlet UIView *lowMemoryRedPoint;


@end
