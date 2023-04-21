// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NERtcCallUIKit.h"
#import <NECoreKit/NECoreKit-Swift.h>
#import <NECoreKit/XKit.h>
#import <Toast/Toast.h>
#import "NetManager.h"

NSString *kAudioCalling = @"kAudioCalling";

NSString *kVideoCalling = @"kVideoCalling";

NSString *kAudioInCall = @"kAudioInCall";

NSString *kVideoInCall = @"kVideoInCall";

NSString *kCalledState = @"kCalledState";

NSString *kMouldName = @"NERtcCallUIKit";

@interface NERtcCallUIKit () <NERtcCallKitDelegate, XKitService>

@property(nonatomic, strong) NERtcCallUIConfig *config;

@property(nonatomic, strong) UIWindow *keywindow;

@property(nonatomic, strong, readwrite) NSMutableDictionary *uiConfigDic;

@property(nonatomic, strong) NSBundle *bundle;

@end

@implementation NERtcCallUIKit

+ (instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static NERtcCallUIKit *instance;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (NSString *)serviceName {
  return kMouldName;
}

- (NSString *)versionName {
  return [NERtcCallUIKit version];
}

- (NSString *)appKey {
  return self.config.appKey;
}

- (void)setupWithConfig:(NERtcCallUIConfig *)config {
  if (nil != config.option && config.appKey != nil) {
    [[NERtcCallKit sharedInstance] setupAppKey:config.appKey options:config.option];
  }
  [[XKit instance] registerService:self];
  self.config = config;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    [NetManager shareInstance];
    [[NERtcCallKit sharedInstance] addDelegate:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didDismiss:)
                                                 name:kCallKitDismissNoti
                                               object:nil];
    self.uiConfigDic = [[NSMutableDictionary alloc] init];
    [self.uiConfigDic setObject:NEAudioCallingController.class forKey:kAudioCalling];
    [self.uiConfigDic setObject:NEAudioInCallController.class forKey:kAudioInCall];
    [self.uiConfigDic setObject:NEVideoCallingController.class forKey:kVideoCalling];
    [self.uiConfigDic setObject:NEVideoInCallController.class forKey:kVideoInCall];
    [self registerRouter];
    [NERtcCallKit sharedInstance].recordHandler = ^(NIMMessage *message) {
      if ([[NetManager shareInstance] isClose] == YES) {
        NIMRtcCallRecordObject *object = (NIMRtcCallRecordObject *)message.messageObject;
        object.callStatus = NIMRtcCallStatusCanceled;
      }
    };
    self.bundle = [NSBundle bundleForClass:self.class];
  }
  return self;
}

- (NSString *)localizableWithKey:(NSString *)key {
  return [self.bundle localizedStringForKey:key value:nil table:@"Localizable"];
}

- (void)registerRouter {
  [[Router shared] register:@"imkit://callkit.page"
                    closure:^(NSDictionary<NSString *, id> *_Nonnull param) {
                      if ([[NetManager shareInstance] isClose] == YES) {
                        [UIApplication.sharedApplication.keyWindow
                            makeToast:[self localizableWithKey:@"network_error"]];
                        return;
                      }
                      NECallParam *callParam = [[NECallParam alloc] init];
                      callParam.currentUserAccid = [param objectForKey:@"currentUserAccid"];
                      callParam.remoteUserAccid = [param objectForKey:@"remoteUserAccid"];
                      callParam.remoteShowName = [param objectForKey:@"remoteShowName"];
                      callParam.remoteAvatar = [param objectForKey:@"remoteAvatar"];
                      NSNumber *type = [param objectForKey:@"type"];
                      NERtcCallType callType = NERtcCallTypeAudio;
                      if (type.intValue == 1) {
                        callType = NERtcCallTypeAudio;
                      } else if (type.intValue == 2) {
                        callType = NERtcCallTypeVideo;
                      }
                      [self callWithParam:callParam withCallType:callType];
                    }];
}

- (void)callWithParam:(NECallParam *)callParam withCallType:(NERtcCallType)callType {
  NECallViewController *callVC = [[NECallViewController alloc] init];
  if (callParam.remoteShowName.length <= 0) {
    callParam.remoteShowName = callParam.remoteUserAccid;
  }
  callVC.isCaller = YES;
  callVC.callType = callType;
  callVC.status = NERtcCallStatusCalling;
  callVC.callParam = callParam;
  callVC.uiConfigDic = self.uiConfigDic;
  callVC.config = self.config.uiConfig;
  [self showCallView:callVC];
}

- (void)onInvited:(NSString *)invitor
          userIDs:(NSArray<NSString *> *)userIDs
      isFromGroup:(BOOL)isFromGroup
          groupID:(NSString *)groupID
             type:(NERtcCallType)type
       attachment:(NSString *)attachment {
  if (self.config.uiConfig.disableShowCalleeView == YES) {
    return;
  }

  [NIMSDK.sharedSDK.userManager
      fetchUserInfos:@[ invitor ]
          completion:^(NSArray<NIMUser *> *_Nullable users, NSError *_Nullable error) {
            if (error) {
              [UIApplication.sharedApplication.keyWindow makeToast:error.description];
              return;
            } else {
              NIMUser *imUser = users.firstObject;
              NECallViewController *callVC = [[NECallViewController alloc] init];
              NECallParam *callParam = [[NECallParam alloc] init];
              callParam.remoteUserAccid = imUser.userId;
              callParam.remoteShowName = self.config.uiConfig.calleeShowPhone == YES
                                             ? imUser.userInfo.mobile
                                             : imUser.userInfo.nickName;
              callParam.remoteAvatar = imUser.userInfo.avatarUrl;
              callParam.currentUserAccid = NIMSDK.sharedSDK.loginManager.currentAccount;
              callVC.callParam = callParam;
              callVC.isCaller = NO;
              callVC.status = NERtcCallStatusCalled;
              callVC.callType = type;
              callVC.uiConfigDic = self.uiConfigDic;
              callVC.config = self.config.uiConfig;
              [self showCallView:callVC];
            }
          }];
}

- (void)showCalled:(NIMUser *)imUser
          callType:(NERtcCallType)type
        attachment:(NSString *)attachment {
  NECallViewController *callVC = [[NECallViewController alloc] init];
  NECallParam *callParam = [[NECallParam alloc] init];
  callParam.remoteUserAccid = imUser.userId;
  callParam.remoteShowName = imUser.userInfo.mobile;
  callParam.remoteAvatar = imUser.userInfo.avatarUrl;
  callParam.currentUserAccid = NIMSDK.sharedSDK.loginManager.currentAccount;
  callVC.callParam = callParam;
  callVC.isCaller = NO;
  callVC.status = NERtcCallStatusCalled;
  callVC.callType = type;
  callVC.uiConfigDic = self.uiConfigDic;
  callVC.config = self.config.uiConfig;
  [self showCallView:callVC];
}

- (void)showCallView:(UIViewController *)callVC {
  UINavigationController *nav = [self getKeyWindowNav];
  UINavigationController *callNav =
      [[UINavigationController alloc] initWithRootViewController:callVC];
  callNav.modalPresentationStyle = UIModalPresentationFullScreen;
  [callNav.navigationBar setHidden:YES];
  [nav presentViewController:callNav animated:YES completion:nil];
}

- (UINavigationController *)getKeyWindowNav {
  UIWindow *window = [[UIWindow alloc] init];
  window.frame = [[UIScreen mainScreen] bounds];
  window.windowLevel = UIWindowLevelStatusBar - 1;
  UIViewController *root = [[UIViewController alloc] init];
  root.view.backgroundColor = [UIColor clearColor];
  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:root];
  nav.navigationBar.tintColor = [UIColor clearColor];
  nav.view.backgroundColor = [UIColor clearColor];
  [nav.navigationBar setHidden:YES];
  self.keywindow = window;
  window.rootViewController = nav;
  window.backgroundColor = [UIColor clearColor];
  [window makeKeyAndVisible];
  return nav;
}

- (void)didDismiss:(NSNotification *)noti {
  UINavigationController *nav = (UINavigationController *)self.keywindow.rootViewController;
  __weak typeof(self) weakSelf = self;
  [nav dismissViewControllerAnimated:YES
                          completion:^{
                            __strong typeof(self) strongSelf = weakSelf;
                            NSLog(@"self window %@", strongSelf.keywindow);
                            [strongSelf.keywindow resignKeyWindow];
                            strongSelf.keywindow = nil;
                          }];
}

+ (NSString *)version {
  return @"1.8.2";
}

@end
