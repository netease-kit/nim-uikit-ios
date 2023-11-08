// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NECallViewBaseController.h"
#import <NECommonKit/NECommonKit-Swift.h>
#import <NECommonUIKit/UIView+YXToast.h>
#import <SDWebImage/SDWebImage.h>
#import "NECallKitUtil.h"
#import "NERtcCallUIKit.h"

@interface NECallViewBaseController ()

@property(nonatomic, assign) BOOL isPlaying;

@property(nonatomic, assign) CallRingType ringType;

@property(nonatomic, assign) BOOL isReceiver;

@end

@implementation NECallViewBaseController

- (instancetype)init {
  self = [super init];
  if (self) {
    // 获取屏幕宽高
    UIScreen *screen = [UIScreen mainScreen];
    self.screenWidth = screen.bounds.size.width;
    self.screenHeight = screen.bounds.size.height;
    self.floatMargin = 10;
    self.bundle = [NSBundle bundleForClass:NECallViewBaseController.class];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:AVAudioSessionSilenceSecondaryAudioHintNotification
              object:nil];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  if (self.isPlaying && self.ringType == CRTCallerRing) {
    [self stopCurrentPlaying];
  }
}

- (void)setupSmallWindown {
  [self.view addSubview:self.recoveryView];
  [NSLayoutConstraint activateConstraints:@[
    [self.recoveryView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.recoveryView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.recoveryView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.recoveryView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
  ]];
  [self.view addGestureRecognizer:self.panGesture];
  self.view.clipsToBounds = YES;

  [self.view addSubview:self.maskView];
  [NSLayoutConstraint activateConstraints:@[
    [self.maskView.topAnchor constraintEqualToAnchor:self.recoveryView.topAnchor],
    [self.maskView.leftAnchor constraintEqualToAnchor:self.recoveryView.leftAnchor],
    [self.maskView.rightAnchor constraintEqualToAnchor:self.recoveryView.rightAnchor],
    [self.maskView.bottomAnchor constraintEqualToAnchor:self.recoveryView.bottomAnchor]
  ]];

  [self.maskView addSubview:self.remoteHeaderImage];
  [NSLayoutConstraint activateConstraints:@[
    [self.remoteHeaderImage.centerXAnchor constraintEqualToAnchor:self.maskView.centerXAnchor],
    [self.remoteHeaderImage.centerYAnchor constraintEqualToAnchor:self.maskView.centerYAnchor],
    [self.remoteHeaderImage.widthAnchor constraintEqualToConstant:42],
    [self.remoteHeaderImage.heightAnchor constraintEqualToConstant:42]
  ]];

  [self.recoveryView addSubview:self.audioSmallView];
  [NSLayoutConstraint activateConstraints:@[
    [self.audioSmallView.leftAnchor constraintEqualToAnchor:self.recoveryView.leftAnchor],
    [self.audioSmallView.topAnchor constraintEqualToAnchor:self.recoveryView.topAnchor],
    [self.audioSmallView.bottomAnchor constraintEqualToAnchor:self.recoveryView.bottomAnchor],
    [self.audioSmallView.rightAnchor constraintEqualToAnchor:self.recoveryView.rightAnchor]
  ]];

  UIImage *callImage = [UIImage imageNamed:@"phone_image"
                                  inBundle:self.bundle
             compatibleWithTraitCollection:nil];

  UIImageView *callImageView = [[UIImageView alloc] initWithImage:callImage];
  callImageView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.audioSmallView addSubview:callImageView];
  [NSLayoutConstraint activateConstraints:@[
    [callImageView.centerXAnchor constraintEqualToAnchor:self.audioSmallView.centerXAnchor],
    [callImageView.topAnchor constraintEqualToAnchor:self.audioSmallView.topAnchor constant:11]
  ]];

  [self.audioSmallView addSubview:self.audioSmallViewTimerLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.audioSmallViewTimerLabel.centerXAnchor
        constraintEqualToAnchor:self.audioSmallView.centerXAnchor],
    [self.audioSmallViewTimerLabel.bottomAnchor
        constraintEqualToAnchor:self.audioSmallView.bottomAnchor
                       constant:-15],
    [self.audioSmallViewTimerLabel.leftAnchor constraintEqualToAnchor:self.audioSmallView.leftAnchor
                                                             constant:3],
    [self.audioSmallViewTimerLabel.rightAnchor
        constraintEqualToAnchor:self.audioSmallView.rightAnchor
                       constant:-3]
  ]];

  [self.remoteHeaderImage sd_setImageWithURL:[NSURL URLWithString:self.callParam.remoteAvatar]
                            placeholderImage:[UIImage imageNamed:@"avator"
                                                                      inBundle:self.bundle
                                                 compatibleWithTraitCollection:nil]];
}

- (void)showToastWithContent:(NSString *)content {
  if (self.callParam.enableShowRecorderToast == NO) {
    return;
  }
  if (content.length <= 0) {
    return;
  }

  [self.preiousWindow ne_makeToast:content];
}

- (BOOL)isJoinRtcWhenCall {
  BOOL enableJoinWhenCall =
      [[[NECallEngine sharedInstance] valueForKeyPath:@"context.joinRtcWhenCall"] boolValue];

  return enableJoinWhenCall;
}

- (void)changeToSmall {
  [[NERtcCallUIKit sharedInstance] changeSmallModeWithTyple:self.callParam.callType];
  self.recoveryView.hidden = NO;
  self.panGesture.enabled = YES;
  if (self.callParam.callType == NECallTypeVideo) {
    [[NECallEngine sharedInstance] setupRemoteView:self.recoveryView];
    self.audioSmallView.hidden = YES;
    self.view.layer.cornerRadius = 0;
    if (self.isRemoteMute == YES) {
      self.maskView.hidden = NO;
    }
  } else {
    self.audioSmallView.hidden = NO;
    self.view.layer.cornerRadius = 6;
  }
  self.isSmallWindow = YES;
}

- (void)changeToNormal {
  [[NERtcCallUIKit sharedInstance] restoreNormalMode];
  self.recoveryView.hidden = YES;
  self.panGesture.enabled = NO;
  self.isSmallWindow = NO;
  self.view.layer.cornerRadius = 0;
  self.maskView.hidden = YES;
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
  if (gesture.state == UIGestureRecognizerStateChanged) {
    CGPoint translation = [gesture translationInView:self.view];
    self.view.transform =
        CGAffineTransformTranslate(self.view.transform, translation.x, translation.y);
    [gesture setTranslation:CGPointZero inView:self.view];
  } else if (gesture.state == UIGestureRecognizerStateCancelled ||
             gesture.state == UIGestureRecognizerStateEnded ||
             gesture.state == UIGestureRecognizerStateFailed ||
             gesture.state == UIGestureRecognizerStateRecognized) {
    CGPoint point = CGPointZero;
    if (gesture.view.frame.origin.x + gesture.view.frame.size.width / 2.0 <
        self.screenWidth / 2.0) {
      point.x = self.floatMargin;
    } else {
      point.x = self.screenWidth - self.floatMargin - gesture.view.frame.size.width;
    }
    if (gesture.view.frame.origin.y - self.floatMargin <= 0) {
      point.y = self.floatMargin;
    } else if (gesture.view.frame.origin.y + gesture.view.frame.size.height + self.floatMargin >
               self.screenHeight) {
      point.y = self.screenHeight - gesture.view.frame.size.height - self.floatMargin;
    } else {
      point.y = gesture.view.frame.origin.y;
    }
    [UIView animateWithDuration:0.5
                     animations:^{
                       gesture.view.frame =
                           CGRectMake(point.x, point.y, gesture.view.frame.size.width,
                                      gesture.view.frame.size.height);
                     }];
  }
}

#pragma mark - call ring play

- (void)playRingWithType:(CallRingType)ringType {
  if ([self isJoinRtcWhenCall]) {
    return;
  }
  self.isPlaying = YES;
  self.ringType = ringType;
  [[NERingPlayerManager shareInstance] playRingWithRingType:ringType isRtcPlay:NO];
}

- (void)stopCurrentPlaying {
  if ([self isJoinRtcWhenCall]) {
    return;
  }
  self.isPlaying = NO;
  [[NERingPlayerManager shareInstance] stopCurrentPlaying];
}

// 设置声音设置输出到听筒
- (void)setAudioOutputToReceiver {
  AVAudioSession *session = [AVAudioSession sharedInstance];
  [session setCategory:AVAudioSessionCategoryPlayAndRecord
           withOptions:AVAudioSessionCategoryOptionAllowBluetooth |
                       AVAudioSessionCategoryOptionAllowBluetoothA2DP
                 error:nil];
  [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
  [session setActive:YES error:nil];
  self.isReceiver = YES;
}

// 设置声音输出到扬声器
- (void)setAudioOutputToSpeaker {
  AVAudioSession *session = [AVAudioSession sharedInstance];
  [session setCategory:AVAudioSessionCategoryPlayback
           withOptions:AVAudioSessionCategoryOptionAllowBluetooth |
                       AVAudioSessionCategoryOptionAllowBluetoothA2DP

                 error:nil];
  [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
  [session setActive:YES error:nil];
  self.isReceiver = NO;
}

- (void)handleInterruption:(NSNotification *)notification {
  NSDictionary *userInfo = notification.userInfo;
  if (userInfo == nil) {
    return;
  }

  AVAudioSessionInterruptionType type =
      [[userInfo valueForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
  switch (type) {
    case AVAudioSessionInterruptionTypeBegan:
      // 中断开始，暂停播放

      break;
    case AVAudioSessionInterruptionTypeEnded: {
      NERtcCallStatus status = NECallEngine.sharedInstance.callStatus;
      if (self.isPlaying == YES && status != NECallStatusIdle) {
        NSLog(@"handleInterruption playRingWithType happen");
        if (self.isReceiver == YES) {
          [self setAudioOutputToReceiver];
        } else {
          [self setAudioOutputToSpeaker];
        }
        [self playRingWithType:self.ringType];
      }
    } break;
    default:
      break;
  }
}

#pragma mark - lazy init

- (UIView *)maskView {
  if (_maskView == nil) {
    // 实现一个渐变颜色的UIView
    _maskView = [[UIView alloc] init];
    _maskView.translatesAutoresizingMaskIntoConstraints = NO;
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = @[
      (__bridge id)[NECallKitUtil colorWithHexString:@"#232529"].CGColor,
      (__bridge id)[NECallKitUtil colorWithHexString:@"#5E6471"].CGColor
    ];
    gradientLayer.locations = @[ @0.0, @1.0 ];
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(0, 1);
    gradientLayer.frame = CGRectMake(0, 0, 90, 160);
    [_maskView.layer addSublayer:gradientLayer];
    _maskView.hidden = YES;
    // 添加点击手势
    UITapGestureRecognizer *tap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeToNormal)];
    [_maskView addGestureRecognizer:tap];
  }
  return _maskView;
}

- (UIImageView *)remoteHeaderImage {
  if (_remoteHeaderImage == nil) {
    _remoteHeaderImage = [[UIImageView alloc] init];
    _remoteHeaderImage.translatesAutoresizingMaskIntoConstraints = NO;
    _remoteHeaderImage.contentMode = UIViewContentModeScaleAspectFit;
    _remoteHeaderImage.clipsToBounds = YES;
    _remoteHeaderImage.layer.cornerRadius = 4.0;
  }
  return _remoteHeaderImage;
}

- (UIView *)recoveryView {
  if (!_recoveryView) {
    _recoveryView = [[UIView alloc] init];
    _recoveryView.translatesAutoresizingMaskIntoConstraints = NO;
    _recoveryView.backgroundColor = [UIColor clearColor];
    _recoveryView.hidden = YES;

    UITapGestureRecognizer *tap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeToNormal)];
    [_recoveryView addGestureRecognizer:tap];
  }
  return _recoveryView;
}

- (UIPanGestureRecognizer *)panGesture {
  if (!_panGesture) {
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    _panGesture.enabled = NO;
  }
  return _panGesture;
}

- (UIView *)audioSmallView {
  if (_audioSmallView == nil) {
    _audioSmallView = [[UIView alloc] init];
    _audioSmallView.translatesAutoresizingMaskIntoConstraints = NO;
    _audioSmallView.backgroundColor = UIColor.whiteColor;
    _audioSmallView.hidden = YES;
  }
  return _audioSmallView;
}

- (UILabel *)audioSmallViewTimerLabel {
  if (_audioSmallViewTimerLabel == nil) {
    _audioSmallViewTimerLabel = [[UILabel alloc] init];
    _audioSmallViewTimerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _audioSmallViewTimerLabel.textColor = [NECallKitUtil colorWithHexString:@"#1BBF52"];
    _audioSmallViewTimerLabel.adjustsFontSizeToFitWidth = YES;
    _audioSmallViewTimerLabel.textAlignment = NSTextAlignmentCenter;
  }
  return _audioSmallViewTimerLabel;
}

- (UIWindow *)preiousWindow {
  return [[NERtcCallUIKit sharedInstance] valueForKey:@"preiousKeywindow"];
}

@end
