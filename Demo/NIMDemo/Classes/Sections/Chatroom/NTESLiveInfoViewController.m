//
//  NTESLiveInfoViewController.m
//  NIM
//
//  Created by chris on 15/12/17.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NTESLiveInfoViewController.h"
#import "NTESLiveMasterInfoView.h"
#import "UIView+NTES.h"
#import "NTESLiveBroadcastView.h"
#import "NTESChatroomManager.h"

@interface NTESLiveInfoViewController()<NIMUserManagerDelegate>

@property (nonatomic, strong) NIMChatroom *chatroom;

@property (nonatomic, strong) NTESLiveMasterInfoView *masterInfoView;

@property (nonatomic, strong) NTESLiveBroadcastView *liveBroadcastView;

@property (nonatomic, strong) NIMChatroomMember *master;

@property (nonatomic, assign) NSTimeInterval lastRequestTime;

@property (nonatomic, assign) NSTimeInterval maxCacheTime; //秒为单位

@end

@implementation NTESLiveInfoViewController

- (instancetype)initWithChatroom:(NIMChatroom *)chatroom{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _chatroom = chatroom;
        _maxCacheTime = 60 * 1; //缓存1分钟过期
        [self checkNeedRequest];
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    self.view.backgroundColor = UIColorFromRGB(0xedf1f5);
    [self.view addSubview:self.masterInfoView];
    [self.view addSubview:self.liveBroadcastView];
    [self refresh];
    //当主播没有上传特别个人信息时，需要从IM信息里读取，这个时候需要监听IM信息变化。
    //由于Demo将个人信息托管至云信，只需要监听此回调即可。
    [[NIMSDK sharedSDK].userManager addDelegate:self];    
}


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self checkNeedRequest];
}


- (void)checkNeedRequest
{
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (now - self.lastRequestTime > self.maxCacheTime) {
        DDLogDebug(@"start request live info, timeinterval : %.2f",now - self.lastRequestTime);
        [self requestChatroom];
        [self requestMaster];
        //失败也不管，至少隔1分钟才会再去请求
        self.lastRequestTime = now;
    }
}



- (void)refresh
{
    if (self.isViewLoaded)
    {
        if (self.master)
        {
            [self.masterInfoView refresh:self.master chatroom:self.chatroom];
        }
        [self.liveBroadcastView refresh:self.chatroom];
    }
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    CGFloat marginTop = 10.f;
    self.masterInfoView.top = marginTop;
    self.liveBroadcastView.height = self.view.height - self.masterInfoView.bottom;
    self.liveBroadcastView.bottom = self.view.height;
    
}


#pragma mark - NIMUserManagerDelegate
- (void)onUserInfoChanged:(NIMUser *)user
{
    [self.masterInfoView refresh:self.master chatroom:self.chatroom];
}


#pragma mark - Request
- (void)requestChatroom
{
    __weak typeof(self) wself = self;
    [[NIMSDK sharedSDK].chatroomManager fetchChatroomInfo:self.chatroom.roomId completion:^(NSError *error, NIMChatroom *chatroom) {
        if (!error)
        {
            wself.chatroom = chatroom;
            [wself refresh];
        }
    }];
}

- (void)requestMaster
{
    NIMChatroomMembersByIdsRequest *request = [[NIMChatroomMembersByIdsRequest alloc] init];
    request.roomId  = self.chatroom.roomId;
    request.userIds = @[self.chatroom.creator];
    __weak typeof(self) wself = self;
    [[NIMSDK sharedSDK].chatroomManager fetchChatroomMembersByIds:request completion:^(NSError *error, NSArray *members) {
        if (!error) {
            wself.master = members.firstObject;
            [wself refresh];
        }
    }];
}

#pragma mark - Get
- (CGFloat)masterInfoViewHeight{
    return 80.f;
}

- (NTESLiveMasterInfoView *)masterInfoView{
    if (!self.isViewLoaded) {
        return nil;
    }
    if (!_masterInfoView) {
        _masterInfoView = [[NTESLiveMasterInfoView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.masterInfoViewHeight)];
    }
    return _masterInfoView;
}

- (NTESLiveBroadcastView *)liveBroadcastView{
    if (!self.isViewLoaded) {
        return nil;
    }
    if (!_liveBroadcastView) {
        _liveBroadcastView = [[NTESLiveBroadcastView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 0)];
        _liveBroadcastView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    return _liveBroadcastView;
}



@end
