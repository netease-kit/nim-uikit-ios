//
//  NTESVideoViewController.m
//  NIM
//
//  Created by chris on 15/4/12.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESVideoViewController.h"
#import "UIView+Toast.h"
#import "Reachability.h"
#import "UIAlertView+NTESBlock.h"
#import "SVProgressHUD.h"
#import "NTESNavigationHandler.h"

@interface NTESVideoViewController ()

@property (nonatomic,strong) NIMVideoObject *videoObject;

@end

@implementation NTESVideoViewController
@synthesize moviePlayer = _moviePlayer;

- (instancetype)initWithVideoObject:(NIMVideoObject *)videoObject{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _videoObject = videoObject;
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NIMSDK sharedSDK].resourceManager cancelTask:_videoObject.path];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.navigationItem.title = @"视频短片";
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.videoObject.path]) {
        [self startPlay];
    }else{
        __weak typeof(self) wself = self;
        [self downLoadVideo:^(NSError *error) {
            if (!error) {
                [wself startPlay];
            }else{
                [wself.view makeToast:@"下载失败，请检查网络"
                             duration:2
                             position:CSToastPositionCenter];
            }
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear: animated];
    [SVProgressHUD dismiss];
    if (![[self.navigationController viewControllers] containsObject: self])
    {
        [self topStatusUIHidden:NO];
    }
}


- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.moviePlayer stop];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear: animated];
    if (_moviePlayer.playbackState == MPMoviePlaybackStatePlaying) {//不要调用.get方法，会过早的初始化播放器
        [self topStatusUIHidden:YES];
    }else{
        [self topStatusUIHidden:NO];
    }
}



- (void)downLoadVideo:(void(^)(NSError *error))handler{
    [SVProgressHUD show];
    __weak typeof(self) wself = self;
    [[NIMSDK sharedSDK].resourceManager download:self.videoObject.url filepath:self.videoObject.path progress:^(float progress) {
        [SVProgressHUD showProgress:progress];
    } completion:^(NSError *error) {
        if (wself) {
            [SVProgressHUD dismiss];
            if (handler) {
                handler(error);
            }
        }
    }];
}




- (void)startPlay{
    self.moviePlayer.view.frame = self.view.bounds;
    self.moviePlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.moviePlayer play];
    [self.view addSubview:self.moviePlayer.view];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlaybackComplete:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:self.moviePlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayStateChanged:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification
                                               object:self.moviePlayer];
    
    
    CGRect bounds = self.moviePlayer.view.bounds;
    CGRect tapViewFrame = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
    UIView *tapView = [[UIView alloc]initWithFrame:tapViewFrame];
    [tapView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    tapView.backgroundColor = [UIColor clearColor];
    [self.moviePlayer.view addSubview:tapView];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onTap:)];
    [tapView  addGestureRecognizer:tap];
}

- (void)moviePlaybackComplete: (NSNotification *)aNotification
{
    if (self.moviePlayer == aNotification.object)
    {
        [self topStatusUIHidden:NO];
        NSDictionary *notificationUserInfo = [aNotification userInfo];
        NSNumber *resultValue = [notificationUserInfo objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
        MPMovieFinishReason reason = [resultValue intValue];
        if (reason == MPMovieFinishReasonPlaybackError)
        {
            NSError *mediaPlayerError = [notificationUserInfo objectForKey:@"error"];
            NSString *errorTip = [NSString stringWithFormat:@"播放失败: %@", [mediaPlayerError localizedDescription]];
            [self.view makeToast:errorTip
                        duration:2
                        position:CSToastPositionCenter];
        }
    }
    
}

- (void)moviePlayStateChanged: (NSNotification *)aNotification
{
    if (self.moviePlayer == aNotification.object)
    {
        switch (self.moviePlayer.playbackState)
        {
            case MPMoviePlaybackStatePlaying:
                [self topStatusUIHidden:YES];
                break;
            case MPMoviePlaybackStatePaused:
            case MPMoviePlaybackStateStopped:
            case MPMoviePlaybackStateInterrupted:
                [self topStatusUIHidden:NO];
            case MPMoviePlaybackStateSeekingBackward:
            case MPMoviePlaybackStateSeekingForward:
                break;
        }
        
    }
}

- (void)topStatusUIHidden:(BOOL)isHidden
{
    [[UIApplication sharedApplication] setStatusBarHidden:isHidden];
    self.navigationController.navigationBar.hidden = isHidden;
    NTESNavigationHandler *handler = (NTESNavigationHandler *)self.navigationController.delegate;
    handler.recognizer.enabled = !isHidden;
}

- (void)onTap: (UIGestureRecognizer *)recognizer
{
    switch (self.moviePlayer.playbackState)
    {
        case MPMoviePlaybackStatePlaying:
            [self.moviePlayer pause];
            break;
        case MPMoviePlaybackStatePaused:
        case MPMoviePlaybackStateStopped:
        case MPMoviePlaybackStateInterrupted:
            [self.moviePlayer play];
            break;
        default:
            break;
    }
}


- (MPMoviePlayerController*)moviePlayer{
    if (!_moviePlayer) {
        _moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:self.videoObject.path]];
        _moviePlayer.controlStyle = MPMovieControlStyleNone;
        _moviePlayer.scalingMode = MPMovieScalingModeAspectFill;
        _moviePlayer.fullscreen = YES;
    }
    return _moviePlayer;
}


@end
