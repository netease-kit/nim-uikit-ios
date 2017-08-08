//
//  NTESTeamMeetingViewController.m
//  NIM
//
//  Created by chris on 2017/5/2.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import "NTESTeamMeetingViewController.h"
#import "UIView+NTES.h"
#import "NTESMeetingMember.h"
#import "NTESTeamMeetingCollectionViewCell.h"
#import "NTESSessionMsgConverter.h"
#import "NTESTimerHolder.h"
#import "NSDictionary+NTESJson.h"
#import "NTESCustomSysNotificationSender.h"
#import "NTESTeamMeetingCallerInfo.h"
#import "NTESTeamMeetingCalleeInfo.h"
#import "NTESSessionUtil.h"
#import "NTESVideoDataTimeoutChecker.h"
#import "NTESTeamMeetingMutesViewController.h"
#import "UIAlertView+NTESBlock.h"
#import "UIView+Toast.h"
#import "NTESBundleSetting.h"

typedef NS_ENUM(NSInteger,NTESTeamMeetingRoleType) {
    NTESTeamMeetingRoleCaller,
    NTESTeamMeetingRoleCallee,
};

@interface NTESTeamMeetingViewController ()<NTESTimerHolderDelegate,NIMNetCallManagerDelegate,NTESVideoDataTimeoutProtocol,NTESTeamMeetingMutesDelegate>
{
    NIMNetCallCamera _camera;
    BOOL _disableCamera;
    BOOL _disableMic;
    BOOL _enableSpeaker;
    
    NTESCustomSysNotificationSender *_notificationSender;
    
    NSInteger _meetingSeconds;
}

//播放提示音
@property (nonatomic,strong) AVAudioPlayer *player;

//所在的群
@property (nonatomic,strong) NIMTeam *team;

//邀请的人
@property (nonatomic,copy) NSArray *invitedMembers;

//等待被叫定时器
@property (nonatomic,strong) NTESTimerHolder *timer;

//yuv 数据检查器，隔一段时间检查一次，如果没有新的 yuv 数据进来，认为发送方不再发送 yuv 数据
@property (nonatomic,strong) NTESVideoDataTimeoutChecker *checker;

//会议
@property (nonatomic,strong) NIMNetCallMeeting *meeting;

//所在会议角色类型
@property (nonatomic,assign) NTESTeamMeetingRoleType role;


@end

@implementation NTESTeamMeetingViewController

- (instancetype)initWithCallerInfo:(NTESTeamMeetingCallerInfo *)info
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        [self setup:info.members teamId:info.teamId];
        
        _meeting = [self makeMeeting];
        _meeting.name = [NSUUID UUID].UUIDString;
        
        
        _role = NTESTeamMeetingRoleCaller;
        _notificationSender = [[NTESCustomSysNotificationSender alloc] init];
    }
    return self;
}

- (instancetype)initWithCalleeInfo:(NTESTeamMeetingCalleeInfo *)info
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        [self setup:info.members teamId:info.teamId];
        
        _meeting = [self makeMeeting];
        _meeting.name = info.meetingName;
        
        _role = NTESTeamMeetingRoleCallee;
        _notificationSender = [[NTESCustomSysNotificationSender alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self removeListeners];
    [_player stop];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColorFromRGB(0x1b1e20);
    self.muteButton.enabled = NO;
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    self.collectionView.collectionViewLayout = layout;
    [self.collectionView registerClass:[NTESTeamMeetingCollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    [self setupButtons];
    NTESTeamMeetingCollectionSeparatorView *separatorView = [[NTESTeamMeetingCollectionSeparatorView alloc] initWithFrame:self.collectionView.bounds];
    separatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.collectionView addSubview:separatorView];
    
    
    [self checkServiceEnable:^(BOOL enable) {
        if (enable) {
            if (self.role == NTESTeamMeetingRoleCaller)
            {
                [self reserveMeetting];
            }
            else if (self.role == NTESTeamMeetingRoleCallee)
            {
                [self joinMeeting];
            }
            _camera = NIMNetCallCameraFront;
            _disableCamera = NO;
            
            [self addListeners];
            [self startVideoDataCheck];
        }else{
            [self dismiss];
        }
    }];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.collectionView.width = self.view.width;
    self.collectionView.height = self.view.width;
    CGFloat spacing = 15.f;
    self.durationLabel.top = self.collectionView.bottom + spacing;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarHidden = YES;
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarHidden = NO;
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}



- (void)reserveMeetting
{
    __weak typeof(self) weakSelf = self;
    [[NIMAVChatSDK sharedSDK].netCallManager reserveMeeting:self.meeting completion:^(NIMNetCallMeeting * _Nonnull meeting, NSError * _Nonnull error) {
        
        dispatch_block_t onError = ^(void){
            // 直接插入一条空 Tip 消息
            [weakSelf sendReserveErrorTip];
            [weakSelf dismiss];
        };
        
        if (!error)
        {
            [[NIMAVChatSDK sharedSDK].netCallManager joinMeeting:weakSelf.meeting completion:^(NIMNetCallMeeting * _Nonnull meeting, NSError * _Nonnull error) {
                if (!error)
                {
                    // 先插入一条 Tip 消息到群中
                    [weakSelf sendReserveSuccessTip];
                    // 逐个发通知给被叫
                    [weakSelf sendCallNotification];
                    // 启动定时器
                    [weakSelf startTimer];
                    // 播放拨打音
                    [weakSelf ring];
                }
                else
                {
                    DDLogError(@"join meeting error! error %@",error);
                    dispatch_async_main_safe(onError);
                }
            }];
        }
        else
        {
            DDLogError(@"reserve meeting error! error %@",error);
            dispatch_async_main_safe(onError);
        }
    }];
}

- (void)joinMeeting
{
    __weak typeof(self) weakSelf = self;
    
    dispatch_block_t onError = ^(void){
        // 直接插入一条空 Tip 消息
        [weakSelf sendJoinErrorTip];
        [weakSelf dismiss];
    };
    
    [[NIMAVChatSDK sharedSDK].netCallManager joinMeeting:self.meeting completion:^(NIMNetCallMeeting * _Nonnull meeting, NSError * _Nonnull error) {
        if (!error)
        {
            // 启动定时器
            [weakSelf startTimer];
        }
        else
        {
            DDLogError(@"join meeting error! error %@",error);
            dispatch_async_main_safe(onError);
        }
    }];
}

- (void)startTimer
{
    _meetingSeconds = 0;
    _timer = [[NTESTimerHolder alloc] init];
    [_timer startTimer:1 delegate:self repeats:YES];
}

- (void)startVideoDataCheck
{
    _checker = [[NTESVideoDataTimeoutChecker alloc] init];
    _checker.delegate = self;
}

#pragma mark - IBAction
- (IBAction)close:(id)sender
{
    [[NIMAVChatSDK sharedSDK].netCallManager leaveMeeting:self.meeting];
    [self dismiss];
}

- (IBAction)switchCamera:(id)sender
{
    _camera = _camera == NIMNetCallCameraBack? NIMNetCallCameraFront : NIMNetCallCameraBack;
    self.cameraSwitchButton.selected = _camera == NIMNetCallCameraBack;
    [[NIMAVChatSDK sharedSDK].netCallManager switchCamera:_camera];
}

- (IBAction)disableCamera:(id)sender
{
    _disableCamera = !_disableCamera;
    self.cameraDisableButton.selected = _disableCamera;
    
    [[NIMAVChatSDK sharedSDK].netCallManager setCameraDisable:_disableCamera];
    [[NIMAVChatSDK sharedSDK].netCallManager setVideoSendMute:_disableCamera];
    
    NIMNetCallControlType control = _disableCamera? NIMNetCallControlTypeCloseVideo : NIMNetCallControlTypeOpenVideo;
    [[NIMAVChatSDK sharedSDK].netCallManager control:self.meeting.callID type:control];
    
    if (_disableCamera)
    {
        NSIndexPath *indexPath = [self findIndexPath:[NIMSDK sharedSDK].loginManager.currentAccount];
        if (indexPath)
        {
            NTESTeamMeetingCollectionViewCell *cell = (NTESTeamMeetingCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            [cell refreshWithDefaultAvatar:[NIMSDK sharedSDK].loginManager.currentAccount];
        }
    }
}


- (IBAction)disableMic:(id)sender
{
    _disableMic = !_disableMic;
    self.micDisableButton.selected = _disableMic;
    [[NIMAVChatSDK sharedSDK].netCallManager setMute:_disableMic];
}

- (IBAction)disableSpeaker:(id)sender
{
    _enableSpeaker = !_enableSpeaker;
    self.speakerDisableButton.selected = !_enableSpeaker;
    [[NIMAVChatSDK sharedSDK].netCallManager setSpeaker:_enableSpeaker];
}

- (IBAction)forbidUserSpeak:(id)sender
{
    NSMutableArray *members = [[NSMutableArray alloc] init];
    for (NTESMeetingMember *member in self.invitedMembers) {
        if (member.state == NTESMeetingMemberStateConnected && ![member.userId isEqualToString:[NIMSDK sharedSDK].loginManager.currentAccount])
        {
            NTESTeamMeetingMuteUser *user = [[NTESTeamMeetingMuteUser alloc] init];
            user.userId = member.userId;
            user.mute = member.mute;
            [members addObject:user];
        }
    }
    NTESTeamMeetingMutesViewController *vc = [[NTESTeamMeetingMutesViewController alloc] initWithMeetingMembers:members];
    vc.team = self.team;
    vc.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - NIMNetCallManagerDelegate
- (void)onUserJoined:(NSString *)uid
             meeting:(NIMNetCallMeeting *)meeting
{
    if ([meeting.name isEqualToString:self.meeting.name])
    {
        [self.player stop];
        NTESMeetingMember *member = [self findMember:uid];
        member.state = NTESMeetingMemberStateConnected;
        self.muteButton.enabled = YES;
        NSIndexPath *indexPath = [self findIndexPath:uid];
        if (indexPath)
        {
            NTESTeamMeetingCollectionViewCell *cell = (NTESTeamMeetingCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            [cell refreshWithUserJoin:uid];
        }
    }
}

- (void)onUserLeft:(NSString *)uid
           meeting:(NIMNetCallMeeting *)meeting
{
    if ([meeting.name isEqualToString:self.meeting.name])
    {
        NSInteger meetingMembers = 0;
        for (NTESMeetingMember *member in self.invitedMembers) {
            if ([member.userId isEqualToString:uid]) {
                member.state = NTESMeetingMemberStateDisconnected;
            }
            if (member.state == NTESMeetingMemberStateConnected) {
                meetingMembers++;
            }
        }
        self.muteButton.enabled = meetingMembers > 1;
        NSIndexPath *indexPath = [self findIndexPath:uid];
        if (indexPath)
        {
            NTESTeamMeetingCollectionViewCell *cell = (NTESTeamMeetingCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            [cell refreshWithUserLeft:uid];
        }
    }
}

- (void)onMeetingError:(NSError *)error
               meeting:(NIMNetCallMeeting *)meeting
{
    DDLogError(@"on meeting error! error %@",error);
    [self.presentingViewController.view makeToast:@"连接断开，请检查网络设置"
                                        duration:2
                                        position:CSToastPositionCenter];

    [self dismiss];
}

- (void)onLocalDisplayviewReady:(UIView *)displayView
{
    NSIndexPath *indexPath = [self findIndexPath:[NIMSDK sharedSDK].loginManager.currentAccount];
    if (indexPath)
    {
        NTESTeamMeetingCollectionViewCell *cell = (NTESTeamMeetingCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell refreshWidthCameraPreview:displayView];
    }
}

- (void)onRemoteYUVReady:(NSData *)yuvData
                   width:(NSUInteger)width
                  height:(NSUInteger)height
                    from:(NSString *)user
{
    NSIndexPath *indexPath = [self findIndexPath:user];
    if (indexPath)
    {
        NTESTeamMeetingCollectionViewCell *cell = (NTESTeamMeetingCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell refreshWidthYUV:yuvData width:width height:height];
    }
}


-(void)onMyVolumeUpdate:(UInt16)volume
{
    NSIndexPath *indexPath = [self findIndexPath:[NIMSDK sharedSDK].loginManager.currentAccount];
    if (indexPath)
    {
        NTESTeamMeetingCollectionViewCell *cell = (NTESTeamMeetingCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell refreshWidthVolume:volume];
    }
}

- (void)onSpeakingUsersReport:(nullable NSArray<NIMNetCallUserInfo *> *)report
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for (NIMNetCallUserInfo *userInfo in report)
    {
        [dict setObject:userInfo forKey:userInfo.uid];
    }
    for (NTESMeetingMember *member in self.invitedMembers)
    {
        NSIndexPath *indexPath = [self findIndexPath:member.userId];
        if (indexPath)
        {
            NTESTeamMeetingCollectionViewCell *cell = (NTESTeamMeetingCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            NIMNetCallUserInfo *userInfo = [dict objectForKey:member.userId];
            [cell refreshWidthVolume:userInfo.volume];
        }
    }
}

- (void)onControl:(UInt64)callID from:(NSString *)user type:(NIMNetCallControlType)control
{
    if (callID == self.meeting.callID)
    {
        DDLogInfo(@"on receive control command %zd from %@",control,user);
        if (control == NIMNetCallControlTypeCloseVideo)
        {
            [self onUserVideoDataTimeout:user];
        }
    }
}

#pragma mark - NTESTimerHolderDelegate
- (void)onNTESTimerFired:(NTESTimerHolder *)holder
{
    _meetingSeconds++;
    
    if (_meetingSeconds == 45) {
        //开始等被叫进来,等 45 秒，然后刷界面结果
        [self checkForTimeoutCallee];
    }
    
    NSInteger hour = _meetingSeconds / 3600;
    NSInteger minute = (_meetingSeconds % 3600) / 60;
    NSInteger second = (_meetingSeconds % 3600) % 60;
    self.durationLabel.text = [NSString stringWithFormat:@"%02zd:%02zd:%02zd",hour,minute,second];
}

#pragma mark - NTESVideoDataTimeoutProtocol
- (void)onUserVideoDataTimeout:(NSString *)user
{
    NSIndexPath *indexPath = [self findIndexPath:user];
    if (indexPath)
    {
        NTESTeamMeetingCollectionViewCell *cell = (NTESTeamMeetingCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell refreshWithDefaultAvatar:user];
    }
}


#pragma mark - NTESTeamMeetingMutesDelegate

- (void)onTeamMembersMuteStateChange:(NSArray<NTESTeamMeetingMuteUser *> *)members
{
    for (NTESTeamMeetingMuteUser *user in members) {
        [[NIMAVChatSDK sharedSDK].netCallManager setAudioMute:user.mute forUser:user.userId];
        NTESMeetingMember *member = [self findMember:user.userId];
        member.mute = user.mute;
    }
}


#pragma mark - Private

- (void)setup:(NSArray *)members teamId:(NSString *)teamId
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (NSString *uid in members) {
        NTESMeetingMember *member = [[NTESMeetingMember alloc] init];
        member.userId = uid;
        if ([uid isEqualToString:[NIMSDK sharedSDK].loginManager.currentAccount]) {
            member.state = NTESMeetingMemberStateConnected;
        }
        [array addObject:member];
    }
    _invitedMembers = [NSArray arrayWithArray:array];
    _team = [[NIMSDK sharedSDK].teamManager teamById:teamId];
    _enableSpeaker = YES;
}


- (NIMNetCallMeeting *)makeMeeting
{
    NIMNetCallMeeting *meeting = [[NIMNetCallMeeting alloc] init];
    meeting.type = NIMNetCallMediaTypeVideo;
    meeting.actor = YES;
    
    NIMNetCallOption *option = [[NIMNetCallOption alloc] init];
    [self fillUserSetting:option];
    option.videoCaptureParam.videoCrop = NIMNetCallVideoCrop1x1;
    meeting.option = option;

    return meeting;
}


- (void)fillUserSetting:(NIMNetCallOption *)option
{
    option.autoRotateRemoteVideo = [[NTESBundleSetting sharedConfig] videochatAutoRotateRemoteVideo];
    option.serverRecordAudio     = [[NTESBundleSetting sharedConfig] serverRecordAudio];
    option.serverRecordVideo     = [[NTESBundleSetting sharedConfig] serverRecordVideo];
    option.preferredVideoEncoder = [[NTESBundleSetting sharedConfig] perferredVideoEncoder];
    option.preferredVideoDecoder = [[NTESBundleSetting sharedConfig] perferredVideoDecoder];
    option.videoMaxEncodeBitrate = [[NTESBundleSetting sharedConfig] videoMaxEncodeKbps] * 1000;
    option.autoDeactivateAudioSession = [[NTESBundleSetting sharedConfig] autoDeactivateAudioSession];
    option.audioDenoise = [[NTESBundleSetting sharedConfig] audioDenoise];
    option.voiceDetect = [[NTESBundleSetting sharedConfig] voiceDetect];
    option.audioHowlingSuppress = [[NTESBundleSetting sharedConfig] audioHowlingSuppress];
    option.preferHDAudio =  [[NTESBundleSetting sharedConfig] preferHDAudio];
    option.scene = [[NTESBundleSetting sharedConfig] scene];
    option.webrtcCompatible = [[NTESBundleSetting sharedConfig] webrtcCompatible];
    
    NIMNetCallVideoCaptureParam *param = [[NIMNetCallVideoCaptureParam alloc] init];
    [self fillVideoCaptureSetting:param];
    option.videoCaptureParam = param;
    
}

- (void)fillVideoCaptureSetting:(NIMNetCallVideoCaptureParam *)param
{
    param.preferredVideoQuality = [[NTESBundleSetting sharedConfig] preferredVideoQuality];
    param.startWithBackCamera   = [[NTESBundleSetting sharedConfig] startWithBackCamera];
}


- (void)checkForTimeoutCallee
{
    NSInteger connectedCount = 0;
    for (NTESMeetingMember *member in self.invitedMembers)
    {
        switch (member.state) {
            case NTESMeetingMemberStateConnecting:
            {
                member.state = NTESMeetingMemberStateTimeout;
                NSIndexPath *indexPath = [self findIndexPath:member.userId];
                if (indexPath)
                {
                    NTESTeamMeetingCollectionViewCell *cell = (NTESTeamMeetingCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                    [cell refreshWithTimeout:member.userId];
                }
            }
                break;
            case NTESMeetingMemberStateConnected:
            case NTESMeetingMemberStateDisconnected:
            {
                //只要是连接上过的，都算上
                connectedCount++;
            }
                break;
            default:
                break;
        }
    }
    if (self.role == NTESTeamMeetingRoleCaller && connectedCount < 2) {
        //自己是拨打放，并只有自己连了上来
        [self.presentingViewController.view makeToast:@"无人接听，请重试"
                                            duration:2
                                            position:CSToastPositionCenter];
        [[NIMAVChatSDK sharedSDK].netCallManager leaveMeeting:self.meeting];
        [self dismiss];
    }
}


- (void)sendReserveErrorTip
{
    NIMMessage *message = [NTESSessionMsgConverter msgWithTip:@"呼叫失败"];
    NIMSession *session = [NIMSession session:self.team.teamId type:NIMSessionTypeTeam];
    [[NIMSDK sharedSDK].conversationManager saveMessage:message forSession:session completion:nil];
}

- (void)sendJoinErrorTip
{
    NIMMessage *message = [NTESSessionMsgConverter msgWithTip:@"加入视频聊天失败"];
    NIMSession *session = [NIMSession session:self.team.teamId type:NIMSessionTypeTeam];
    [[NIMSDK sharedSDK].conversationManager saveMessage:message forSession:session completion:nil];
}

- (void)sendReserveSuccessTip
{
    NIMSession *session = [NIMSession session:self.team.teamId type:NIMSessionTypeTeam];
    NSString *nick = [NTESSessionUtil showNick:[NIMSDK sharedSDK].loginManager.currentAccount inSession:session];
    NSString *tip = [NSString stringWithFormat:@"%@发起了视频聊天",nick];
    NIMMessage *message = [NTESSessionMsgConverter msgWithTip:tip];
    message.setting.roamingEnabled = NO;
    message.setting.historyEnabled = NO;
    message.setting.shouldBeCounted = NO;
    [[NIMSDK sharedSDK].chatManager sendMessage:message toSession:session error:nil];
}

- (void)sendCallNotification
{
    NSMutableArray *members = [[NSMutableArray alloc] init];
    for (NTESMeetingMember *member in self.invitedMembers)
    {
        [members addObject:member.userId];
    }
    [_notificationSender sendCallNotification:self.team.teamId roomName:self.meeting.name members:members];
}

//铃声 - 拨打方铃声
- (void)ring{
    [self.player stop];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"video_chat_tip_sender" withExtension:@"aac"];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.player.numberOfLoops = 30;
    [self.player play];
}


- (NTESMeetingMember *)findMember:(NSString *)userId
{
    for (NTESMeetingMember *member in self.invitedMembers)
    {
        if ([member.userId isEqualToString:userId]) {
            return member;
        }
    }
    return nil;
}

- (NSIndexPath *)findIndexPath:(NSString *)userId
{
    NSInteger index = 0;
    for (NTESMeetingMember *member in self.invitedMembers)
    {
        if ([member.userId isEqualToString:userId]) {
            break;
        }
        index++;
    }
    if (index >= self.invitedMembers.count) {
        return nil;
    }
    NSInteger section = index / self.sections;
    NSInteger row = index % self.sections;
    return [NSIndexPath indexPathForRow:row inSection:section];
}

- (NTESMeetingMember *)findMemberWithIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.section * self.rowsInSection + indexPath.row;
    if (self.invitedMembers.count > index) {
        return [self.invitedMembers objectAtIndex:index];
    }
    return nil;
}

- (void)addListeners
{
    [[NIMAVChatSDK sharedSDK].netCallManager addDelegate:self];
}

- (void)removeListeners
{
    [[NIMAVChatSDK sharedSDK].netCallManager removeDelegate:self];
}


- (void)checkServiceEnable:(void(^)(BOOL))result{
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        [[AVAudioSession sharedInstance] performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
            dispatch_async_main_safe(^{
                if (granted) {
                    NSString *mediaType = AVMediaTypeVideo;
                    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
                    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                        message:@"相机权限受限,无法视频聊天"
                                                                       delegate:nil
                                                              cancelButtonTitle:@"确定"
                                                              otherButtonTitles:nil];
                        [alert showAlertWithCompletionHandler:^(NSInteger idx) {
                            if (result) {
                                result(NO);
                            }
                        }];
                    }else{
                        if (result) {
                            result(YES);
                        }
                    }
                }
                else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                    message:@"麦克风权限受限,无法聊天"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"确定"
                                                          otherButtonTitles:nil];
                    [alert showAlertWithCompletionHandler:^(NSInteger idx) {
                        if (result) {
                            result(NO);
                        }
                    }];
                }
                
            });
        }];
    }
}


- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)rowsInSection
{
    return 3;
}

- (NSInteger)sections
{
    return 3;
}

- (void)setupButtons
{
    [self.cameraSwitchButton setImage:[UIImage imageNamed:@"btn_meeting_camera_normal"] forState:UIControlStateNormal];
    [self.cameraSwitchButton setImage:[UIImage imageNamed:@"btn_meeting_camera_pressed"] forState:UIControlStateHighlighted];
    [self.cameraSwitchButton setImage:[UIImage imageNamed:@"btn_meeting_camera_selected"] forState:UIControlStateSelected];
    [self.cameraSwitchButton setImage:[UIImage imageNamed:@"btn_meeting_camera_selected_pressed"] forState:UIControlStateSelected | UIControlStateHighlighted];
    
    [self.cameraDisableButton setImage:[UIImage imageNamed:@"btn_meeting_camera_disable_normal"] forState:UIControlStateNormal];
    [self.cameraDisableButton setImage:[UIImage imageNamed:@"btn_meeting_camera_disable_pressed"] forState:UIControlStateHighlighted];
    [self.cameraDisableButton setImage:[UIImage imageNamed:@"btn_meeting_camera_disable_selected"] forState:UIControlStateSelected];
    [self.cameraDisableButton setImage:[UIImage imageNamed:@"btn_meeting_camera_disable_selected_pressed"] forState:UIControlStateSelected | UIControlStateHighlighted];
    
    [self.micDisableButton setImage:[UIImage imageNamed:@"btn_meeting_mic_disable_normal"] forState:UIControlStateNormal];
    [self.micDisableButton setImage:[UIImage imageNamed:@"btn_meeting_mic_disable_pressed"] forState:UIControlStateHighlighted];
    [self.micDisableButton setImage:[UIImage imageNamed:@"btn_meeting_mic_disable_selected"] forState:UIControlStateSelected];
    [self.micDisableButton setImage:[UIImage imageNamed:@"btn_meeting_mic_disable_selected_pressed"] forState:UIControlStateSelected | UIControlStateHighlighted];
    
    [self.speakerDisableButton setImage:[UIImage imageNamed:@"btn_meeting_speaker_disable_normal"] forState:UIControlStateNormal];
    [self.speakerDisableButton setImage:[UIImage imageNamed:@"btn_meeting_speaker_disable_pressed"] forState:UIControlStateHighlighted];
    [self.speakerDisableButton setImage:[UIImage imageNamed:@"btn_meeting_speaker_disable_selected"] forState:UIControlStateSelected];
    [self.speakerDisableButton setImage:[UIImage imageNamed:@"btn_meeting_speaker_disable_selected_pressed"] forState:UIControlStateSelected | UIControlStateHighlighted];
    
    [self.muteButton setImage:[UIImage imageNamed:@"btn_meeting_mute_normal"] forState:UIControlStateNormal];
    [self.muteButton setImage:[UIImage imageNamed:@"btn_meeting_mute_pressed"] forState:UIControlStateHighlighted];
    [self.muteButton setImage:[UIImage imageNamed:@"btn_meeting_mute_disable"] forState:UIControlStateDisabled];
    
    [self.hangupButton setImage:[UIImage imageNamed:@"btn_meeting_hangup_normal"] forState:UIControlStateNormal];
    [self.hangupButton setImage:[UIImage imageNamed:@"btn_meeting_hangup_pressed"] forState:UIControlStateHighlighted];
}



#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width  = collectionView.width / self.rowsInSection;
    CGFloat height = width;
    return CGSizeMake(width, height);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}



#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.rowsInSection;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NTESTeamMeetingCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.team = self.team;
    
    NTESMeetingMember *member = [self findMemberWithIndexPath:indexPath];
    if (member.userId)
    {
        if ([member.userId isEqualToString:[NIMSDK sharedSDK].loginManager.currentAccount])
        {
            [cell refreshWithDefaultAvatar:member.userId];
        }
        else
        {
            [cell refrehWithConnecting:member.userId];
        }
        
    }
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 3;
}


- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


@end

