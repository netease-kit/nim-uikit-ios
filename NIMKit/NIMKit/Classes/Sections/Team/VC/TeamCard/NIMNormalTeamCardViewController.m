//
//  NTESNormalTeamCardViewController.m
//  NIM
//
//  Created by chris on 15/3/10.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <NIMSDK/NIMSDK.h>
#import "NIMNormalTeamCardViewController.h"
#import "NIMCardMemberItem.h"
#import "NIMKitDependency.h"
#import "NIMTeamCardRowItem.h"
#import "NIMTeamMemberCardViewController.h"
#import "UIView+NIM.h"
#import "NIMMemberGroupView.h"
#import "NIMTeamSwitchTableViewCell.h"
#import "NIMContactSelectViewController.h"
#import "NIMGlobalMacro.h"
#import "NIMKitProgressHUD.h"
#import "NIMTeamListDataManager.h"

@interface NIMNormalTeamCardViewController ()<NIMTeamManagerDelegate,
                                              NIMTeamSwitchProtocol,
                                              NIMContactSelectDelegate,
                                              NIMMemberGroupViewDelegate>

@property (nonatomic,strong) NIMMemberGroupView *headerView;
@property (nonatomic,assign) NIMKitCardHeaderOpeator currentOpera;
@property (nonatomic,strong) NIMTeamCardViewControllerOption *option; //外部配置
@property (nonatomic,strong) NIMTeamListDataManager *dataSource;

@end

@implementation NIMNormalTeamCardViewController

- (void)dealloc{
    [[NIMSDK sharedSDK].teamManager removeDelegate:self];
}

- (instancetype)initWithTeam:(NIMTeam *)team
                     session:(NIMSession *)session
                      option:(NIMTeamCardViewControllerOption *)option {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _currentOpera = CardHeaderOpeatorNone;
        _option = option;
        _dataSource = [[NIMTeamListDataManager alloc] initWithTeam:team session:session];
        [[NIMSDK sharedSDK].teamManager addDelegate:self];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self didFetchTeamMember];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    CGSize size = [self.headerView sizeThatFits:CGSizeMake(self.view.nim_width, CGFLOAT_MAX)];
    self.headerView.nim_size = size;
}

#pragma mark - Overload
- (UIView *)didGetHeaderView {
    return self.headerView;
}

- (void)didBuildTeamSwitchCell:(NIMTeamSwitchTableViewCell *)cell {
    cell.switchDelegate = self;
}

#pragma mark - Data
- (NSArray <NSArray <NIMTeamCardRowItem *> *> *)buildBodyData{

    NIMTeamCardRowItem *itemName = [[NIMTeamCardRowItem alloc] init];
    itemName.title            = @"讨论组名称";
    itemName.subTitle         = _dataSource.team.teamName;
    itemName.action           = @selector(updateTeamInfoName);
    itemName.rowHeight        = 50.f;
    itemName.type             = TeamCardRowItemTypeCommon;
    
    NIMTeamCardRowItem *teamNotify = [[NIMTeamCardRowItem alloc] init];
    teamNotify.title            = @"消息提醒";
    //普通群没有只接受管理员
    teamNotify.switchOn         = [_dataSource.team notifyStateForNewMsg] == NIMTeamNotifyStateAll;
    teamNotify.rowHeight        = 50.f;
    teamNotify.type             = TeamCardRowItemTypeSwitch;
    teamNotify.identify         = NIMTeamCardSwithCellTypeNotify;

    NIMTeamCardRowItem *itemQuit = [[NIMTeamCardRowItem alloc] init];
    itemQuit.title            = @"退出讨论组";
    itemQuit.action           = @selector(quitTeam);
    itemQuit.rowHeight        = 60.f;
    itemQuit.type             = TeamCardRowItemTypeRedButton;
    
    NIMTeamCardRowItem *itemTop = [[NIMTeamCardRowItem alloc] init];
    itemTop.title            = @"聊天置顶";
    itemTop.switchOn         = _option.isTop;
    itemTop.rowHeight        = 50.f;
    itemTop.type             = TeamCardRowItemTypeSwitch;
    itemTop.identify         = NIMTeamCardSwithCellTypeTop;
    return @[@[itemName,teamNotify,itemTop],@[itemQuit]];
}

#pragma mark - Refresh
- (void)reloadData{
    [self refreshTableHeader:self.view.nim_width];
    [self refreshTableBody];
    [self refreshTitle];
}

- (void)refreshTableHeader:(CGFloat)width{
    NIMKitCardHeaderOpeator opeartor;
    if (_dataSource.myTeamInfo.type == NIMTeamMemberTypeOwner) {
        opeartor = CardHeaderOpeatorAdd | CardHeaderOpeatorRemove;
    }else{
        opeartor = CardHeaderOpeatorAdd;
    }
    NSMutableArray <NIMMemebrGroupData *> *datas = [self headerDatasWithMembers:_dataSource.members];
    [_headerView refreshDatas:datas operators:opeartor];
    CGSize size = [self.headerView sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    _headerView.nim_size = size;
    _headerView.enableRemove = self.currentOpera == CardHeaderOpeatorRemove;
}

- (void)refreshTableBody{
    self.datas = [self buildBodyData];
}

- (void)refreshTitle{
    self.navigationItem.title = _dataSource.team.teamName;
}

- (NSMutableArray <NIMMemebrGroupData *> *)headerDatasWithMembers:(NSArray<NIMTeamMember *> *)members {
    NSMutableArray *ret = [NSMutableArray array];
    for (NIMTeamMember *member in members) {
        NIMMemebrGroupData *obj = [[NIMMemebrGroupData alloc] init];
        obj.userId = member.userId;
        obj.isMyUserId = [member.userId isEqualToString:_dataSource.myAccount];
        [ret addObject:obj];
    }
    return ret;
}

#pragma mark - Function
- (void)didFetchTeamMember {
    __weak typeof(self) wself = self;
    [_dataSource fetchTeamMembersWithOption:nil completion:^(NSError * _Nullable error, NSString * _Nullable msg) {
        if (!error) {
            [wself reloadData];
        }
        [wself showToastMsg:msg];
    }];
}

- (void)didUpdateTeamName:(NSString *)name {
    if (!name) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [_dataSource updateTeamName:name completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        if (!error) {
            [weakSelf refreshTableBody];
        }
        [weakSelf showToastMsg:msg];
    }];
}

- (void)didQuitTeam{
    __weak typeof(self) weakSelf = self;
    [_dataSource quitTeamCompletion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        if (!error) {
            [weakSelf.navigationController popToRootViewControllerAnimated:YES];
        }
        [weakSelf showToastMsg:msg];
    }];
}

- (void)didInviteUsers:(NSArray<NSString *> *)userIds {
    __weak typeof(self) wself = self;
    [NIMKitProgressHUD show];
    NSDictionary *info = @{
                           @"postscript" : @"邀请你加入讨论组",
                           @"attach" : @"邀请扩展消息"
                           };
    [_dataSource addUsers:userIds info:info completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        [NIMKitProgressHUD dismiss];
        if (!error) {
            [wself refreshTableHeader:wself.view.nim_width];
        }
        wself.currentOpera = CardHeaderOpeatorNone;
    }];
}

- (void)didKickUser:(NSString *)userId {
    __weak typeof(self) wself = self;
    [NIMKitProgressHUD show];
    [_dataSource kickUsers:@[userId] completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        [NIMKitProgressHUD dismiss];
        if (!error) {
            [wself refreshTableHeader:wself.view.nim_width];
        }
        [wself showToastMsg:msg];
    }];
}

- (void)didUpdateNotifiyState:(NIMTeamNotifyState)state {
    __weak typeof(self) weakSelf = self;
    [_dataSource updateTeamNotifyState:state completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        if (!error) {
            [weakSelf refreshTableBody];
        }
        [weakSelf showToastMsg:msg];
    }];
}

#pragma mark - Actions
- (void)updateTeamInfoName{
    __weak typeof(self) weakSelf = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"修改讨论组名称" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:nil];
    UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *input = alert.textFields.firstObject;
        [weakSelf didUpdateTeamName:input.text];
    }];
    [alert addAction:sure];
    [alert addAction:[self makeCancelAction]];
    [self showAlert:alert];
}

- (void)quitTeam{
    __weak typeof(self) weakSelf = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认退出讨论组?" message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf didQuitTeam];
    }];
    [alert addAction:sure];
    [alert addAction:[self makeCancelAction]];
    [self showAlert:alert];
}

#pragma mark - ContactSelectDelegate
- (void)didFinishedSelect:(NSArray *)selectedContacts{
    if (selectedContacts.count == 0) {
        return;
    }
    
    switch (self.currentOpera) {
        case CardHeaderOpeatorAdd:{
            [self didInviteUsers:selectedContacts];
            break;
        }
        default:
            break;
    }
}

- (void)didCancelledSelect{
    self.currentOpera = CardHeaderOpeatorNone;
}

#pragma mark - NIMTeamSwitchProtocol
- (void)cell:(NIMTeamSwitchTableViewCell *)cell onStateChanged:(BOOL)on {
    if (cell.identify == NIMTeamCardSwithCellTypeNotify) {
        NIMTeamNotifyState state = on? NIMTeamNotifyStateAll : NIMTeamNotifyStateNone;
        [self didUpdateNotifiyState:state];
    } else if (cell.identify == NIMTeamCardSwithCellTypeTop) {
        if ([self.delegate respondsToSelector:@selector(NIMTeamCardVCDidSetTop:)]) {
            [self.delegate NIMTeamCardVCDidSetTop:on];
        }
    } else {}
}

#pragma mark - NIMTeamManagerDelegate
- (void)onTeamUpdated:(NIMTeam *)team{
    if ([team.teamId isEqualToString:_dataSource.team.teamId]) {
        [self didFetchTeamMember];
    }
}

- (void)transferOwner:(NSString *)memberId isLeave:(BOOL)isLeave{
    __block typeof(self) wself = self;
    [_dataSource ontransferWithNewOwnerId:memberId
                                    leave:isLeave
                               completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        [wself showToastMsg:msg];
    }];
}

#pragma mark - NIMMemberGroupViewDelegate
- (void)didSelectRemoveButtonWithMemberId:(NSString *)uid{
    if (uid) {
        [self didKickUser:uid];
    }
}

- (void)didSelectOperator:(NIMKitCardHeaderOpeator)opera {
    switch (opera) {
        case CardHeaderOpeatorAdd:{
            self.currentOpera = CardHeaderOpeatorAdd;
            NSMutableArray *users = [[NSMutableArray alloc] init];
            NSString *currentUserID = [_dataSource myAccount];
            [users addObject:currentUserID];
            [users addObjectsFromArray:_dataSource.memberIds];
            NIMContactFriendSelectConfig *config = [[NIMContactFriendSelectConfig alloc] init];
            config.filterIds = users;
            config.needMutiSelected = YES;
            NIMContactSelectViewController *vc = [[NIMContactSelectViewController alloc] initWithConfig:config];
            vc.delegate = self;
            [vc show];
            break;
        }
        case CardHeaderOpeatorRemove:{
            self.currentOpera = self.currentOpera==CardHeaderOpeatorRemove? CardHeaderOpeatorNone : CardHeaderOpeatorRemove;
            [self refreshTableHeader:self.view.nim_width];
            break;
        }
        default:
            break;
    }
}

#pragma mark - Getter
- (NIMMemberGroupView *)headerView {
    if (!_headerView) {
        _headerView = [[NIMMemberGroupView alloc] initWithFrame:CGRectZero];
        _headerView.delegate = self;
    }
    return _headerView;
}

@end
