//
//  NTESNormalTeamCardViewController.m
//  NIM
//
//  Created by chris on 15/3/10.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <NIMSDK/NIMSDK.h>
#import "NIMNormalTeamCardViewController.h"
#import "NIMTeamCardMemberItem.h"
#import "NIMKitDependency.h"
#import "NIMTeamCardRowItem.h"
#import "NIMTeamMemberCardViewController.h"
#import "UIView+NIM.h"
#import "NIMMemberGroupView.h"
#import "NIMTeamSwitchTableViewCell.h"
#import "NIMContactSelectViewController.h"
#import "NIMGlobalMacro.h"
#import "NIMKitProgressHUD.h"

@interface NIMNormalTeamCardViewController ()<NIMTeamManagerDelegate,
                                              NIMTeamSwitchProtocol,
                                              NIMContactSelectDelegate,
                                              NIMMemberGroupViewDelegate>

@property (nonatomic,strong) NIMMemberGroupView *headerView;
@property (nonatomic,assign) NIMKitCardHeaderOpeator currentOpera;

@end

@implementation NIMNormalTeamCardViewController

- (void)dealloc{
    [[NIMSDK sharedSDK].teamManager removeDelegate:self];
}

- (instancetype)initWithTeam:(NIMTeam *)team
                     session:(NIMSession *)session
                      option:(NIMTeamCardViewControllerOption *)option {
    self = [super initWithTeam:team session:session option:option];
    if (self) {
        _currentOpera = CardHeaderOpeatorNone;
        [[NIMSDK sharedSDK].teamManager addDelegate:self];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self didFetchTeamMember:nil];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    CGSize size = [self.headerView sizeThatFits:CGSizeMake(self.view.nim_width, CGFLOAT_MAX)];
    self.headerView.nim_size = size;
    self.tableView.tableHeaderView = self.headerView;
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

    itemName.title            = @"讨论组名称".nim_localized;
    itemName.subTitle         = self.teamListManager.team.teamName;
    itemName.action           = @selector(updateTeamInfoName);
    itemName.rowHeight        = 50.f;
    itemName.type             = TeamCardRowItemTypeCommon;
    
    NIMTeamCardRowItem *teamNotify = [[NIMTeamCardRowItem alloc] init];
    teamNotify.title            = @"消息提醒".nim_localized;
    //普通群没有只接受管理员
    teamNotify.switchOn         = [self.teamListManager.team notifyStateForNewMsg] == NIMTeamNotifyStateAll;
    teamNotify.rowHeight        = 50.f;
    teamNotify.type             = TeamCardRowItemTypeSwitch;
    teamNotify.identify         = NIMTeamCardSwithCellTypeNotify;

    NIMTeamCardRowItem *itemQuit = [[NIMTeamCardRowItem alloc] init];
    itemQuit.title            = @"退出讨论组".nim_localized;
    itemQuit.action           = @selector(quitTeam);
    itemQuit.rowHeight        = 60.f;
    itemQuit.type             = TeamCardRowItemTypeRedButton;
    
    NIMTeamCardRowItem *itemTop = [[NIMTeamCardRowItem alloc] init];

    itemTop.title            = @"聊天置顶".nim_localized;
    itemTop.switchOn         = self.option.isTop;
    itemTop.rowHeight        = 50.f;
    itemTop.type             = TeamCardRowItemTypeSwitch;
    itemTop.identify         = NIMTeamCardSwithCellTypeTop;
    return @[@[itemName,teamNotify,itemTop],@[itemQuit]];
}

#pragma mark - Refresh
- (void)reloadTableHeaderData{
    NIMKitCardHeaderOpeator opeartor;
    if (self.teamListManager.myTeamInfo.type == NIMTeamMemberTypeOwner) {
        opeartor = CardHeaderOpeatorAdd | CardHeaderOpeatorRemove;
    }else{
        opeartor = CardHeaderOpeatorAdd;
    }
    NSMutableArray <NIMMemebrGroupData *> *datas = [self headerDatasWithMembers:self.teamListManager.members];
    [_headerView refreshDatas:datas operators:opeartor];
    CGSize size = [self.headerView sizeThatFits:CGSizeMake(self.view.nim_width, CGFLOAT_MAX)];
    _headerView.nim_size = size;
    _headerView.enableRemove = self.currentOpera == CardHeaderOpeatorRemove;
}

- (void)reloadTableViewData{
    self.datas = [self buildBodyData];
}

- (void)reloadOtherData{
    self.navigationItem.title = self.teamListManager.team.teamName;
}

- (NSMutableArray <NIMMemebrGroupData *> *)headerDatasWithMembers:(NSArray<NIMTeamCardMemberItem *> *)members {
    NSMutableArray *ret = [NSMutableArray array];
    for (NIMTeamCardMemberItem *member in members) {
        NIMMemebrGroupData *obj = [[NIMMemebrGroupData alloc] init];
        obj.userId = member.userId;
        [ret addObject:obj];
    }
    return ret;
}

#pragma mark - Actions
- (void)updateTeamInfoName{
    __weak typeof(self) weakSelf = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"修改讨论组名称".nim_localized message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:nil];
    UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确认".nim_localized style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *input = alert.textFields.firstObject;
        [weakSelf didUpdateTeamName:input.text];
    }];
    [alert addAction:sure];
    [alert addAction:[self makeCancelAction]];
    [self showAlert:alert];
}

- (void)quitTeam{
    __weak typeof(self) weakSelf = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认退出讨论组?".nim_localized message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确认".nim_localized style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf didQuitTeam];
    }];
    [alert addAction:sure];
    [alert addAction:[self makeCancelAction]];
    [self showAlert:alert];
}

#pragma mark - ContactSelectDelegate
- (void)didFinishedSelect:(NSArray *)selectedContacts{
    switch (self.currentOpera) {
        case CardHeaderOpeatorAdd:{
            __weak typeof(self) wself = self;
            [self didInviteUsers:selectedContacts completion:^{
                wself.currentOpera = CardHeaderOpeatorNone;
            }];
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
    if ([team.teamId isEqualToString:self.teamListManager.team.teamId]) {
        [self didFetchTeamMember:nil];
    }
}

- (void)transferOwner:(NSString *)memberId isLeave:(BOOL)isLeave{
    __block typeof(self) wself = self;
    [self.teamListManager transferOwnerWithUserId:memberId
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
            NSString *currentUserID = [self.teamListManager myAccount];
            [users addObject:currentUserID];
            [users addObjectsFromArray:self.teamListManager.memberIds];
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
            [self reloadTableHeaderData];
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
