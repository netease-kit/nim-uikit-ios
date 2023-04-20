// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NECallViewController.h"
#import <NECommonKit/NECommonKit-Swift.h>
#import <SDWebImage/SDWebImage.h>
#import <Toast/Toast.h>
#import "NECallUIStateController.h"
#import "NECustomButton.h"
#import "NEExpandButton.h"
#import "NERtcCallUIKit.h"
#import "NEVideoOperationView.h"
#import "NEVideoView.h"
#import "NetManager.h"
#import "SettingManager.h"

NSString *const kCallKitDismissNoti = @"kCallKitDismissNoti";

NSString *const kCallKitShowNoti = @"kCallKitShowNoti";

@interface NECallViewController () <NERtcLinkEngineDelegate>

@property(nonatomic, strong) UIButton *switchCameraBtn;

@property(strong, nonatomic) NEVideoOperationView *operationView;

/// 音视频转换
@property(strong, nonatomic) NECustomButton *mediaSwitchBtn;

@property(strong, nonatomic) UILabel *timerLabel;

@property(strong, nonatomic) NSTimer *timer;

@property(strong, nonatomic) UIImageView *blurImage;

@property(strong, nonatomic) UIToolbar *toolBar;

@property(assign, nonatomic) int timerCount;

@property(nonatomic, assign) BOOL isPstn;  // 当前呼叫是否已进入pstn流程，默认 NO

@property(nonatomic, strong) UIView *bannerView;

@property(nonatomic, weak) UIAlertController *alert;

@property(nonatomic, strong) UILabel *cnameLabel;

@property(nonatomic, assign) BOOL isRemoteMute;

@property(assign, nonatomic) CGFloat factor;

/// 通话状态视图
@property(nonatomic, strong) NEAudioCallingController *audioCallingController;

@property(nonatomic, strong) NEAudioInCallController *audioInCallController;

@property(nonatomic, strong) NEVideoCallingController *videoCallingController;

@property(nonatomic, strong) NEVideoInCallController *videoInCallController;

@property(nonatomic, strong) NECalledViewController *calledController;

@property(nonatomic, weak) NECallUIStateController *stateUIController;

@property(nonatomic, strong) NSBundle *bundle;

@end

@implementation NECallViewController

- (instancetype)init {
  self = [super init];
  if (self) {
    self.timerCount = 0;
    self.factor = 1.0;
    self.bundle = [NSBundle bundleForClass:self.class];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] postNotificationName:kCallKitShowNoti object:nil];
  [[NERtcEngine sharedEngine] setParameters:@{kNERtcKeyVideoStartWithBackCamera : @NO}];
  if (self.callType == NERtcCallTypeVideo) {
    self.remoteCameraAvailable = YES;
  }
  [self setupUI];
  //  [self setupCenterRemoteAvator];
  [self setupSDK];
  [self updateUIonStatus:self.status];
  if (self.isCaller == NO && [NERtcCallKit sharedInstance].callStatus == NERtcCallStatusIdle) {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      [weakSelf onCallEnd];
    });
  }

  [self.view addSubview:self.bannerView];
  [NSLayoutConstraint activateConstraints:@[
    [self.bannerView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:80],
    [self.bannerView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20],
    [self.bannerView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20],
    [self.bannerView.heightAnchor constraintEqualToConstant:40]
  ]];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  [[NERtcCallKit sharedInstance] setupLocalView:nil];
}

#pragma mark - SDK
- (void)setupSDK {
  [[NERtcCallKit sharedInstance] addDelegate:self];
  [[NERtcCallKit sharedInstance] enableLocalVideo:YES];

  __weak typeof(self) weakSelf = self;
  if (self.status == NERtcCallStatusCalling) {
    [[NERtcCallKit sharedInstance]
               call:self.callParam.remoteUserAccid
               type:self.callType ? self.callType : NERtcCallTypeVideo
         attachment:self.callParam.attachment
        globalExtra:self.callParam.extra
          withToken:self.callParam.token
        channelName:self.callParam.channelName
         completion:^(NSError *_Nullable error) {
           NSLog(@"call error code : %@", error);
           __strong typeof(self) strongSelf = weakSelf;
           if (strongSelf.callType == NERtcCallTypeVideo) {
             if ([[SettingManager shareInstance] isGlobalInit] == YES) {
               __weak typeof(self) weakSelf2 = strongSelf;
               dispatch_async(dispatch_get_main_queue(), ^{
                 __strong typeof(self) strongSelf2 = weakSelf2;
                 [[NERtcCallKit sharedInstance]
                     setupLocalView:strongSelf2.videoCallingController.bigVideoView.videoView];
               });
             }
             strongSelf.videoCallingController.bigVideoView.userID =
                 strongSelf.callParam.currentUserAccid;
           }

           if (error) {
             /// 对方离线时 通过APNS推送 UI不弹框提示
             if (error.code == 10202 || error.code == 10201) {
               return;
             } else {
               [strongSelf onCallEnd];
             }
             [UIApplication.sharedApplication.keyWindow makeToast:error.localizedDescription];
           }
         }];
  }
}

- (void)setCallType:(NERtcCallType)callType {
  NSLog(@"set current call type : %lu", (unsigned long)callType);
  _callType = callType;
}

#pragma mark - UI
- (void)setupUI {
  if (self.view.frame.size.height < 600) {
    self.factor = 0.5;
  }

  CGSize buttonSize = CGSizeMake(75, 103);
  CGFloat statusHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;

  self.blurImage = [[UIImageView alloc] init];
  self.blurImage.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.blurImage];
  [NSLayoutConstraint activateConstraints:@[
    [self.blurImage.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.blurImage.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.blurImage.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.blurImage.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
  ]];

  if (self.callParam.remoteAvatar.length <= 0) {
    UIView *cover = [self getDefaultHeaderView:self.callParam.remoteUserAccid
                                          font:[UIFont systemFontOfSize:200]
                                      showName:self.callParam.remoteShowName];
    [self.blurImage addSubview:cover];
    [NSLayoutConstraint activateConstraints:@[
      [cover.leftAnchor constraintEqualToAnchor:self.blurImage.leftAnchor],
      [cover.rightAnchor constraintEqualToAnchor:self.blurImage.rightAnchor],
      [cover.topAnchor constraintEqualToAnchor:self.blurImage.topAnchor],
      [cover.bottomAnchor constraintEqualToAnchor:self.blurImage.bottomAnchor]
    ]];
  }

  self.toolBar = [[UIToolbar alloc] initWithFrame:self.view.bounds];
  self.toolBar.barStyle = UIBarStyleBlackOpaque;
  [self.blurImage addSubview:self.toolBar];

  [self setupChildController];

  [self.view addSubview:self.switchCameraBtn];
  [NSLayoutConstraint activateConstraints:@[
    [self.switchCameraBtn.topAnchor constraintEqualToAnchor:self.view.topAnchor
                                                   constant:statusHeight + 20],
    [self.switchCameraBtn.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20],
    [self.switchCameraBtn.heightAnchor constraintEqualToConstant:30],
    [self.switchCameraBtn.widthAnchor constraintEqualToConstant:30]
  ]];

  [self.view addSubview:self.operationView];
  [NSLayoutConstraint activateConstraints:@[
    [self.operationView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.operationView.heightAnchor constraintEqualToConstant:60],
    [self.operationView.widthAnchor constraintEqualToConstant:self.view.frame.size.width * 0.8],
    [self.operationView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor
                                                    constant:-50.0 * self.factor]
  ]];

  /// 未接通状态下的音视频切换按钮
  self.mediaSwitchBtn = [[NECustomButton alloc] init];
  self.mediaSwitchBtn.maskBtn.accessibilityIdentifier = @"inCallSwitch";

  [self.view addSubview:self.mediaSwitchBtn];
  [NSLayoutConstraint activateConstraints:@[
    [self.mediaSwitchBtn.centerXAnchor constraintEqualToAnchor:self.operationView.centerXAnchor],
    [self.mediaSwitchBtn.bottomAnchor constraintEqualToAnchor:self.operationView.topAnchor
                                                     constant:-150 * self.factor],
    [self.mediaSwitchBtn.heightAnchor constraintEqualToConstant:buttonSize.height],
    [self.mediaSwitchBtn.widthAnchor constraintEqualToConstant:buttonSize.width]
  ]];
  self.mediaSwitchBtn.hidden = YES;

  [self.mediaSwitchBtn.maskBtn addTarget:self
                                  action:@selector(mediaClick:)
                        forControlEvents:UIControlEventTouchUpInside];

  [self.view addSubview:self.timerLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.timerLabel.centerYAnchor constraintEqualToAnchor:self.switchCameraBtn.centerYAnchor],
    [self.timerLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor]
  ]];
}

#pragma mark - inner function

- (void)setCallingTypeSwith:(BOOL)show {
  if (show == YES && self.config.showCallingSwitchCallType == YES) {
    self.mediaSwitchBtn.hidden = NO;
  } else {
    self.mediaSwitchBtn.hidden = YES;
  }
}

- (void)setupChildController {
  if (self.isCaller == YES) {
    [self addChildViewController:self.videoCallingController];
    [self.view addSubview:self.videoCallingController.view];
    [self addChildViewController:self.audioCallingController];
    [self.view addSubview:self.audioCallingController.view];
  } else {
    [self addChildViewController:self.calledController];
    [self.view addSubview:self.calledController.view];
  }

  [self addChildViewController:self.audioInCallController];
  [self.view addSubview:self.audioInCallController.view];
  [self addChildViewController:self.videoInCallController];
  [self.view addSubview:self.videoInCallController.view];
}

- (void)setSwitchAudioStyle {
  self.mediaSwitchBtn.imageView.image = [UIImage imageNamed:@"switch_audio"
                                                   inBundle:self.bundle
                              compatibleWithTraitCollection:nil];
  self.mediaSwitchBtn.titleLabel.text = [self localizableWithKey:@"switch_to_audio"];
  self.mediaSwitchBtn.tag = NERtcCallTypeAudio;
  [self showVideoView];
  [self setUrl:self.callParam.remoteAvatar withPlaceholder:@"avator"];
  [self.stateUIController refreshUI];
}

- (void)setSwitchVideoStyle {
  self.mediaSwitchBtn.imageView.image = [UIImage imageNamed:@"switch_video"
                                                   inBundle:self.bundle
                              compatibleWithTraitCollection:nil];
  self.mediaSwitchBtn.titleLabel.text = [self localizableWithKey:@"switch_to_video"];
  self.mediaSwitchBtn.tag = NERtcCallTypeVideo;
  [self hideVideoView];
  [self setUrl:self.callParam.remoteAvatar withPlaceholder:@"avator"];
  [self.stateUIController refreshUI];
}

- (void)updateUIonStatus:(NERtcCallStatus)status {
  switch (status) {
    case NERtcCallStatusCalling: {
      [self setCallingTypeSwith:YES];
      self.operationView.hidden = YES;
      self.stateUIController.view.hidden = YES;
      if (self.callType == NERtcCallTypeVideo) {
        self.stateUIController = self.videoCallingController;
        [self.videoCallingController refreshUI];
        [self setSwitchAudioStyle];
      } else {
        self.stateUIController = self.audioCallingController;
        [self setSwitchVideoStyle];
      }
      self.stateUIController.view.hidden = NO;

    } break;
    case NERtcCallStatusCalled: {
      [self setCallingTypeSwith:YES];
      self.operationView.hidden = YES;
      self.stateUIController.view.hidden = YES;
      self.stateUIController = self.calledController;
      self.stateUIController.view.hidden = NO;
      [self.calledController refreshUI];
      if (self.callType == NERtcCallTypeVideo) {
        self.mediaSwitchBtn.imageView.image = [UIImage imageNamed:@"switch_audio"
                                                         inBundle:self.bundle
                                    compatibleWithTraitCollection:nil];
        self.mediaSwitchBtn.titleLabel.text = [self localizableWithKey:@"switch_to_audio"];
        [self setSwitchAudioStyle];
      } else {
        self.mediaSwitchBtn.imageView.image = [UIImage imageNamed:@"switch_video"
                                                         inBundle:self.bundle
                                    compatibleWithTraitCollection:nil];
        self.mediaSwitchBtn.titleLabel.text = [self localizableWithKey:@"switch_to_video"];
        [self setSwitchVideoStyle];
      }
      __weak typeof(self) weakSelf = self;
      [self.calledController.remoteBigAvatorView
          sd_setImageWithURL:[NSURL URLWithString:self.callParam.remoteAvatar]
                   completed:^(UIImage *_Nullable image, NSError *_Nullable error,
                               SDImageCacheType cacheType, NSURL *_Nullable imageURL) {
                     __strong typeof(self) strongSelf = weakSelf;
                     if (image == nil) {
                       image = [UIImage imageNamed:@"avator"
                                                inBundle:strongSelf.bundle
                           compatibleWithTraitCollection:nil];
                     }
                     if (strongSelf.isCaller == false &&
                         strongSelf.callType == NERtcCallTypeVideo) {
                       [strongSelf.blurImage setHidden:NO];
                     }
                     strongSelf.blurImage.image = image;
                   }];

    } break;
    case NERtcCallStatusInCall: {
      [self setCallingTypeSwith:NO];
      self.operationView.hidden = NO;
      self.stateUIController.view.hidden = YES;
      if (self.callType == NERtcCallTypeVideo) {
        self.stateUIController = self.videoInCallController;
        self.switchCameraBtn.hidden = NO;
        [self.videoInCallController refreshUI];
      } else {
        [self.operationView changeAudioStyle];
        self.stateUIController = self.audioInCallController;
      }
      self.stateUIController.view.hidden = NO;

    } break;
    default:
      break;
  }
  self.status = status;
}

- (void)showVideoView {
  if (self.status == NERtcCallStatusCalling) {
    [[NERtcCallKit sharedInstance]
        setupLocalView:self.videoCallingController.bigVideoView.videoView];
  }
  if (self.status == NERtcCallStatusInCall) {
    [[NERtcCallKit sharedInstance]
        setupLocalView:self.videoInCallController.smallVideoView.videoView];
    [[NERtcCallKit sharedInstance] setupRemoteView:self.videoInCallController.bigVideoView.videoView
                                           forUser:self.callParam.remoteUserAccid];
  }

  [[NERtcCallKit sharedInstance] muteLocalAudio:NO];
  [[NERtcCallKit sharedInstance] muteLocalVideo:NO];
  self.operationView.microPhone.selected = NO;
  self.operationView.cameraBtn.selected = NO;

  self.operationView.speakerBtn.selected = NO;
  self.operationView.microPhone.selected = NO;
  NSError *error;
  [[NERtcCallKit sharedInstance] setLoudSpeakerMode:YES error:&error];
  [[NERtcEngine sharedEngine] muteLocalAudio:NO];
}

- (void)hideVideoView {
  [[NERtcCallKit sharedInstance] setupLocalView:nil];
  [[NERtcCallKit sharedInstance] setupRemoteView:nil forUser:nil];
  self.operationView.speakerBtn.selected = YES;
  self.operationView.microPhone.selected = NO;
  NSError *error;
  [[NERtcCallKit sharedInstance] setLoudSpeakerMode:NO error:&error];
  [[NERtcEngine sharedEngine] muteLocalAudio:NO];
}

#pragma mark - event

- (void)closeEvent:(UIButton *)button {
  [[NERtcCallKit sharedInstance] hangup:^(NSError *_Nullable error){

  }];
}

- (void)cancelEvent:(UIButton *)button {
  __weak typeof(self) weakSelf = self;
  NSLog(@"cancel rtc");
  if ([[NetManager shareInstance] isClose] == YES) {
    [self destroy];
  }
  [[NERtcCallKit sharedInstance] cancel:^(NSError *_Nullable error) {
    NSLog(@"cancel error %@", error);
    button.enabled = YES;
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (error.code == 20016) {
      if ([UIApplication.sharedApplication respondsToSelector:@selector(keyWindow)]) {
        [UIApplication.sharedApplication.keyWindow
            makeToast:[strongSelf localizableWithKey:@"cancel_failed"]];
      }
    } else {
      [strongSelf destroy];
    }
  }];
}
- (void)rejectEvent:(UIButton *)button {
  if ([[NetManager shareInstance] isClose] == YES) {
    [self destroy];
  }
  self.calledController.acceptBtn.userInteractionEnabled = NO;
  __weak typeof(self) weakSelf = self;

  if ([[SettingManager shareInstance] rejectBusyCode] == YES) {
    [[NERtcCallKit sharedInstance]
        rejectWithReason:TerminalCodeBusy
          withCompletion:^(NSError *_Nullable error) {
            __strong typeof(self) strongSelf = weakSelf;
            strongSelf.calledController.acceptBtn.userInteractionEnabled = YES;
            [strongSelf destroy];
          }];
  } else {
    [[NERtcCallKit sharedInstance] reject:^(NSError *_Nullable error) {
      __strong typeof(self) strongSelf = weakSelf;
      strongSelf.calledController.acceptBtn.userInteractionEnabled = YES;
      [strongSelf destroy];
    }];
  }
}
- (void)acceptEvent:(UIButton *)button {
  if ([[NetManager shareInstance] isClose] == YES) {
    [self.view makeToast:[self localizableWithKey:@"network_error"]];
    return;
  }

  self.calledController.rejectBtn.userInteractionEnabled = NO;
  self.calledController.acceptBtn.userInteractionEnabled = NO;
  __weak typeof(self) weakSelf = self;

  [[NERtcCallKit sharedInstance]
      acceptWithToken:[[SettingManager shareInstance] customToken]
       withCompletion:^(NSError *_Nullable error) {
         __strong typeof(self) strongSelf = weakSelf;
         strongSelf.calledController.rejectBtn.userInteractionEnabled = YES;
         strongSelf.calledController.acceptBtn.userInteractionEnabled = YES;
         if (error) {
           if (error.code != 10420) {
             [UIApplication.sharedApplication.keyWindow
                 makeToast:[NSString
                               stringWithFormat:@"%@ %@",
                                                [strongSelf localizableWithKey:@"accept_failed"],
                                                error.localizedDescription]];
           }
           __weak typeof(self) weakSelf2 = strongSelf;
           dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                          dispatch_get_main_queue(), ^{
                            __strong typeof(self) strongSelf2 = weakSelf2;
                            [strongSelf2 destroy];
                          });
         } else {
           [[NERtcCallKit sharedInstance] memberOfAccid:@""
                                             completion:^(NIMSignalingMemberInfo *_Nullable info){

                                             }];
           [strongSelf updateUIonStatus:NERtcCallStatusInCall];
           [strongSelf startTimer];
         }
       }];
}
- (void)switchCameraBtn:(UIButton *)button {
  [[NERtcCallKit sharedInstance] switchCamera];
  button.selected = !button.selected;
  if (button.isSelected == YES) {
    [[NERtcEngine sharedEngine] setParameters:@{kNERtcKeyVideoStartWithBackCamera : @YES}];
  } else {
    [[NERtcEngine sharedEngine] setParameters:@{kNERtcKeyVideoStartWithBackCamera : @NO}];
  }
}
- (void)microPhoneClick:(UIButton *)button {
  button.selected = !button.selected;
  [[NERtcCallKit sharedInstance] muteLocalAudio:button.selected];
}
- (void)cameraBtnClick:(UIButton *)button {
  button.selected = !button.selected;
  NSLog(@"mute video select : %d", button.selected);
  if ([[SettingManager shareInstance] useEnableLocalMute] == YES) {
    NSLog(@"enableLocalVideo: %d", !button.selected);
    [[NERtcCallKit sharedInstance] enableLocalVideo:!button.selected];
  } else {
    [[NERtcCallKit sharedInstance] muteLocalVideo:button.selected];
  }
  [self changeDefaultImage:button.selected];
  [self cameraAvailble:!button.selected userId:self.callParam.currentUserAccid];
}
- (void)hangupBtnClick:(UIButton *)button {
  [[NERtcCallKit sharedInstance] hangup:^(NSError *_Nullable error){

  }];

  [self destroy];
}
- (void)microphoneBtnClick:(UIButton *)button {
  NSLog(@"micro phone btn click : %d", button.imageView.highlighted);
  self.audioCallingController.microphoneBtn.imageView.highlighted =
      !self.audioCallingController.microphoneBtn.imageView.highlighted;
  [[NERtcCallKit sharedInstance]
      muteLocalAudio:self.audioCallingController.microphoneBtn.imageView.highlighted];
  _operationView.microPhone.selected =
      self.audioCallingController.microphoneBtn.imageView.highlighted;
}
- (void)speakerBtnClick:(UIButton *)button {
  NSLog(@"speaker btn click : %d", self.audioCallingController.speakerBtn.imageView.highlighted);
  NSError *error = nil;

  [[NERtcCallKit sharedInstance]
      setLoudSpeakerMode:!self.audioCallingController.speakerBtn.imageView.highlighted
                   error:&error];
  if (error == nil) {
    self.audioCallingController.speakerBtn.imageView.highlighted =
        !self.audioCallingController.speakerBtn.imageView.highlighted;
    _operationView.speakerBtn.selected =
        !self.audioCallingController.speakerBtn.imageView.highlighted;
  } else {
    [self.view makeToast:error.description];
  }
}

- (void)operationSwitchClick:(UIButton *)btn {
  if ([[NetManager shareInstance] isClose] == YES) {
    [self.view makeToast:[self localizableWithKey:@"network_error"]];
    return;
  }
  __weak typeof(self) weakSelf = self;
  btn.enabled = NO;
  NERtcCallType type =
      self.callType == NERtcCallTypeVideo ? NERtcCallTypeAudio : NERtcCallTypeVideo;
  [[NERtcCallKit sharedInstance]
      switchCallType:type
           withState:NERtcSwitchStateInvite
          completion:^(NSError *_Nullable error) {
            __strong typeof(self) strongSelf = weakSelf;
            // weakSelf.mediaSwitchBtn.enabled = YES;
            btn.enabled = YES;
            if (error == nil) {
              NSLog(@"切换成功 : %lu", type);
              NSLog(@"switch : %d", btn.selected);
              if (type == NERtcCallTypeVideo && [SettingManager.shareInstance isVideoConfirm]) {
                [strongSelf showBannerView];
              } else if (type == NERtcCallTypeAudio &&
                         [SettingManager.shareInstance isAudioConfirm]) {
                [strongSelf showBannerView];
              }
            } else {
              [strongSelf.view
                  makeToast:[NSString
                                stringWithFormat:@"%@: %@",
                                                 [strongSelf localizableWithKey:@"switch_error"],
                                                 error]];
            }
          }];
}

- (void)operationSpeakerClick:(UIButton *)btn {
  NSError *error = nil;
  BOOL use;
  [[NERtcEngine sharedEngine] getLoudspeakerMode:&use];
  NSLog(@"get loud speaker %d", use);
  [[NERtcCallKit sharedInstance] setLoudSpeakerMode:btn.selected error:&error];
  if (error == nil) {
    btn.selected = !btn.selected;
  } else {
    [self.view makeToast:error.description];
  }
}

- (void)mediaClick:(UIButton *)btn {
  if ([[NetManager shareInstance] isClose] == YES) {
    [self.view makeToast:[self localizableWithKey:@"network_error"]];
    return;
  }
  __weak typeof(self) weakSelf = self;
  self.mediaSwitchBtn.maskBtn.enabled = NO;
  NERtcCallType type =
      weakSelf.callType == NERtcCallTypeVideo ? NERtcCallTypeAudio : NERtcCallTypeVideo;
  [[NERtcCallKit sharedInstance]
      switchCallType:type
           withState:NERtcSwitchStateInvite
          completion:^(NSError *_Nullable error) {
            __strong typeof(self) strongSelf = weakSelf;
            strongSelf.mediaSwitchBtn.maskBtn.enabled = YES;
            if (error == nil) {
              if (type == NERtcCallTypeVideo && [SettingManager.shareInstance isVideoConfirm]) {
                [strongSelf showBannerView];
              } else if (type == NERtcCallTypeAudio &&
                         [SettingManager.shareInstance isAudioConfirm]) {
                [strongSelf showBannerView];
              }
            } else {
              [strongSelf.view
                  makeToast:[NSString
                                stringWithFormat:@"%@ : %@",
                                                 [strongSelf localizableWithKey:@"switch_error"],
                                                 error]];
            }
          }];
}

#pragma mark - NERtcVideoCallDelegate

- (void)onDisconnect:(NSError *)reason {
  [self destroy];
}
- (void)onUserEnter:(NSString *)userID {
  [self updateUIonStatus:NERtcCallStatusInCall];
  [self startTimer];
  if ([[SettingManager shareInstance] incallShowCName] == YES &&
      [self.cnameLabel superview] == nil) {
    [self.view addSubview:self.cnameLabel];
    self.cnameLabel.text =
        [NSString stringWithFormat:@"cname: %@", [[SettingManager shareInstance] getRtcCName]];
    [NSLayoutConstraint activateConstraints:@[
      [self.cnameLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
      [self.cnameLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
  }
}
- (void)onUserCancel:(NSString *)userID {
  [[NERtcCallKit sharedInstance] hangup:^(NSError *_Nullable error){
  }];
  [UIApplication.sharedApplication.keyWindow makeToast:[self localizableWithKey:@"remote_cancel"]];
  [self destroy];
}
- (void)onCameraAvailable:(BOOL)available userID:(NSString *)userID {
  self.isRemoteMute = !available;
  [self cameraAvailble:available userId:userID];
}
- (void)onVideoMuted:(BOOL)muted userID:(NSString *)userID {
  self.isRemoteMute = muted;
  [self cameraAvailble:!muted userId:userID];
}
- (void)onUserLeave:(NSString *)userID {
  NSLog(@"onUserLeave");
  [self destroy];
}
- (void)onUserDisconnect:(NSString *)userID {
  NSLog(@"onUserDiconnect");
  [self destroy];
}
- (void)onCallingTimeOut {
  if ([[NetManager shareInstance] isClose] == YES) {
    [self destroy];
    return;
  }
  [UIApplication.sharedApplication.keyWindow makeToast:[self localizableWithKey:@"remote_timeout"]];
  [self destroy];
}
- (void)onUserBusy:(NSString *)userID {
  [UIApplication.sharedApplication.keyWindow makeToast:[self localizableWithKey:@"remote_busy"]];
  [self destroy];
}
- (void)onCallEnd {
  [self destroy];
}
- (void)onUserReject:(NSString *)userID {
  [UIApplication.sharedApplication.keyWindow makeToast:[self localizableWithKey:@"remote_reject"]];
  [self destroy];
}

- (void)onOtherClientAccept {
  [UIApplication.sharedApplication.keyWindow
      makeToast:[self localizableWithKey:@"other_client_accept"]];
  [self destroy];
}

- (void)onOtherClientReject {
  [UIApplication.sharedApplication.keyWindow
      makeToast:[self localizableWithKey:@"other_client_reject"]];
  [self destroy];
}

- (void)onCallTypeChange:(NERtcCallType)callType withState:(NERtcSwitchState)state {
  NSLog(@"onCallTypeChange: %lu withState: %lu", (unsigned long)callType, (unsigned long)state);
  switch (state) {
    case NERtcSwitchStateAgree:
      [self hideBannerView];
      [self onCallTypeChange:callType];
      break;
    case NERtcSwitchStateInvite: {
      if (self.alert != nil) {
        NSLog(@"alert is showing");
        return;
      }
      UIAlertController *alert = [UIAlertController
          alertControllerWithTitle:[self localizableWithKey:@"permission"]
                           message:callType == NERtcCallTypeVideo
                                       ? [self localizableWithKey:@"audio_to_video"]
                                       : [self localizableWithKey:@"video_to_audio"]
                    preferredStyle:UIAlertControllerStyleAlert];
      self.alert = alert;
      UIAlertAction *rejectAction =
          [UIAlertAction actionWithTitle:[self localizableWithKey:@"reject"]
                                   style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction *_Nonnull action) {
                                   [[NERtcCallKit sharedInstance]
                                       switchCallType:callType
                                            withState:NERtcSwitchStateReject
                                           completion:^(NSError *_Nullable error) {
                                             if (error) {
                                               [UIApplication.sharedApplication.keyWindow
                                                   makeToast:error.localizedDescription];
                                             }
                                           }];
                                 }];
      __weak typeof(self) weakSelf = self;
      UIAlertAction *agreeAction =
          [UIAlertAction actionWithTitle:[self localizableWithKey:@"agree"]
                                   style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction *_Nonnull action) {
                                   [[NERtcCallKit sharedInstance]
                                       switchCallType:callType
                                            withState:NERtcSwitchStateAgree
                                           completion:^(NSError *_Nullable error) {
                                             [weakSelf onCallTypeChange:callType];
                                             if (error) {
                                               [UIApplication.sharedApplication.keyWindow
                                                   makeToast:error.localizedDescription];
                                             }
                                           }];
                                 }];

      [alert addAction:rejectAction];
      [alert addAction:agreeAction];
      [self presentViewController:alert animated:YES completion:nil];

      NSLog(@"NERtcSwitchStateInvite : %ld", callType);

    }

    break;
    case NERtcSwitchStateReject:
      [self hideBannerView];
      [UIApplication.sharedApplication.keyWindow makeToast:[self localizableWithKey:@"reject_tip"]];
      break;
    default:
      break;
  }
  NSLog(@"onCallTypeChange : %lu  with state : %lu", callType, state);
}

- (void)onCallTypeChange:(NERtcCallType)callType {
  NSLog(@"onCallTypeChange:");
  if (self.callType == callType) {
    return;
  }
  self.callType = callType;
  [self updateUIonStatus:self.status];

  if (self.status == NERtcCallStatusInCall) {
    switch (callType) {
      case NERtcCallTypeAudio:
        NSLog(@"NERtcCallTypeAudio");
        [self.operationView changeAudioStyle];
        [self hideVideoView];
        break;
      case NERtcCallTypeVideo:
        NSLog(@"NERtcCallTypeVideo");
        [self.operationView changeVideoStyle];
        [self showVideoView];
        break;
      default:
        break;
    }
    return;
  }

  switch (callType) {
    case NERtcCallTypeAudio:
      [self.operationView changeAudioStyle];
      [self setSwitchVideoStyle];
      break;
    case NERtcCallTypeVideo:
      [self.operationView changeVideoStyle];
      [self setSwitchAudioStyle];
      break;
    default:
      break;
  }
}

- (void)onError:(NSError *)error {
  NSLog(@"call kit on error : %@", error);
}

- (void)onAudioAvailable:(BOOL)available userID:(NSString *)userID {
  NSLog(@"onAudioAvailable");
}

#pragma mark - private mothed
- (void)cameraAvailble:(BOOL)available userId:(NSString *)userId {
  if ([self.videoInCallController.bigVideoView.userID isEqualToString:userId]) {
    self.videoInCallController.bigVideoView.maskView.hidden = available;
    self.remoteCameraAvailable = available;
  }
  if ([self.videoInCallController.smallVideoView.userID isEqualToString:userId]) {
    self.videoInCallController.smallVideoView.maskView.hidden = available;
    self.remoteCameraAvailable = available;
  }
}

- (void)setUrl:(NSString *)url withPlaceholder:(NSString *)holder {
  __weak typeof(self) weakSelf = self;
  UIImageView *remoteAvatorView = nil;
  if (self.callType == NERtcCallTypeVideo) {
    remoteAvatorView = self.videoCallingController.remoteAvatorView;
  } else {
    remoteAvatorView = self.calledController.remoteBigAvatorView;
  }
  [remoteAvatorView
      sd_setImageWithURL:[NSURL URLWithString:url]
               completed:^(UIImage *_Nullable image, NSError *_Nullable error,
                           SDImageCacheType cacheType, NSURL *_Nullable imageURL) {
                 __strong typeof(self) strongSelf = weakSelf;
                 if (image == nil) {
                   image = [UIImage imageNamed:holder
                                            inBundle:strongSelf.bundle
                       compatibleWithTraitCollection:nil];
                 }
                 if (strongSelf.isCaller == false && strongSelf.callType == NERtcCallTypeVideo) {
                   [strongSelf.blurImage setHidden:NO];
                 }
                 strongSelf.blurImage.image = image;
               }];
}

- (void)startTimer {
  if (self.timer != nil) {
    return;
  }
  if (self.timerLabel.hidden == YES) {
    self.timerLabel.hidden = NO;
  }
  self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                target:self
                                              selector:@selector(figureTimer)
                                              userInfo:nil
                                               repeats:YES];
}

- (void)figureTimer {
  self.timerCount++;
  self.timerLabel.text = [self timeFormatted:self.timerCount];
}

- (NSString *)timeFormatted:(int)totalSeconds {
  if (totalSeconds < 3600) {
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
  }
  int seconds = totalSeconds % 60;
  int minutes = (totalSeconds / 60) % 60;
  int hours = totalSeconds / 3600;
  return [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds];
}

- (NSString *)getInviteText {
  return (self.callType == NERtcCallTypeAudio ? [self localizableWithKey:@"invite_audio_call"]
                                              : [self localizableWithKey:@"invite_video_call"]);
}

- (void)hideBannerView {
  self.bannerView.hidden = YES;
}

- (void)showBannerView {
  self.bannerView.hidden = NO;
}

#pragma mark - destroy
- (void)destroy {
  if (self.alert != nil) {
    [self.alert dismissViewControllerAnimated:NO completion:nil];
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:kCallKitDismissNoti object:nil];
  [[NERtcCallKit sharedInstance] removeDelegate:self];

  if (self.timer != nil) {
    [self.timer invalidate];
    self.timer = nil;
  }
}

#pragma mark - property

- (UILabel *)cnameLabel {
  if (_cnameLabel == nil) {
    _cnameLabel = [[UILabel alloc] init];
    _cnameLabel.textColor = [UIColor redColor];
    _cnameLabel.font = [UIFont systemFontOfSize:14];
    _cnameLabel.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _cnameLabel;
}

- (UIView *)bannerView {
  if (!_bannerView) {
    _bannerView = [[UIView alloc] init];
    _bannerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    _bannerView.clipsToBounds = YES;
    _bannerView.layer.cornerRadius = 4.0;
    _bannerView.hidden = YES;
    _bannerView.translatesAutoresizingMaskIntoConstraints = NO;

    NEExpandButton *closeBtn = [NEExpandButton buttonWithType:UIButtonTypeCustom];
    [_bannerView addSubview:closeBtn];
    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    closeBtn.backgroundColor = [UIColor clearColor];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeBtn setTitle:@"X" forState:UIControlStateNormal];
    [closeBtn addTarget:self
                  action:@selector(hideBannerView)
        forControlEvents:UIControlEventTouchUpInside];

    [NSLayoutConstraint activateConstraints:@[
      [closeBtn.topAnchor constraintEqualToAnchor:_bannerView.topAnchor],
      [closeBtn.bottomAnchor constraintEqualToAnchor:_bannerView.bottomAnchor],
      [closeBtn.rightAnchor constraintEqualToAnchor:_bannerView.rightAnchor],
      [closeBtn.widthAnchor constraintEqualToConstant:40]
    ]];

    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [_bannerView addSubview:label];
    label.textColor = [UIColor whiteColor];
    [NSLayoutConstraint activateConstraints:@[
      [label.leftAnchor constraintEqualToAnchor:self.bannerView.leftAnchor constant:10],
      [label.topAnchor constraintEqualToAnchor:self.bannerView.topAnchor],
      [label.rightAnchor constraintEqualToAnchor:closeBtn.leftAnchor constant:-10]
    ]];

    label.adjustsFontSizeToFitWidth = YES;
    label.text = [self localizableWithKey:@"waitting_remote_response"];
  }
  return _bannerView;
}

- (UIButton *)switchCameraBtn {
  if (!_switchCameraBtn) {
    _switchCameraBtn = [[UIButton alloc] init];
    [_switchCameraBtn setImage:[UIImage imageNamed:@"call_switch_camera"
                                                        inBundle:self.bundle
                                   compatibleWithTraitCollection:nil]
                      forState:UIControlStateNormal];
    [_switchCameraBtn addTarget:self
                         action:@selector(switchCameraBtn:)
               forControlEvents:UIControlEventTouchUpInside];
    _switchCameraBtn.translatesAutoresizingMaskIntoConstraints = NO;
    _switchCameraBtn.hidden = YES;
  }
  return _switchCameraBtn;
}

- (NEVideoOperationView *)operationView {
  if (!_operationView) {
    _operationView = [[NEVideoOperationView alloc] init];
    _operationView.translatesAutoresizingMaskIntoConstraints = NO;
    _operationView.layer.cornerRadius = 30;
    [_operationView.microPhone addTarget:self
                                  action:@selector(microPhoneClick:)
                        forControlEvents:UIControlEventTouchUpInside];
    [_operationView.cameraBtn addTarget:self
                                 action:@selector(cameraBtnClick:)
                       forControlEvents:UIControlEventTouchUpInside];
    [_operationView.hangupBtn addTarget:self
                                 action:@selector(hangupBtnClick:)
                       forControlEvents:UIControlEventTouchUpInside];
    [_operationView.mediaBtn addTarget:self
                                action:@selector(operationSwitchClick:)
                      forControlEvents:UIControlEventTouchUpInside];
    [_operationView.speakerBtn addTarget:self
                                  action:@selector(operationSpeakerClick:)
                        forControlEvents:UIControlEventTouchUpInside];
  }
  return _operationView;
}

- (UILabel *)timerLabel {
  if (nil == _timerLabel) {
    _timerLabel = [[UILabel alloc] init];
    _timerLabel.textColor = [UIColor whiteColor];
    _timerLabel.font = [UIFont systemFontOfSize:14.0];
    _timerLabel.textAlignment = NSTextAlignmentCenter;
    _timerLabel.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _timerLabel;
}

- (void)dealloc {
  [[NERtcCallKit sharedInstance] removeDelegate:self];
}

- (void)hideViews:(NSArray<UIView *> *)views {
  for (UIView *view in views) {
    [view setHidden:YES];
  }
}

- (void)showViews:(NSArray<UIView *> *)views {
  for (UIView *view in views) {
    [view setHidden:NO];
  }
}

- (void)changeDefaultImage:(BOOL)mute {
  // TODO: 代码整理
  /*
   UIImage *image = [[SettingManager shareInstance] muteDefaultImage];
   if (image != nil) {
   if (mute == YES) {
   if (self.showMyBigView) {
   self.bigVideoView.imageView.image = image;
   self.bigVideoView.imageView.hidden = NO;
   [self changeRemoteMute:self.isRemoteMute videoView:self.smallVideoView];
   } else {
   self.smallVideoView.imageView.image = image;
   self.smallVideoView.imageView.hidden = NO;
   [self changeRemoteMute:self.isRemoteMute videoView:self.bigVideoView];
   }
   } else {
   if (self.showMyBigView) {
   self.bigVideoView.imageView.image = nil;
   self.bigVideoView.imageView.hidden = YES;
   self.smallVideoView.imageView.hidden = YES;
   [self changeRemoteMute:self.isRemoteMute videoView:self.smallVideoView];
   } else {
   self.smallVideoView.imageView.image = nil;
   self.smallVideoView.imageView.hidden = YES;
   [self changeRemoteMute:self.isRemoteMute videoView:self.bigVideoView];
   }
   }
   } */
}

- (void)changeRemoteMute:(BOOL)mute videoView:(NEVideoView *)remoteVideo {
  UIImage *defaultImage = [[SettingManager shareInstance] remoteDefaultImage];
  if (mute == true && defaultImage != nil) {
    remoteVideo.imageView.hidden = NO;
    remoteVideo.imageView.image = defaultImage;
  } else {
    remoteVideo.imageView.hidden = YES;
  }
}

- (NEAudioCallingController *)audioCallingController {
  if (nil == _audioCallingController) {
    _audioCallingController =
        (NEAudioCallingController *)[self getCallStateInstanceWithClassKey:kAudioCalling];
  }
  if (nil == _audioCallingController) {
    _audioCallingController = [[NEAudioCallingController alloc] init];
    _audioCallingController.isCaller = self.isCaller;
    _audioCallingController.callParam = self.callParam;
    _audioCallingController.callType = self.callType;
    _audioCallingController.mainController = self;
    _audioCallingController.view.hidden = YES;
  }

  return _audioCallingController;
}

- (NEAudioInCallController *)audioInCallController {
  if (nil == _audioInCallController) {
    _audioInCallController =
        (NEAudioInCallController *)[self getCallStateInstanceWithClassKey:kAudioInCall];
  }
  if (nil == _audioInCallController) {
    _audioInCallController = [[NEAudioInCallController alloc] init];
    _audioInCallController.isCaller = self.isCaller;
    _audioInCallController.callParam = self.callParam;
    _audioInCallController.callType = self.callType;
    _audioInCallController.mainController = self;
    _audioInCallController.view.hidden = YES;
  }
  return _audioInCallController;
}

- (NEVideoCallingController *)videoCallingController {
  if (nil == _videoCallingController) {
    _videoCallingController =
        (NEVideoCallingController *)[self getCallStateInstanceWithClassKey:kVideoCalling];
  }
  if (nil == _videoCallingController) {
    _videoCallingController = [[NEVideoCallingController alloc] init];
    _videoCallingController.isCaller = self.isCaller;
    _videoCallingController.callParam = self.callParam;
    _videoCallingController.callType = self.callType;
    _videoCallingController.mainController = self;
    _videoCallingController.view.hidden = YES;
  }
  return _videoCallingController;
}

- (NEVideoInCallController *)videoInCallController {
  if (nil == _videoInCallController) {
    _videoInCallController =
        (NEVideoInCallController *)[self getCallStateInstanceWithClassKey:kVideoInCall];
  }
  if (nil == _videoInCallController) {
    _videoInCallController = [[NEVideoInCallController alloc] init];
    _videoInCallController.isCaller = self.isCaller;
    _videoInCallController.callParam = self.callParam;
    _videoInCallController.callType = self.callType;
    _videoInCallController.mainController = self;
    _videoInCallController.view.hidden = YES;
  }
  return _videoInCallController;
}

- (NECalledViewController *)calledController {
  if (nil == _calledController) {
    _calledController =
        (NECalledViewController *)[self getCallStateInstanceWithClassKey:kCalledState];
  }
  if (nil == _calledController) {
    _calledController = [[NECalledViewController alloc] init];
    _calledController.isCaller = self.isCaller;
    _calledController.callParam = self.callParam;
    _calledController.callType = self.callType;
    _calledController.mainController = self;
    _calledController.view.hidden = YES;
  }
  return _calledController;
}

#pragma mark - common fuction

- (NECallUIStateController *)getCallStateInstanceWithClassKey:(NSString *)key {
  Class cls = [self.uiConfigDic objectForKey:key];
  if (nil != cls) {
    NECallUIStateController *controller = [[cls alloc] init];
    controller.isCaller = self.isCaller;
    controller.callParam = self.callParam;
    controller.callType = self.callType;
    controller.mainController = self;
    controller.view.hidden = YES;
    return controller;
  }
  return nil;
}

- (UIView *)getDefaultHeaderView:(NSString *)accid
                            font:(UIFont *)font
                        showName:(NSString *)showName {
  UIView *headerView = [[UIView alloc] init];
  headerView.backgroundColor = [UIColor colorWithStringWithString:accid];
  headerView.translatesAutoresizingMaskIntoConstraints = NO;
  NSString *show = showName.length > 0 ? showName : accid;
  if (show.length >= 2) {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [headerView addSubview:label];
    label.textColor = [UIColor whiteColor];
    label.font = font;
    label.text = [show substringWithRange:NSMakeRange(show.length - 2, 2)];
    [NSLayoutConstraint activateConstraints:@[
      [label.centerYAnchor constraintEqualToAnchor:headerView.centerYAnchor],
      [label.centerXAnchor constraintEqualToAnchor:headerView.centerXAnchor]
    ]];
  }
  return headerView;
}

- (NSString *)localizableWithKey:(NSString *)key {
  return [self.bundle localizedStringForKey:key value:nil table:@"Localizable"];
  ;
}
@end
