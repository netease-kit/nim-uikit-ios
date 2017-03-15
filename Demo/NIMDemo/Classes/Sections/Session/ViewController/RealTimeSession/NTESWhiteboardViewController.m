//
//  RTSDemoViewController.m
//  NIM
//
//  Created by 高峰 on 15/7/1.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESWhiteboardViewController.h"
#import "NTESWhiteboardDrawView.h"
#import "NTESTimerHolder.h"
#import "UIView+Toast.h"
#import "UIActionSheet+NTESBlock.h"
#import "NIMAvatarImageView.h"
#import "NTESWhiteboardAttachment.h"
#import "NTESSessionMsgConverter.h"
#import "NTESDevice.h"
#import "NTESBundleSetting.h"

typedef NS_ENUM(NSUInteger, WhiteBoardCmdType){
    WhiteBoardCmdTypePointStart    = 1,
    WhiteBoardCmdTypePointMove     = 2,
    WhiteBoardCmdTypePointEnd      = 3,
    
    WhiteBoardCmdTypeCancelLine    = 4,
    WhiteBoardCmdTypePacketID      = 5,
    WhiteBoardCmdTypeClearLines    = 6,
    WhiteBoardCmdTypeClearLinesAck = 7,
};

static const NSTimeInterval CallerWaitSeconds = 40;
static const NSTimeInterval SendCmdIntervalSeconds = 0.06;

@interface NTESWhiteboardViewController ()<NIMRTSManagerDelegate, NTESTimerHolderDelegate>

@property (strong, nonatomic) NTESWhiteboardDrawView *myDrawView;
@property (strong, nonatomic) NTESWhiteboardDrawView *peerDrawView;
@property (weak, nonatomic) IBOutlet UIButton *acceptButton;
@property (weak, nonatomic) IBOutlet UIButton *rejectButton;
@property (weak, nonatomic) IBOutlet UIView *headerView;

@property (weak, nonatomic) IBOutlet UIView *footerView;
@property (weak, nonatomic) IBOutlet UIButton *muteButton;
@property (weak, nonatomic) IBOutlet UIButton *SpeakerButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;

@property (weak, nonatomic) IBOutlet UILabel *hintTextLabel;
@property (weak, nonatomic) IBOutlet NIMAvatarImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameTextLabel;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UILabel *closeLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelRequestButton;

@property (copy, nonatomic) NSString *sessionID;
@property (copy, nonatomic) NSString *peerID;
@property (assign, nonatomic) NSUInteger types;
@property (copy, nonatomic) NSString *info;
@property (assign, nonatomic) BOOL isCaller;

@property (assign, nonatomic) BOOL mute;
@property (assign, nonatomic) BOOL speaker;

@property (strong, nonatomic) NSMutableString *cmds;
@property (strong, nonatomic) NSLock *cmdsLock;
@property (strong, nonatomic) NTESTimerHolder *sendCmdsTimer;
@property (assign, nonatomic) NSUInteger drawViewWidth;

@property (strong, nonatomic) NTESTimerHolder *callerWaitingTimer;

@property (assign, nonatomic) UInt64 refPacketID;

@property (assign, nonatomic) BOOL audioConnected;
@property (assign, nonatomic) BOOL dismissed;

@property (assign, nonatomic) BOOL needTerminateRTS;

@end

@implementation NTESWhiteboardViewController

#pragma mark - public methods
- (id)initWithSessionID:(NSString *)sessionID
                 peerID:(NSString *)peerID
                  types:(NSUInteger)types
                   info:(NSString *)info
{
    if (self = [super init]) {
        _sessionID = sessionID;
        _peerID = peerID;
        _types = types;
        _info = info;
        _isCaller = _sessionID ? NO : YES;
        _mute = YES;
        _speaker = YES;
        _cmds = [[NSMutableString alloc] initWithCapacity:1];
        _cmdsLock = [[NSLock alloc] init];
        _sendCmdsTimer = [[NTESTimerHolder alloc] init];
        _needTerminateRTS = YES;
    }
    return self;

}

- (void)viewDidLoad {
    [super viewDidLoad];
    id<NIMRTSManager> manager = [NIMAVChatSDK sharedSDK].rtsManager;
    [manager addDelegate:self];
    [self updateButton];
    
    NIMKitInfo *info = [[NIMKit sharedKit] infoByUser:_peerID option:nil];
    NSURL *avatarURL;
    if (info.avatarUrlString.length) {
        avatarURL = [NSURL URLWithString:info.avatarUrlString];
    }
    [_avatarImageView nim_setImageWithURL:avatarURL placeholderImage:info.avatarImage options:SDWebImageRetryFailed];
    
    [_nameTextLabel setText:[info showName]];
    
    self.view.backgroundColor = UIColorFromRGB(0xE9ECF0);
    
    [_nameTextLabel setTextColor:UIColorFromRGB(0x868686)];
    [_hintTextLabel setTextColor:UIColorFromRGB(0x868686)];
    
    [_cancelRequestButton setBackgroundColor:UIColorFromRGB(0xF54A63)];
    [_rejectButton setBackgroundColor:UIColorFromRGB(0xF54A63)];
    [_acceptButton setBackgroundColor:UIColorFromRGB(0x0F91F2)];
    [_cancelButton setBackgroundColor:UIColorFromRGB(0x0F91F2)];
    [_clearButton setBackgroundColor:UIColorFromRGB(0xF54A63)];
    [_headerView setBackgroundColor:UIColorFromRGB(0xFDFDFE)];
    
    _rejectButton.layer.cornerRadius = 8;
    _acceptButton.layer.cornerRadius = 8;
    _cancelRequestButton.layer.cornerRadius = 8;
    _cancelButton.layer.cornerRadius = 5;
    _clearButton.layer.cornerRadius = 5;
    
    _headerView.layer.borderWidth = 0.5;
    _headerView.layer.borderColor = UIColorFromRGB(0x9FA1A5).CGColor;
    _footerView.layer.borderWidth = 0.5;
    _footerView.layer.borderColor = UIColorFromRGB(0x9FA1A5).CGColor;

    if (_isCaller) {
        [self switchToCallerView];
        [self requestRTS];
        [_hintTextLabel setText:@"正在邀请对方, 请稍后"];
        _callerWaitingTimer = [[NTESTimerHolder alloc] init];
        [_callerWaitingTimer startTimer:CallerWaitSeconds delegate:self repeats:NO];
    }
    else {
        [_hintTextLabel setText:@"对方发起白板演示"];
        [self switchToCalleeView];
    }
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:animated];
}
- (void)dealloc
{
    [self termimateRTS];
}

#pragma mark - user interfaces
- (IBAction)onRejectButtonPressed:(id)sender {
    [self responseRTS:NO];
    [self dismiss];
}
- (IBAction)onAcceptButtonPressed:(id)sender {
    
    if (_types & NIMRTSServiceAudio) {
        UInt64 currentNetcall = [[NIMAVChatSDK sharedSDK].netCallManager currentCallID];
        if (currentNetcall) {
            [[NIMAVChatSDK sharedSDK].netCallManager hangup:currentNetcall];
        }
    }
    
    [self responseRTS:YES];
    [self switchToWaitingConnectView];
}
- (IBAction)onMuteButtonPressed:(id)sender {
    _mute = !_mute;
    [self updateButton];
    [[NIMAVChatSDK sharedSDK].rtsManager setMute:_mute];
    [[NIMAVChatSDK sharedSDK].rtsManager sendRTSControl:_mute ? @"关闭了声音" : @"打开了声音" forSession:_sessionID];
}
- (IBAction)onSpeakerButtonPressed:(id)sender {
    _speaker = !_speaker;
    [self updateButton];
    [[NIMAVChatSDK sharedSDK].rtsManager setSpeaker:_speaker];
}
- (IBAction)onCloseButtonPressed:(id)sender {
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"退出后, 你将不再接收白板演示的消息内容" delegate:nil cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"退出", nil];
    __weak typeof(self) wself = self;
    [sheet showInView:self.view completionHandler:^(NSInteger index) {
        if (index != sheet.cancelButtonIndex) {
            [wself termimateRTS];
            [wself dismissAfter:2];
        }
    }];
}

- (IBAction)onCancelButtonPressed:(id)sender {
    [_myDrawView deleteLastLine];
    [self sendWhiteboardCmd:WhiteBoardCmdTypeCancelLine];
}

- (IBAction)onClearLinesButtonPressed:(id)sender {
    [self clearWhiteboard];
    [self sendWhiteboardCmd:WhiteBoardCmdTypeClearLines];
}

- (IBAction)onCancelRequestButtonPressed:(id)sender
{
    [self termimateRTS];
    [self dismiss];
}


#pragma mark - delegates
#pragma mark NIMRTSManagerDelegate
- (void)onRTSResponse:(NSString *)sessionID
                 from:(NSString *)callee
             accepted:(BOOL)accepted
{
    if (!accepted) {
        DDLogInfo(@"RTSDemo: peer rejected");
        [self makeToast:@"对方拒绝了本次请求"];
        [self dismiss];
    }
    else {
        [self switchToWaitingConnectView];
        [_callerWaitingTimer stopTimer];
    }
}

- (void)onRTSTerminate:(NSString *)sessionID
                    by:(NSString *)user
{
    DDLogInfo(@"RTSDemo: peer terminated, session id %@, current session id %@", sessionID, _sessionID);
    if (sessionID == _sessionID) {
        [self makeToast:@"对方已离开"];
        [self termimateRTS];
        if ([[NTESDevice currentDevice] isInBackground]) {
            [self dismiss];
        }
        else {
            [self dismissAfter:2];
        }
    }
}

- (void)onRTSResponsedByOther:(NSString *)sessionID
                     accepted:(BOOL)accepted
{
    DDLogInfo(@"RTSDemo: responsed by other");
    [self makeToast:[NSString stringWithFormat:@"已在其他端%@", accepted ? @"接受" : @"拒绝"]];
    _needTerminateRTS = NO;
    [self dismissAfter:2];


}
- (void)onRTS:(NSString *)sessionID
      service:(NIMRTSService)type
       status:(NIMRTSStatus)status
        error:(NSError *)error
{
    DDLogInfo(@"RTSDemo: service %zd status %zd", type, status);
    if (type == NIMRTSServiceReliableTransfer) {
        if (status == NIMRTSStatusConnect) {
            [self switchToConnectedView];
            [_sendCmdsTimer startTimer:SendCmdIntervalSeconds delegate:self repeats:YES];
        }
        else {
            DDLogInfo(@"已断开连接: %zd", error.code);
            [self termimateRTS];
            [self dismissAfter:1];
        }
    }
    else if (type == NIMRTSServiceAudio) {
        _audioConnected = (status == NIMRTSStatusConnect) ? YES : NO;
        if (_audioConnected) {
            [[NIMAVChatSDK sharedSDK].rtsManager setMute:_mute];
        }
        else {
            DDLogInfo(@"已断开音频服务: %zd", error.code);
        }
        if (![_footerView isHidden]) {
            [_muteButton setHidden:!_audioConnected];
        }
    }
}

- (void)onRTSReceive:(NSString *)sessionID
                data:(NSData *)data
                from:(NSString *)user
              withIn:(NIMRTSService)channel
{
    NSString *cmdString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    DDLogDebug(@"receive app data:%@", cmdString);
    NSArray *cmds = [cmdString componentsSeparatedByString:@";"];
    BOOL newLine = NO;
    NSMutableArray *points = [[NSMutableArray alloc] init];
    for (NSString *cmdString in cmds) {
        if ([cmdString rangeOfString:@":"].length == 0) {
            continue;
        }
        NSArray *cmd = [cmdString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":,"]];
        NSAssert(cmd.count == 3, @"Invalid cmd");
        
        NSInteger c = [cmd[0] integerValue];
        NSArray *point = [NSArray arrayWithObjects:
                          @([cmd[1] floatValue] * _drawViewWidth),
                          @([cmd[2] floatValue] * _drawViewWidth), nil];
        switch (c) {
            case WhiteBoardCmdTypePointStart:
                if ([points count] > 0) {
                    [_peerDrawView addPoints:points isNewLine:newLine];
                    points = [[NSMutableArray alloc] init];
                }
                newLine = YES;
            case WhiteBoardCmdTypePointMove:
            case WhiteBoardCmdTypePointEnd:
                [points addObject:point];
                break;
            case WhiteBoardCmdTypeCancelLine:
                [_peerDrawView deleteLastLine];
                break;
//            case WhiteBoardCmdTypePacketID:
//                DDLogDebug(@"------receive cmd id %@", cmd[1]);
//                break;
            case WhiteBoardCmdTypeClearLines:
                [self clearWhiteboard];
                [self sendWhiteboardCmd:WhiteBoardCmdTypeClearLinesAck];
                break;
            case WhiteBoardCmdTypeClearLinesAck:
                [self clearWhiteboard];
                break;
            default:
                break;
        }
    }
    if ([points count] > 0) {
        [_peerDrawView addPoints:points isNewLine:newLine];
    }
}

- (void)onRTSControl:(NSString *)controlInfo
                from:(NSString *)user
          forSession:(NSString *)sessionID
{
    if (sessionID == _sessionID) {
        DDLogDebug(@"Receive control info [%@] from %@", controlInfo, user);
        [self.view.window makeToast:[NSString stringWithFormat:@"%@: %@", user, controlInfo]
                           duration:2
                           position:CSToastPositionBottom];
    }
}

- (void)onRTSRecordingInfo:(NIMRTSRecordingInfo *)info
                forSession:(NSString *)sessionID
{
//    NSString *fileType = (info.service == NIMRTSServiceReliableTransfer) ? @"白板" : @"语音";
//    [self sendMessage:[NTESSessionMsgConverter msgWithText:[NSString stringWithFormat:@"%@:%@", fileType, info.recordFileName]]];
}


#pragma mark UIResponder
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint p = [[touches anyObject] locationInView:_myDrawView];
    [self onPointCollected:p type:WhiteBoardCmdTypePointStart];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint p = [[touches anyObject] locationInView:_myDrawView];
    [self onPointCollected:p type:WhiteBoardCmdTypePointMove];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint p = [[touches anyObject] locationInView:_myDrawView];
    [self onPointCollected:p type:WhiteBoardCmdTypePointEnd];
}

#pragma mark M80TimerHolderDelegate
- (void)onNTESTimerFired:(NTESTimerHolder *)holder
{
    if (holder == _sendCmdsTimer) {
        [self sendCmds];
    }
    else if (holder == _callerWaitingTimer) {
        [self makeToast:@"对方未接受请求"];
        [self termimateRTS];
        [self dismissAfter:2];
    }
}

#pragma mark - private methods
- (void)requestRTS
{
    
    NIMRTSOption *option = [[NIMRTSOption alloc] init];
    
    option.extendMessage = @"白板请求扩展信息";
    option.apnsContent = @"邀请你加入白板会话";
    option.apnsSound = @"video_chat_tip_receiver.aac";
    [self fillUserSetting:option];
    
    __weak typeof(self) wself = self;
    _sessionID = [[NIMAVChatSDK sharedSDK].rtsManager requestRTS:[NSArray arrayWithObject:_peerID]
                                                  services:_types
                                                    option:option
                                                completion:^(NSError *error, NSString *sessionID, UInt64 channelID)
    {
        if (error) {
            DDLogInfo(@"RTSDemo: send request failed %zd!!!", error.code);
            NSString *errToast = (error.code == NIMRemoteErrorCodeCalleeOffline) ? @"对方不在线" : [NSString stringWithFormat:@"发起失败:%zd", error.code];
            [wself makeToast:errToast];
            [wself dismissAfter:2];
        }
        else {
            DDLogInfo(@"RTSDemo: session %@ channel %llu", sessionID, channelID);
            NTESWhiteboardAttachment *attachment = [[NTESWhiteboardAttachment alloc] init];
            attachment.flag = CustomWhiteboardFlagInvite;
            NIMMessage *message = [NTESSessionMsgConverter msgWithWhiteboardAttachment:attachment];
            [wself sendMessage:message];
        }
    }];
}
- (void)responseRTS:(BOOL)accepted
{
    NIMRTSOption *option = [[NIMRTSOption alloc] init];    
    [self fillUserSetting:option];

    __weak typeof(self) wself = self;
    [[NIMAVChatSDK sharedSDK].rtsManager responseRTS:_sessionID
                                        accept:accepted
                                        option:option
                                    completion:^(NSError *error, NSString *sessionID, UInt64 channelID) {
        if (error) {
            [wself makeToast:[NSString stringWithFormat:@"接听失败:%zd", error.code]];
            DDLogInfo(@"RTSDemo: send response failed %zd!!!", error.code);
            [wself dismissAfter:2];
        }
        else {
            DDLogInfo(@"RTSDemo: session %@ channel %llu", sessionID, channelID);
        }
    }];
}

- (void)termimateRTS
{
    if (_needTerminateRTS) {
        _needTerminateRTS = NO;
        [[NIMAVChatSDK sharedSDK].rtsManager terminateRTS:_sessionID];
    }
}

- (void)onPointCollected:(CGPoint)p type:(WhiteBoardCmdType)type
{
    //send to peer
    NSString *cmd = [NSString stringWithFormat:@"%zd:%.3f,%.3f;", type, p.x/_drawViewWidth, p.y/_drawViewWidth];
    [self addCmd:cmd];
    
    //local render
    NSArray *point = [NSArray arrayWithObjects:@(p.x), @(p.y), nil];
    [_myDrawView addPoints:[NSMutableArray arrayWithObjects:point, nil]
                 isNewLine:(type == WhiteBoardCmdTypePointStart)];
}

- (void)addCmd:(NSString *)aCmd
{
    [_cmdsLock lock];
    [_cmds appendString:aCmd];
    [_cmdsLock unlock];
    
    if ([_cmds length] >= 30000) {
        [self sendCmds];
    }
}

- (void)sendCmds
{
    [_cmdsLock lock];
    if ([_cmds length] > 0) {
//        DDLogDebug(@"++++++send cmd id %llu", _refPacketID);
        NSString *cmd = [NSString stringWithFormat:@"%zd:%llu,0;", WhiteBoardCmdTypePacketID, _refPacketID ++];
        [_cmds appendString:cmd];
        
        [self sendRTSData:_cmds];
        [_cmds setString:@""];
    }
    [_cmdsLock unlock];
}


- (void)sendRTSData:(NSString *)data
{
    BOOL success = [[NIMAVChatSDK sharedSDK].rtsManager sendRTSData:[data dataUsingEncoding:NSUTF8StringEncoding]
                                                        from:_sessionID
                                                           to:(_isCaller ? nil : _peerID) //单播和广播发送示例
                                                        with:NIMRTSServiceReliableTransfer];
    if (!success) {
        [self.view.window makeToast:@"数据发送失败" duration:1 position:CSToastPositionBottom];
    }
}

- (void)switchToCallerView
{
    [_rejectButton setHidden:YES];
    [_acceptButton setHidden:YES];
    [_cancelRequestButton setHidden:NO];
    [_footerView setHidden:YES];
    [_hintTextLabel setHidden:NO];
    [_avatarImageView setHidden:NO];
    [_nameTextLabel setHidden:NO];
    [_closeButton setHidden:YES];
    [_closeLabel setHidden:YES];
}


- (void)switchToCalleeView
{
    [_rejectButton setHidden:NO];
    [_acceptButton setHidden:NO];
    [_cancelRequestButton setHidden:YES];
    [_footerView setHidden:YES];
    [_hintTextLabel setHidden:NO];
    [_avatarImageView setHidden:NO];
    [_nameTextLabel setHidden:NO];
    [_closeButton setHidden:YES];
    [_closeLabel setHidden:YES];
}

- (void)switchToWaitingConnectView
{
    [_rejectButton setHidden:YES];
    [_acceptButton setHidden:YES];
    [_cancelRequestButton setHidden:YES];
    [_footerView setHidden:YES];
    [_hintTextLabel setHidden:NO];
    [_avatarImageView setHidden:NO];
    [_nameTextLabel setHidden:NO];
    [_closeButton setHidden:NO];
    [_closeLabel setHidden:NO];
}

- (void)switchToConnectedView
{
    [_rejectButton setHidden:YES];
    [_acceptButton setHidden:YES];
    [_cancelRequestButton setHidden:YES];
    [_footerView setHidden:NO];
    [_muteButton setHidden:!_audioConnected];
    [self showDrawView];
    [_hintTextLabel setHidden:YES];
    [_avatarImageView setHidden:YES];
    [_nameTextLabel setHidden:YES];
    [_closeButton setHidden:NO];
    [_closeLabel setHidden:NO];
}

- (void)showDrawView
{
    CGRect frame = self.view.bounds;
    _drawViewWidth = frame.size.width;
    
    frame.origin.y = (frame.size.height - frame.size.width) / 2;
    frame.size.height = _drawViewWidth;

    _myDrawView = [[NTESWhiteboardDrawView alloc] initWithFrame:frame];
    _myDrawView.layer.borderWidth = 0.5;
    _myDrawView.layer.borderColor = UIColorFromRGB(0x9FA1A5).CGColor;
    _myDrawView.backgroundColor = [UIColor whiteColor];
    [_myDrawView setLineColor:[UIColor redColor]];
    [self.view addSubview:_myDrawView];
    
    _peerDrawView = [[NTESWhiteboardDrawView alloc] initWithFrame:frame];
    _peerDrawView.layer.borderWidth = 0.5;
    _peerDrawView.layer.borderColor = UIColorFromRGB(0x9FA1A5).CGColor;
    _peerDrawView.backgroundColor = [UIColor clearColor];
    [_peerDrawView setLineColor:[UIColor greenColor]];
    [self.view addSubview:_peerDrawView];
}

- (void)updateButton
{
    NSString *image = _mute? @"btn_whiteboard_sound_close" : @"btn_whiteboard_sound_open";
    [_muteButton setImage:[UIImage imageNamed:image] forState:UIControlStateNormal];
    [_muteButton setImage:[UIImage imageNamed:image] forState:UIControlStateHighlighted];
}

- (void)dismissAfter:(NSTimeInterval)seconds
{
    [self.view setUserInteractionEnabled:NO];
    __weak typeof(self) wself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [wself dismiss];
    });
}

- (void)dismiss{
    if (_dismissed) {
        return;
    }
    _dismissed = YES;
    id<NIMRTSManager> manager = [NIMAVChatSDK sharedSDK].rtsManager;
    [manager removeDelegate:self];
    
    NTESWhiteboardAttachment *attachment = [[NTESWhiteboardAttachment alloc] init];
    attachment.flag = CustomWhiteboardFlagClose;
    NIMMessage *message = [NTESSessionMsgConverter msgWithWhiteboardAttachment:attachment];
    [[[NIMSDK sharedSDK] conversationManager] saveMessage:message
                                               forSession:[NIMSession session:_peerID type:NIMSessionTypeP2P]
                                                           completion:nil];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [self dismissViewControllerAnimated:NO completion:^{
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
    }];
}

- (void)makeToast:(NSString *)toast
{
    [self.view.window makeToast:toast duration:3 position:CSToastPositionCenter];
}

- (void)sendMessage:(NIMMessage *)message
{
    [[[NIMSDK sharedSDK] chatManager] sendMessage:message
                                        toSession:[NIMSession session:_peerID type:NIMSessionTypeP2P]
                                            error:nil];
}

//发送纯命令, 不带参数
- (void)sendWhiteboardCmd:(WhiteBoardCmdType)cmd
{
    NSString *cmdString = [NSString stringWithFormat:@"%zd:0,0;", cmd];
    [self addCmd:cmdString];
}

- (void)clearWhiteboard
{
    [_myDrawView clear];
    [_peerDrawView clear];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)fillUserSetting:(NIMRTSOption *)option
{
    option.serverRecordAudio = [[NTESBundleSetting sharedConfig] serverRecordAudio];
    option.serverRecordData = [[NTESBundleSetting sharedConfig] serverRecordWhiteboardData];
    option.autoDeactivateAudioSession = [[NTESBundleSetting sharedConfig] autoDeactivateAudioSession];
    option.audioDenoise = [[NTESBundleSetting sharedConfig] audioDenoise];
    option.voiceDetect = [[NTESBundleSetting sharedConfig] voiceDetect];
    option.preferHDAudio =  [[NTESBundleSetting sharedConfig] voiceDetect];
}


@end
