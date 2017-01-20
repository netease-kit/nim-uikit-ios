//
//  NTESVideoChatViewController.m
//  NIM
//
//  Created by chris on 15/5/5.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESVideoChatViewController.h"
#import "UIView+Toast.h"
#import "NTESTimerHolder.h"
#import "NTESAudioChatViewController.h"
#import "NTESMainTabController.h"
#import "NetCallChatInfo.h"
#import "NTESSessionUtil.h"
#import "NTESVideoChatNetStatusView.h"
#import "NTESGLView.h"
#import "NTESBundleSetting.h"

#define NTESUseGLView

@interface NTESVideoChatViewController ()

@property (nonatomic,assign) NIMNetCallCamera cameraType;

@property (nonatomic,strong) CALayer *localVideoLayer;

@property (nonatomic,assign) BOOL oppositeCloseVideo;

#if defined (NTESUseGLView)
@property (nonatomic, strong) NTESGLView *remoteGLView;
#endif

@end

@implementation NTESVideoChatViewController

- (instancetype)initWithCallInfo:(NetCallChatInfo *)callInfo
{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        self.callInfo = callInfo;
        self.callInfo.isMute = NO;
        self.callInfo.useSpeaker = NO;
        self.callInfo.disableCammera = NO;
        if (!self.localVideoLayer) {
            //没有的话，尝试去取一把预览层（从视频切到语音再切回来的情况下是会有的）
            self.localVideoLayer = [NIMSDK sharedSDK].netCallManager.localPreviewLayer;
        }
        [[NIMSDK sharedSDK].netCallManager switchType:NIMNetCallTypeVideo];
    }
    return self;
}


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.callInfo.callType = NIMNetCallTypeVideo;
        _cameraType = [[NTESBundleSetting sharedConfig] startWithBackCamera] ? NIMNetCallCameraBack :NIMNetCallCameraFront;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.localVideoLayer) {
        [self.localView.layer addSublayer:self.localVideoLayer];
    }
    [self initUI];
}

- (void)initUI
{
    self.localRecordingView.layer.cornerRadius = 10.0;
    self.localRecordingRedPoint.layer.cornerRadius = 4.0;
    self.lowMemoryView.layer.cornerRadius = 10.0;
    self.lowMemoryRedPoint.layer.cornerRadius = 4.0;
    self.refuseBtn.exclusiveTouch = YES;
    self.acceptBtn.exclusiveTouch = YES;
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        [self initRemoteGLView];
    }
}

- (void)initRemoteGLView {
#if defined (NTESUseGLView)
    _remoteGLView = [[NTESGLView alloc] initWithFrame:_remoteView.bounds];
    [_remoteGLView setContentMode:UIViewContentModeScaleAspectFit];
    [_remoteGLView setBackgroundColor:[UIColor clearColor]];
    _remoteGLView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_remoteView addSubview:_remoteGLView];
#endif
}


#pragma mark - Call Life
- (void)startByCaller{
    [super startByCaller];
    [self startInterface];
}

- (void)startByCallee{
    [super startByCallee];
    [self waitToCallInterface];
}
- (void)onCalling{
    [super onCalling];
    [self videoCallingInterface];
}

- (void)waitForConnectiong{
    [super waitForConnectiong];
    [self connectingInterface];
}

#pragma mark - Interface
//正在接听中界面
- (void)startInterface{
    self.acceptBtn.hidden = YES;
    self.refuseBtn.hidden   = YES;
    self.hungUpBtn.hidden   = NO;
    self.connectingLabel.hidden = NO;
    self.connectingLabel.text = @"正在呼叫，请稍候...";
    self.switchModelBtn.hidden = YES;
    self.switchCameraBtn.hidden = YES;
    self.muteBtn.hidden = YES;
    self.disableCameraBtn.hidden = YES;
    self.localRecordBtn.hidden = YES;
    self.localRecordingView.hidden = YES;
    self.lowMemoryView.hidden = YES;
    [self.hungUpBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.hungUpBtn addTarget:self action:@selector(hangup) forControlEvents:UIControlEventTouchUpInside];
}

//选择是否接听界面
- (void)waitToCallInterface{
    self.acceptBtn.hidden = NO;
    self.refuseBtn.hidden   = NO;
    self.hungUpBtn.hidden   = YES;
    NSString *nick = [NTESSessionUtil showNick:self.callInfo.caller inSession:nil];
    self.connectingLabel.text = [nick stringByAppendingString:@"的来电"];
    self.muteBtn.hidden = YES;
    self.switchCameraBtn.hidden = YES;
    self.disableCameraBtn.hidden = YES;
    self.localRecordBtn.hidden = YES;
    self.localRecordingView.hidden = YES;
    self.lowMemoryView.hidden = YES;
    self.switchModelBtn.hidden = YES;
}

//连接对方界面
- (void)connectingInterface{
    self.acceptBtn.hidden = YES;
    self.refuseBtn.hidden   = YES;
    self.hungUpBtn.hidden   = NO;
    self.connectingLabel.hidden = NO;
    self.connectingLabel.text = @"正在连接对方...请稍后...";
    self.switchModelBtn.hidden = YES;
    self.switchCameraBtn.hidden = YES;
    self.muteBtn.hidden = YES;
    self.disableCameraBtn.hidden = YES;
    self.localRecordBtn.hidden = YES;
    self.localRecordingView.hidden = YES;
    self.lowMemoryView.hidden = YES;
    [self.hungUpBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.hungUpBtn addTarget:self action:@selector(hangup) forControlEvents:UIControlEventTouchUpInside];
}

//接听中界面(视频)
- (void)videoCallingInterface{
    
    NIMNetCallNetStatus status = [[NIMSDK sharedSDK].netCallManager netStatus:self.peerUid];
    [self.netStatusView refreshWithNetState:status];
    self.acceptBtn.hidden = YES;
    self.refuseBtn.hidden   = YES;
    self.hungUpBtn.hidden   = NO;
    self.connectingLabel.hidden = YES;
    self.muteBtn.hidden = NO;
    self.switchCameraBtn.hidden = NO;
    self.disableCameraBtn.hidden = NO;
    self.localRecordBtn.hidden = NO;
    self.switchModelBtn.hidden = NO;
    self.muteBtn.selected = self.callInfo.isMute;
    self.disableCameraBtn.selected = self.callInfo.disableCammera;
    self.localRecordBtn.selected = self.callInfo.localRecording;
    self.localRecordingView.hidden = !self.callInfo.localRecording;
    self.lowMemoryView.hidden = YES;
    [self.switchModelBtn setTitle:@"语音模式" forState:UIControlStateNormal];
    [self.hungUpBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.hungUpBtn addTarget:self action:@selector(hangup) forControlEvents:UIControlEventTouchUpInside];
    self.localVideoLayer.hidden = NO;
}

//切换接听中界面(语音)
- (void)audioCallingInterface{
    
    NTESAudioChatViewController *vc = [[NTESAudioChatViewController alloc] initWithCallInfo:self.callInfo];
    [UIView  beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.75];
    [self.navigationController pushViewController:vc animated:NO];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.navigationController.view cache:NO];
    [UIView commitAnimations];
    NSMutableArray * vcs = [self.navigationController.viewControllers mutableCopy];
    [vcs removeObject:self];
    self.navigationController.viewControllers = vcs;
}

- (void)udpateLowSpaceWarning:(BOOL)show {
    self.lowMemoryView.hidden = !show;
    self.localRecordingView.hidden = show;
}


#pragma mark - IBAction

- (IBAction)acceptToCall:(id)sender{
    BOOL accept = (sender == self.acceptBtn);
    //防止用户在点了接收后又点拒绝的情况
    [self response:accept];
}

- (IBAction)mute:(BOOL)sender{
    self.callInfo.isMute = !self.callInfo.isMute;
    self.player.volume = !self.callInfo.isMute;
    [[NIMSDK sharedSDK].netCallManager setMute:self.callInfo.isMute];
    self.muteBtn.selected = self.callInfo.isMute;
}

- (IBAction)switchCamera:(id)sender{
    if (self.cameraType == NIMNetCallCameraFront) {
        self.cameraType = NIMNetCallCameraBack;
    }else{
        self.cameraType = NIMNetCallCameraFront;
    }
    [[NIMSDK sharedSDK].netCallManager switchCamera:self.cameraType];
    self.switchCameraBtn.selected = (self.cameraType == NIMNetCallCameraBack);
}


- (IBAction)disableCammera:(id)sender{
    self.callInfo.disableCammera = !self.callInfo.disableCammera;
    [[NIMSDK sharedSDK].netCallManager setCameraDisable:self.callInfo.disableCammera];
    self.disableCameraBtn.selected = self.callInfo.disableCammera;
    if (self.callInfo.disableCammera) {
        [self.localVideoLayer removeFromSuperlayer];
        [[NIMSDK sharedSDK].netCallManager control:self.callInfo.callID type:NIMNetCallControlTypeCloseVideo];
    }else{
        [self.localView.layer addSublayer:self.localVideoLayer];
        [[NIMSDK sharedSDK].netCallManager control:self.callInfo.callID type:NIMNetCallControlTypeOpenVideo];
    }
}

- (IBAction)localRecord:(id)sender {
    
    if (self.callInfo.localRecording) {
        if (![self stopLocalRecording]) {
            [self.view makeToast:@"无法结束录制"
                        duration:3
                        position:CSToastPositionCenter];
        }
    }
    else {
        NSString *toastText;
        if ([self startLocalRecording]) {
            toastText = @"仅录制你的声音和图像";
        }
        else {
            toastText = @"无法开始录制";
        }
        [self.view makeToast:toastText
                    duration:3
                    position:CSToastPositionCenter];
    }
}


- (IBAction)switchCallingModel:(id)sender{
    [[NIMSDK sharedSDK].netCallManager control:self.callInfo.callID type:NIMNetCallControlTypeToAudio];
    [self switchToAudio];
}


#pragma mark - NIMNetCallManagerDelegate

- (void)setLocalVideoLayer:(CALayer *)localVideoLayer{
    _localVideoLayer = localVideoLayer;
}

- (void)onLocalPreviewReady:(CALayer *)layer{
    if (self.localVideoLayer) {
        [self.localVideoLayer removeFromSuperlayer];
    }
    self.localVideoLayer = layer;
    layer.frame = self.localView.bounds;
    [self.localView.layer addSublayer:layer];
}

#if defined(NTESUseGLView)
- (void)onRemoteYUVReady:(NSData *)yuvData
                   width:(NSUInteger)width
                  height:(NSUInteger)height
                    from:(NSString *)user
{
    if (([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) && !self.oppositeCloseVideo) {
        
        if (!_remoteGLView) {
            [self initRemoteGLView];
        }
        [_remoteGLView render:yuvData width:width height:height];
    }
}
#else
- (void)onRemoteImageReady:(CGImageRef)image{
    if (self.oppositeCloseVideo) {
        return;
    }
    self.remoteView.contentMode = UIViewContentModeScaleAspectFill;
    self.remoteView.image = [UIImage imageWithCGImage:image];
}
#endif

- (void)onControl:(UInt64)callID
             from:(NSString *)user
             type:(NIMNetCallControlType)control{
    [super onControl:callID from:user type:control];
    switch (control) {
        case NIMNetCallControlTypeToAudio:
            [self switchToAudio];
            break;
        case NIMNetCallControlTypeCloseVideo:
            [self resetRemoteImage];
            self.oppositeCloseVideo = YES;
            [self.view makeToast:@"对方关闭了摄像头"
                        duration:2
                        position:CSToastPositionCenter];
            break;
        case NIMNetCallControlTypeOpenVideo:
            self.oppositeCloseVideo = NO;
            [self.view makeToast:@"对方开启了摄像头"
                        duration:2
                        position:CSToastPositionCenter];
            break;
        default:
            break;
    }
}


-(void)onCallEstablished:(UInt64)callID
{
    if (self.callInfo.callID == callID) {
        [super onCallEstablished:callID];
        
        self.durationLabel.hidden = NO;
        self.durationLabel.text = self.durationDesc;
    }
}

- (void)onNetStatus:(NIMNetCallNetStatus)status user:(NSString *)user
{
    if ([user isEqualToString:self.peerUid]) {
        [self.netStatusView refreshWithNetState:status];
    }
}


- (void)onLocalRecordStarted:(UInt64)callID fileURL:(NSURL *)fileURL
{
    [super onLocalRecordStarted:callID fileURL:fileURL];
    if (self.callInfo.callID == callID) {
        self.localRecordBtn.selected = YES;
        self.localRecordingView.hidden = NO;
        self.lowMemoryView.hidden = YES;
    }
}


- (void)onLocalRecordError:(NSError *)error
                    callID:(UInt64)callID
{
    [super onLocalRecordError:error callID:callID];
    if (self.callInfo.callID == callID) {
        self.localRecordBtn.selected = NO;
        self.localRecordingView.hidden = YES;
        self.lowMemoryView.hidden = YES;
    }
}

- (void) onLocalRecordStopped:(UInt64)callID
                      fileURL:(NSURL *)fileURL
{
    [super onLocalRecordStopped:callID fileURL:fileURL];
    if (self.callInfo.callID == callID) {
        self.localRecordBtn.selected = NO;
        self.localRecordingView.hidden = YES;
        self.lowMemoryView.hidden = YES;
    }
}

#pragma mark - M80TimerHolderDelegate

- (void)onNTESTimerFired:(NTESTimerHolder *)holder{
    [super onNTESTimerFired:holder];
    self.durationLabel.text = self.durationDesc;
}

#pragma mark - Misc
- (void)switchToAudio{
    [self audioCallingInterface];
}

- (NSString*)durationDesc{
    if (!self.callInfo.startTime) {
        return @"";
    }
    NSTimeInterval time = [NSDate date].timeIntervalSince1970;
    NSTimeInterval duration = time - self.callInfo.startTime;
    return [NSString stringWithFormat:@"%02d:%02d",(int)duration/60,(int)duration%60];
}

- (void)resetRemoteImage{
#if defined (NTESUseGLView)
    [self.remoteGLView render:nil width:0 height:0];
#endif

    self.remoteView.image = [UIImage imageNamed:@"netcall_bkg.jpg"];
}

@end
