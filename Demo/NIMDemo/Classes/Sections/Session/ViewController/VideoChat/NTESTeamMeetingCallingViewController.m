//
//  NTESTeamMeetingCallingViewController.m
//  NIM
//
//  Created by chris on 2017/5/3.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import "NTESTeamMeetingCallingViewController.h"
#import "NTESTeamMeetingViewController.h"
#import "NTESTeamMeetingCalleeInfo.h"
#import "NTESTimerHolder.h"
#import "UIView+Toast.h"
#import "UIAlertView+NTESBlock.h"
#import <AVFoundation/AVFoundation.h>


//激活铃声后无人接听的超时时间
#define NTESTeamMeegingNoBodyResponseTimeOut 45

@interface NTESTeamMeetingCallingViewController ()<NTESTimerHolderDelegate>

@property (nonatomic,strong) NTESTeamMeetingCalleeInfo *info;

@property (nonatomic,strong) NTESTimerHolder *timer;

@property (nonatomic,strong) AVAudioPlayer *player; //播放提示音

@end

@implementation NTESTeamMeetingCallingViewController

- (instancetype)initWithCalleeInfo:(NTESTeamMeetingCalleeInfo *)info
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        _info  = info;
        _timer = [[NTESTimerHolder alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *teamName = self.info.teamName;
    teamName = teamName? teamName : [[NIMSDK sharedSDK].teamManager teamById:self.info.teamId].teamName;
    self.nameLabel.text = [NSString stringWithFormat:@"%@的视频通话",teamName];
    [self.timer startTimer:NTESTeamMeegingNoBodyResponseTimeOut delegate:self repeats:NO];
    [self checkServiceEnable:^(BOOL enable) {
        if (!enable)
        {
            [self dismiss];
        }
        else
        {
            [self ring];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarHidden = NO;
    [self.player stop];
}

#pragma mark - NTESTimerHolderDelegate
- (void)onNTESTimerFired:(NTESTimerHolder *)holder
{
    [self.presentingViewController.view makeToast:@"接听超时"
                                     duration:2
                                     position:CSToastPositionCenter];
    [self dismiss];
}


#pragma mark - IBAction
- (IBAction)hangup:(id)sender
{
    [self dismiss];
}

- (IBAction)connect:(id)sender
{
    NTESTeamMeetingViewController *vc = [[NTESTeamMeetingViewController alloc] initWithCalleeInfo:self.info];
    UIViewController *presentingViewController = self.presentingViewController;
    [self dismissViewControllerAnimated:NO completion:^{
        [presentingViewController presentViewController:vc animated:NO completion:nil];
    }];
}

#pragma mark - Private
- (void)dismiss
{
    [self dismissViewControllerAnimated:NO completion:nil];
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


//铃声 - 接收方铃声
- (void)ring
{
    [self.player stop];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"video_chat_tip_receiver" withExtension:@"aac"];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.player.numberOfLoops = 30;
    [self.player play];
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
