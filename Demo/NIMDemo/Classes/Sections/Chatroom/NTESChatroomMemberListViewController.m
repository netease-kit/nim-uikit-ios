//
//  NTESChatroomMemberListViewController.m
//  NIM
//
//  Created by chris on 15/12/17.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NTESChatroomMemberListViewController.h"
#import "NTESChatroomMemberCell.h"
#import "UIScrollView+NTESPullToRefresh.h"
#import "UIView+Toast.h"
#import "UIView+NTES.h"
#import "NTESChatroomManager.h"

@interface NTESChatroomMemberListViewController()<UITableViewDataSource,UITableViewDelegate,NIMChatManagerDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NIMChatroom *chatrooom;

@property (nonatomic, assign) NSInteger limit; //分页条数

@property (nonatomic, strong) NSMutableArray<NIMChatroomMember *> *members;


@end

@implementation NTESChatroomMemberListViewController

- (instancetype)initWithChatroom:(NIMChatroom *)chatroom{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _limit     = 100;
        _chatrooom = chatroom;
        _members   = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    self.view.backgroundColor = UIColorFromRGB(0xedf1f5);
    [self.view addSubview:self.tableView];
    [self prepareData];
    [[NIMSDK sharedSDK].chatManager addDelegate:self];
    [self.tableView registerClass:[NTESChatroomMemberCell class] forCellReuseIdentifier:self.cellReuseIdentifier];
}


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self prepareData];
}

- (void)prepareData{
    __weak typeof(self) wself = self;
    [self requestTeamMembers:nil handler:^(NSError *error, NSArray *members) {
        if (!error)
        {
            [wself.members removeAllObjects];
            if (members.count == wself.limit)
            {
                [wself.tableView addPullToRefreshWithActionHandler:^{
                    [wself loadMoreData];
                } position:NTESPullToRefreshPositionBottom];
            }
            else
            {
                wself.tableView.tableFooterView = [[UIView alloc] init];
            }
            wself.members = [NSMutableArray arrayWithArray:members];
            [wself sortMember];
            [wself.tableView reloadData];
        }
        else
        {
            [wself.view makeToast:@"直播间成员获取失败"];
        }
    }];
}

- (void)loadMoreData{
    __weak typeof(self) wself = self;
    [self requestTeamMembers:self.members.lastObject handler:^(NSError *error, NSArray *members){
        [wself.tableView.pullToRefreshView stopAnimating];
        [wself.members addObjectsFromArray:members];
        [wself sortMember];
        [wself.tableView reloadData];
    }];
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}


- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NIMChatroomMember *member = self.members[indexPath.row];
    BOOL isBlack = member.isInBlackList;
    BOOL isMute  = member.isMuted;
    BOOL isManager = member.type == NIMChatroomMemberTypeManager;
    
    __weak typeof(self) weakSelf = self;
    UITableViewRowAction *blackUser = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:isBlack? @"解除拉黑":@"拉黑" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [weakSelf updateBlackListAtIndexPath:indexPath isBlack:!isBlack];
        [tableView setEditing:NO animated:YES];
    }];
    blackUser.backgroundColor = [UIColor orangeColor];
    
    UITableViewRowAction *muteUser = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:isMute?@"解除禁言":@"禁言" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [weakSelf updateMuteListAtIndexPath:indexPath isMute:!isMute];
        [tableView setEditing:NO animated:YES];
    }];
    muteUser.backgroundColor = [UIColor redColor];
    
    UITableViewRowAction *appointManager = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:isManager?@"解除管理员":@"任命管理员" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [weakSelf appointManagerAtIndexPath:indexPath isManager:!isManager];
        [tableView setEditing:NO animated:YES];
    }];
    appointManager.backgroundColor = UIColorFromRGB(0x0BB3FC);
    
    UITableViewRowAction *kickMember = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"踢出" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [weakSelf kickMemberAtIndexPath:indexPath];
        [tableView setEditing:NO animated:NO];
    }];
    kickMember.backgroundColor = UIColorFromRGB(0xC71585);
    
    return @[blackUser,muteUser,appointManager,kickMember];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.members.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NTESChatroomMemberCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellReuseIdentifier];
    NIMChatroomMember *member = self.members[indexPath.row];
    [cell refresh:member];
    return cell;
}

#pragma mark - Role
- (void)updateBlackListAtIndexPath:(NSIndexPath *)indexPath isBlack:(BOOL)isBlack
{
    NIMChatroomMember *member = self.members[indexPath.row];
    NIMChatroomMemberUpdateRequest *request = [[NIMChatroomMemberUpdateRequest alloc] init];
    request.roomId = self.chatrooom.roomId;
    request.userId = member.userId;
    request.enable = isBlack;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].chatroomManager updateMemberBlack:request completion:^(NSError *error) {
        if (!error)
        {
            member.isInBlackList = isBlack;
            if (!isBlack) {
                //解除拉黑后默认变回游客身份
                member.type = NIMChatroomMemberTypeGuest;
            }
            [weakSelf.members replaceObjectAtIndex:indexPath.row withObject:member];
            [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
        else
        {
            NSString *toast = [NSString stringWithFormat:@"操作失败 code:%zd",error.code];
            [weakSelf.tableView makeToast:toast duration:2.0 position:CSToastPositionCenter];
        }
    }];
}


- (void)updateMuteListAtIndexPath:(NSIndexPath *)indexPath isMute:(BOOL)isMute
{
    NIMChatroomMember *member = self.members[indexPath.row];
    NIMChatroomMemberUpdateRequest *request = [[NIMChatroomMemberUpdateRequest alloc] init];
    request.roomId = self.chatrooom.roomId;
    request.userId = member.userId;
    request.enable = isMute;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].chatroomManager updateMemberMute:request completion:^(NSError *error) {
        if (!error)
        {
            member.isMuted = isMute;
            if (!isMute) {
                //解除禁言后默认变回游客身份
                member.type = NIMChatroomMemberTypeGuest;
            }
            [weakSelf.members replaceObjectAtIndex:indexPath.row withObject:member];
            [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
        else
        {
            NSString *toast = [NSString stringWithFormat:@"操作失败 code:%zd",error.code];
            [weakSelf.tableView makeToast:toast duration:2.0 position:CSToastPositionCenter];
        }
    }];
}

- (void)appointManagerAtIndexPath:(NSIndexPath *)indexPath isManager:(BOOL)isManager
{
    NIMChatroomMember *member = self.members[indexPath.row];
    NIMChatroomMemberUpdateRequest *request = [[NIMChatroomMemberUpdateRequest alloc] init];
    request.roomId = self.chatrooom.roomId;
    request.userId = member.userId;
    request.enable = isManager;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].chatroomManager markMemberManager:request completion:^(NSError *error) {
        if (!error)
        {
            member.type = isManager ? NIMChatroomMemberTypeManager : NIMChatroomMemberTypeNormal;
            [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        else
        {
            NSString *toast = [NSString stringWithFormat:@"操作失败 code:%zd",error.code];
            [weakSelf.tableView makeToast:toast duration:2.0 position:CSToastPositionCenter];
        }
    }];
}

- (void)kickMemberAtIndexPath:(NSIndexPath *)indexPath
{
    NIMChatroomMember *member = self.members[indexPath.row];
    NIMChatroomMemberKickRequest *request = [[NIMChatroomMemberKickRequest alloc] init];
    request.roomId = self.chatrooom.roomId;
    request.userId = member.userId;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].chatroomManager kickMember:request completion:^(NSError *error) {
        if (!error)
        {
            [weakSelf.members removeObjectAtIndex:indexPath.row];
            [weakSelf.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else
        {
            NSString *toast = [NSString stringWithFormat:@"操作失败 code:%zd",error.code];
            [weakSelf.tableView makeToast:toast duration:2.0 position:CSToastPositionCenter];
        }
    }];
}

#pragma mark - Private 
- (void)requestTeamMembers:(NIMChatroomMember *)lastMember handler:(NIMChatroomMembersHandler)handler{
    NIMChatroomMemberRequest *request = [[NIMChatroomMemberRequest alloc] init];
    request.roomId = self.chatrooom.roomId;
    request.lastMember = lastMember;
    request.type   = lastMember.type == NIMChatroomMemberTypeGuest ? NIMChatroomFetchMemberTypeTemp : NIMChatroomFetchMemberTypeRegularOnline;
    request.limit  = self.limit;
    __weak typeof(self) wself = self;
    [[NIMSDK sharedSDK].chatroomManager fetchChatroomMembers:request completion:^(NSError *error, NSArray *members) {
        if (!error)
        {
            if (members.count < wself.limit && request.type == NIMChatroomFetchMemberTypeRegularOnline) {
                //固定的没抓够，再抓点临时的充数
                NIMChatroomMemberRequest *req = [[NIMChatroomMemberRequest alloc] init];
                req.roomId = wself.chatrooom.roomId;
                req.lastMember = nil;
                req.type   = NIMChatroomFetchMemberTypeTemp;
                req.limit  = wself.limit;
                [[NIMSDK sharedSDK].chatroomManager fetchChatroomMembers:req completion:^(NSError *error, NSArray *tempMembers) {
                    NSArray *result;
                    if (!error) {
                        result = [members arrayByAddingObjectsFromArray:tempMembers];
                        if (result.count > wself.limit) {
                            result = [result subarrayWithRange:NSMakeRange(0, wself.limit)];
                        }
                    }
                    handler(error,result);
                }];
            }
            else
            {
                handler(error,members);
            }
        }
        else
        {
            handler(error,members);
        }
    }];
}

- (void)sortMember
{
    NSDictionary<NSNumber *,NSNumber *> *values =
                             @{
                               @(NIMChatroomMemberTypeCreator) : @(1),
                               @(NIMChatroomMemberTypeManager) : @(2),
                               @(NIMChatroomMemberTypeNormal ) : @(3),
                               @(NIMChatroomMemberTypeLimit  ) : @(4),
                               @(NIMChatroomMemberTypeGuest  ) : @(5),
                              };
    [self.members sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NIMChatroomMember *member1  = obj1;
        NIMChatroomMember *member2  = obj2;
        NIMChatroomMemberType type1 = member1.type;
        NIMChatroomMemberType type2 = member2.type;
        return values[@(type1)].integerValue > values[@(type2)].integerValue;
    }];
}

#pragma mark - Get
- (NSString *)cellReuseIdentifier{
    return @"cell";
}


- (UITableView *)tableView
{
    if (!self.isViewLoaded) {
        return nil;
    }
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height) style:UITableViewStylePlain];
        CGFloat contentInsetTop = 10.f;
        _tableView.contentInset = UIEdgeInsetsMake(contentInsetTop, 0, 0, 0);
        _tableView.backgroundColor  = [UIColor clearColor];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.dataSource = self;
        _tableView.delegate   = self;
        
    }
    return _tableView;
}

@end
