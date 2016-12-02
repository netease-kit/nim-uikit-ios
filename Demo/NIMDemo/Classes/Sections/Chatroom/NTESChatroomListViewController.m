//
//  NTESChatroomListViewController.m
//  NIM
//
//  Created by chris on 15/12/10.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NTESChatroomListViewController.h"
#import "NTESLiveViewController.h"
#import "NTESChatroomListCell.h"
#import "UIView+NTES.h"
#import "SVProgressHUD.h"
#import "NTESChatroomManager.h"
#import "NTESDemoService.h"
#import "UIView+Toast.h"

static NSString *ChatroomListReuseIdentity = @"ChatroomListReuseIdentity";

@interface NTESChatroomListViewController ()

@property (nonatomic,copy)   NSArray *data;

@property (nonatomic,assign) BOOL enteringChatroom;

@property (nonatomic,strong) UIRefreshControl *refreshControl;

@end

@implementation NTESChatroomListViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _data = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"直播间";
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.collectionView];
    [self.collectionView addSubview:self.refreshControl];
    [self refresh];
}


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (!self.data.count && !self.refreshControl.refreshing) {
        [self refresh];
    }
}

- (void)refresh
{
    [self.refreshControl beginRefreshing];
    __weak typeof(self) weakSelf = self;
    [[NTESDemoService sharedService] fetchDemoChatrooms:^(NSError *error, NSArray<NIMChatroom *> *chatroom) {
        if (!error) {
            weakSelf.data = chatroom;
            [weakSelf.collectionView reloadData];
        }else{
            NSString *toast = [NSString stringWithFormat:@"请求失败 code:%zd",error.code];
            [weakSelf.view makeToast:toast duration:2.0 position:CSToastPositionCenter];
        }
        [weakSelf.refreshControl endRefreshing];
    }];
}

- (void)onPull2Refresh:(UIRefreshControl *)sender
{
    [self refresh];
}


- (void)reloadCollectionView:(BOOL)animated
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = self.itemSpacing;
    CGFloat padding = self.itemSpacing;
    layout.sectionInset = UIEdgeInsetsMake(padding * .5,padding,padding * .5,padding);
    layout.itemSize = CGSizeMake(self.itemWidth, self.itemHeight);

    [self.collectionView reloadData];
    [self.collectionView setCollectionViewLayout:layout animated:animated];
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    if (self.enteringChatroom) {
        return;
    }
    NIMChatroom *chatroom = [self chatroomAtIndexPath:indexPath];
    NIMUser *user = [[NIMSDK sharedSDK].userManager userInfo:[NIMSDK sharedSDK].loginManager.currentAccount];
    NIMChatroomEnterRequest *request = [[NIMChatroomEnterRequest alloc] init];
    request.roomId = chatroom.roomId;
    request.roomNickname = user.userInfo.nickName;
    request.roomAvatar = user.userInfo.avatarUrl;
    [SVProgressHUD show];
    self.enteringChatroom = YES;
    __weak typeof(self) wself = self;
    [[[NIMSDK sharedSDK] chatroomManager] enterChatroom:request
                                             completion:^(NSError *error,NIMChatroom *chatroom,NIMChatroomMember *me) {
                                                 [SVProgressHUD dismiss];
                                                 wself.enteringChatroom = NO;
                                                 if (error == nil)
                                                 {
                                                     [[NTESChatroomManager sharedInstance] cacheMyInfo:me roomId:chatroom.roomId];
                                                     
                                                     NTESLiveViewController *vc = [[NTESLiveViewController alloc] initWithChatroom:chatroom];
                                                     [self.navigationController pushViewController:vc animated:YES];
                                                 }
                                                 else
                                                 {
                                                     NSString *toast = [NSString stringWithFormat:@"进入失败 code:%zd",error.code];
                                                     [wself.view makeToast:toast duration:2.0 position:CSToastPositionCenter];
                                                     DDLogError(@"enter room %@ failed %@",chatroom.roomId,error);
                                                 }

                                             }];
    
    
}

#pragma mark - UICollectioMnViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger remain = self.data.count - self.numberOfItems * section;
    NSInteger numberOfItems = remain > self.numberOfItems ? self.numberOfItems : remain;
    return numberOfItems;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    NSInteger sections = self.data.count / self.numberOfItems;
    NSInteger numberOfSections = (self.data.count % self.numberOfItems) ? sections + 1 : sections;
    return numberOfSections;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NTESChatroomListCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ChatroomListReuseIdentity forIndexPath:indexPath];;
    NIMChatroom *chatroom = [self chatroomAtIndexPath:indexPath];
    [cell refresh:chatroom];
    return cell;
}


- (NIMChatroom *)chatroomAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.section * self.numberOfItems + indexPath.row;
    return [self.data objectAtIndex:index];
}


#pragma mark - Getter
- (NSInteger)numberOfItems{
    return 2;
}

- (CGFloat)itemWidth{
    //itemWidth在实际可能会有一些浮点误差导致一行放不下，这里取整保证可以放下
    return (NSInteger)((self.view.width - (self.itemSpacing * (self.numberOfItems + 1))) / self.numberOfItems);
}

- (CGFloat)itemSpacing{
    return 10;
}

- (CGFloat)itemHeight{
    return self.itemWidth * 0.75;
}


- (UICollectionView *)collectionView{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = self.itemSpacing;
        CGFloat padding = self.itemSpacing;
        layout.sectionInset = UIEdgeInsetsMake(padding * .5,padding,padding * .5,padding);
        layout.itemSize = CGSizeMake(self.itemWidth, self.itemHeight);
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        _collectionView.backgroundColor  = [UIColor whiteColor];
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _collectionView.contentInset = UIEdgeInsetsMake(padding * .5f, 0, padding * .5f, 0);
        [_collectionView registerClass:[NTESChatroomListCell class] forCellWithReuseIdentifier:ChatroomListReuseIdentity];
        _collectionView.delegate   = self;
        _collectionView.dataSource = self;
    }
    return _collectionView;
}

- (UIRefreshControl *)refreshControl
{
    if (!_refreshControl) {
        _refreshControl = [[UIRefreshControl alloc] initWithFrame:CGRectZero];
        [_refreshControl addTarget:self action:@selector(onPull2Refresh:) forControlEvents:UIControlEventValueChanged];
    }
    return _refreshControl;
}

#pragma mark - 旋转处理 (iOS7)

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self reloadCollectionView:YES];
}

#pragma mark - 旋转处理 (iOS8 or above)
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if (![self isViewLoaded]) {
        return;
    }
    [coordinator animateAlongsideTransition:^(id <UIViewControllerTransitionCoordinatorContext> context)
     {
         [self reloadCollectionView:YES];
     } completion:nil];
}


@end
