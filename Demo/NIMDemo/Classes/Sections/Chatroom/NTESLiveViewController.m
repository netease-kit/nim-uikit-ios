//
//  NTESLiveViewController.m
//  NIM
//
//  Created by chris on 15/12/16.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NTESLiveViewController.h"
#import "NTESChatroomSegmentedControl.h"
#import "UIView+NTES.h"
#import "NTESPageView.h"
#import "NTESChatroomViewController.h"
#import "NTESChatroomMemberListViewController.h"
#import "NTESLiveInfoViewController.h"
#import "UIImageView+WebCache.h"
#import "SVProgressHUD.h"
#import "UIImage+NTESColor.h"
#import "NTESLiveActionView.h"
#import "UIView+Toast.h"

@interface NTESLiveViewController ()<NTESLiveActionViewDataSource,NTESLiveActionViewDelegate,NIMChatroomManagerDelegate>

@property (nonatomic, copy)   NIMChatroom *chatroom;

@property (nonatomic, strong) NTESChatroomViewController *chatroomViewController;

@property (nonatomic, strong) NTESLiveActionView *actionView;

@property (nonatomic, strong) UIImageView *liveImageView;

@property (nonatomic, weak)   UIViewController *currentChildViewController;

@end

@implementation NTESLiveViewController

NTES_USE_CLEAR_BAR

- (instancetype)initWithChatroom:(NIMChatroom *)chatroom{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _chatroom = chatroom;
    }
    
    return self;
}

- (void)dealloc{
    [[NIMSDK sharedSDK].chatroomManager exitChatroom:_chatroom.roomId completion:nil];
    [[NIMSDK sharedSDK].chatroomManager removeDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupChildViewController];
    [self.view addSubview:self.liveImageView];
    [self.view addSubview:self.actionView];
    [self.actionView reloadData];
    self.currentChildViewController = self.chatroomViewController;
    [self adjustInputView];
    [self setupBackBarButtonItem];
    
    
    [[NIMSDK sharedSDK].chatroomManager addDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent
                                                animated:NO];
    [self.currentChildViewController beginAppearanceTransition:YES animated:animated];
}


- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault
                                                animated:NO];
    [self.currentChildViewController beginAppearanceTransition:NO animated:animated];
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.currentChildViewController endAppearanceTransition];
}


- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
    return NO;
}


- (void)setupChildViewController
{
    NSArray *vcs = [self makeChildViewControllers];
    for (UIViewController *vc in vcs) {
        [self addChildViewController:vc];
    }
}

#pragma mark - NTESLiveActionViewDataSource

- (NSInteger)numberOfPages
{
    return self.childViewControllers.count;
}

- (UIView *)viewInPage:(NSInteger)index
{
    UIView *view = self.childViewControllers[index].view;
    return view;
}

- (CGFloat)liveViewHeight
{
    return self.liveImageView.height;
}


#pragma mark - NTESLiveActionViewDelegate

- (void)onSegmentControlChanged:(NTESChatroomSegmentedControl *)control
{
    UIViewController *lastChild = self.currentChildViewController;
    UIViewController *child = self.childViewControllers[self.actionView.segmentedControl.selectedSegmentIndex];
    
    [lastChild beginAppearanceTransition:NO animated:YES];
    [child beginAppearanceTransition:YES animated:YES];
    [self.actionView.pageView scrollToPage:self.actionView.segmentedControl.selectedSegmentIndex];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentChildViewController = child;
        [lastChild endAppearanceTransition];
        [child endAppearanceTransition];
        self.chatroomViewController.sessionInputView.hidden = self.currentChildViewController != self.chatroomViewController;
    });
}

- (void)onTouchActionBackground
{
    [self.chatroomViewController.sessionInputView endEditing:YES];
}

#pragma mark - Get

#define LiveViewDefaultHeight 239.f

- (CGFloat)liveImageViewHeight
{
    return LiveViewDefaultHeight;
}

- (UIImageView *)liveImageView{
    if (!self.isViewLoaded) {
        return nil;
    }
    if (!_liveImageView) {
        _liveImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.width,self.liveImageViewHeight)];
        _liveImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _liveImageView.contentMode   = UIViewContentModeScaleAspectFill;
        _liveImageView.clipsToBounds = YES;
        NSInteger index = self.chatroom.roomId.hash % 8;
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"chatroom_cover_page_%zd",index]];
        [_liveImageView sd_setImageWithURL:nil placeholderImage:image];
    }
    return _liveImageView;
}

- (NTESLiveActionView *)actionView
{
    if (!self.isViewLoaded) {
        return nil;
    }
    if (!_actionView) {
        _actionView = [[NTESLiveActionView alloc] initWithDataSource:self];
        _actionView.frame = self.view.bounds;
        _actionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _actionView.delegate = self;
    }
    return _actionView;
}

#pragma mark - NIMChatroomManagerDelegate
- (void)chatroom:(NSString *)roomId beKicked:(NIMChatroomKickReason)reason
{
    if ([roomId isEqualToString:self.chatroom.roomId]) {
        NSString *toast = [NSString stringWithFormat:@"你被踢出聊天室"];
        DDLogInfo(@"chatroom be kicked, roomId:%@  rease:%zd",roomId,reason);
        [[NIMSDK sharedSDK].chatroomManager exitChatroom:roomId completion:nil];
        
        [self.view.window makeToast:toast duration:2.0 position:CSToastPositionCenter];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)chatroom:(NSString *)roomId connectionStateChanged:(NIMChatroomConnectionState)state;
{
    DDLogInfo(@"chatroom connectionStateChanged roomId : %@  state:%zd",roomId,state);
}

- (void)chatroom:(NSString *)roomId autoLoginFailed:(NSError *)error
{
    NSString *toast = [NSString stringWithFormat:@"chatroom autoLoginFailed failed : %zd",error.code];
    DDLogInfo(@"%@",toast);
    [[NIMSDK sharedSDK].chatroomManager exitChatroom:roomId completion:nil];
    [self.view.window makeToast:toast duration:2.0 position:CSToastPositionCenter];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Private
- (NSArray *)makeChildViewControllers{
    self.chatroomViewController = [[NTESChatroomViewController alloc] initWithChatroom:self.chatroom];
    NTESChatroomMemberListViewController *memberListVC = [[NTESChatroomMemberListViewController alloc] initWithChatroom:self.chatroom];
    NTESLiveInfoViewController *liveInfoVC = [[NTESLiveInfoViewController alloc] initWithChatroom:self.chatroom];
    return @[self.chatroomViewController,liveInfoVC,memberListVC];
}

//这个视图是替换一下聊天室的输入框，为了在多行输入显示时，输入框可以遮住上层的直播图
- (void)adjustInputView
{
    UIView *inputView  = self.chatroomViewController.sessionInputView;
    UIView *revertView;
    if ([self.currentChildViewController isKindOfClass:[NTESChatroomViewController class]]) {
        revertView = self.view;
    }else{
        revertView = self.chatroomViewController.view;
    }
    CGRect frame = [inputView.superview convertRect:inputView.frame toView:revertView];
    inputView.frame = frame;
    [revertView addSubview:inputView];
}

- (void)setupBackBarButtonItem
{
    UIImage *buttonNormal = [[UIImage imageNamed:@"chatroom_back_normal"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *buttonSelected = [[UIImage imageNamed:@"chatroom_back_selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [self.navigationController.navigationBar setBackIndicatorImage:buttonNormal];
    [self.navigationController.navigationBar setBackIndicatorTransitionMaskImage:buttonSelected];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backItem;
}

#pragma mark - Rotate
- (BOOL)shouldAutorotate{
    return NO;
}

@end
