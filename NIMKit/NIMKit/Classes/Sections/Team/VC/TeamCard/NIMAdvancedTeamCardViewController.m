//
//  NIMAdvancedTeamCardViewController.m
//  NIM
//
//  Created by chris on 15/3/25.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMAdvancedTeamCardViewController.h"
#import "NIMTeamMemberCardViewController.h"
#import "NIMContactSelectViewController.h"
#import "NIMTeamMemberListViewController.h"
#import "NIMTeamMuteMemberListViewController.h"
#import "NIMTeamAnnouncementListViewController.h"
#import "NIMTeamCardRowItem.h"
#import "UIView+NIM.h"
#import "NIMTeamCardMemberItem.h"
#import "NIMKitUtil.h"
#import "NIMTeamCardHeaderView.h"
#import "NIMTeamListDataManager.h"
#import "NIMKitInfoFetchOption.h"
#import "NIMTeamHelper.h"

@interface NIMAdvancedTeamCardViewController ()<NIMTeamMemberListCellActionDelegate,
                                                NIMContactSelectDelegate,
                                                NIMTeamSwitchProtocol,
                                                NIMTeamManagerDelegate,
                                                NIMTeamCardHeaderViewDelegate,
                                                NIMTeamAnnouncementListVCDelegate>

@property (nonatomic,strong) NIMTeamCardHeaderView *headerView;

@end

@implementation NIMAdvancedTeamCardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - reload
- (UIView *)didGetHeaderView {
    return self.headerView;
}

- (void)didBuildTeamSwitchCell:(NIMTeamSwitchTableViewCell *)cell {
    cell.switchDelegate = self;
}

- (void)didBuildTeamMemberCell:(NIMTeamMemberListCell *)cell {
    cell.delegate = self;
    cell.disableInvite = ![NIMKitUtil canInviteMemberToTeam:self.teamListManager.myTeamInfo];
    NSMutableArray <NSDictionary *>*memberInfos = [NSMutableArray array];
    for (int i = 0; i < MIN(cell.maxShowMemberCount, self.teamListManager.members.count); i++) {
        NIMTeamCardMemberItem *obj = self.teamListManager.members[i];
        NIMKitInfoFetchOption *option = [[NIMKitInfoFetchOption alloc] init];
        option.session = self.teamListManager.session;
        NIMKitInfo *info = [[NIMKit sharedKit] infoByUser:obj.userId option:option];
        
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        dic[kTeamMember] = obj;
        dic[kTeamMemberInfo] = info;
        [memberInfos addObject:dic];
        
    }
    cell.infos = memberInfos;
}

#pragma mark - Data
- (NSArray<NSArray<NIMTeamCardRowItem *> *> *)buildBodyData{
    NSArray *ret = nil;
    __weak typeof(self) weakSelf = self;
    BOOL canEdit = [NIMKitUtil canEditTeamInfo:self.teamListManager.myTeamInfo];
    BOOL isOwner    = self.teamListManager.myTeamInfo.type == NIMTeamMemberTypeOwner;
    BOOL isManager  = self.teamListManager.myTeamInfo.type == NIMTeamMemberTypeManager;
    
    NIMTeamCardRowItem *teamMember = [[NIMTeamCardRowItem alloc] init];
    teamMember.title  = @"群成员".nim_localized;
    teamMember.rowHeight = 111.f;
    teamMember.action = @selector(enterMemberCard);
    teamMember.type   = TeamCardRowItemTypeTeamMember;
    
    NIMTeamCardRowItem *teamType = [[NIMTeamCardRowItem alloc] init];
    teamType.title = @"群类型".nim_localized;
    teamType.subTitle = @"高级群".nim_localized;
    teamType.rowHeight = 50.f;
    teamType.type   = TeamCardRowItemTypeCommon;
    teamType.actionDisabled = YES;
    
    NIMTeamCardRowItem *teamName = [[NIMTeamCardRowItem alloc] init];
    teamName.title = @"群名称".nim_localized;
    teamName.subTitle = self.teamListManager.team.teamName;
    teamName.action = @selector(updateTeamName);
    teamName.rowHeight = 50.f;
    teamName.type   = TeamCardRowItemTypeCommon;
    teamName.actionDisabled = !canEdit;
    
    NIMTeamCardRowItem *teamNick = [[NIMTeamCardRowItem alloc] init];
    teamNick.title = @"群昵称".nim_localized;
    teamNick.subTitle = self.teamListManager.myTeamInfo.nickname;
    teamNick.action = @selector(updateTeamNick);
    teamNick.rowHeight = 50.f;
    teamNick.type   = TeamCardRowItemTypeCommon;

    NIMTeamCardRowItem *teamIntro = [[NIMTeamCardRowItem alloc] init];
    teamIntro.title = @"群介绍".nim_localized;
    teamIntro.subTitle = self.teamListManager.team.intro.length ? self.teamListManager.team.intro : (canEdit ? @"点击填写群介绍".nim_localized : @"");
    teamIntro.action = @selector(updateTeamIntro);
    teamIntro.rowHeight = 50.f;
    teamIntro.type   = TeamCardRowItemTypeCommon;
    teamIntro.actionDisabled = !canEdit;
    
    NIMTeamCardRowItem *teamAnnouncement = [[NIMTeamCardRowItem alloc] init];
    teamAnnouncement.title = @"群公告".nim_localized;
    teamAnnouncement.subTitle = @"点击查看群公告".nim_localized;
    teamAnnouncement.action = @selector(updateTeamAnnouncement);
    teamAnnouncement.rowHeight = 50.f;
    teamAnnouncement.type   = TeamCardRowItemTypeCommon;
    
    BOOL inAllMuteMode = self.teamListManager.team.inAllMuteMode;
    NIMTeamCardRowItem *teamMute = [[NIMTeamCardRowItem alloc] init];
    teamMute.title = @"群禁言".nim_localized;
    teamMute.subTitle = [NIMTeamHelper teamMuteText:inAllMuteMode];
    teamMute.rowHeight = 50.f;
    teamMute.type = TeamCardRowItemTypeSelected;
    teamMute.optionItems = [NIMTeamHelper teamMuteItemsWithSeleced:inAllMuteMode];
    teamMute.actionDisabled = !canEdit;
    teamMute.selectedBlock = ^(id<NIMKitSelectCardData> item) {
        [weakSelf didUpdateTeamMute:[item.value integerValue]];
    };
    
    NIMTeamCardRowItem *teamMuteList = [[NIMTeamCardRowItem alloc] init];
    teamMuteList.title = @"禁言列表".nim_localized;
    teamMuteList.rowHeight = 50.f;
    teamMuteList.type = TeamCardRowItemTypeCommon;
    teamMuteList.action = @selector(enterMuteList);

    NIMTeamCardRowItem *teamNotify = [[NIMTeamCardRowItem alloc] init];
    teamNotify.title  = @"消息提醒".nim_localized;
    teamNotify.subTitle = [NIMTeamHelper notifyStateText:self.teamListManager.team.notifyStateForNewMsg];
    teamNotify.rowHeight = 50.f;
    teamNotify.type = TeamCardRowItemTypeSelected;
    teamNotify.optionItems = [NIMTeamHelper notifyStateItemsWithSeleced:self.teamListManager.team.notifyStateForNewMsg];
    teamNotify.selectedBlock = ^(id<NIMKitSelectCardData> item) {
        [weakSelf didUpdateNotifiyState:[item.value integerValue]];
    };

    NIMTeamCardRowItem *itemQuit = [[NIMTeamCardRowItem alloc] init];
    itemQuit.title = @"退出高级群".nim_localized;
    itemQuit.action = @selector(quitTeam);
    itemQuit.rowHeight = 60.f;
    itemQuit.type   = TeamCardRowItemTypeRedButton;
    
    NIMTeamCardRowItem *itemDismiss = [[NIMTeamCardRowItem alloc] init];
    itemDismiss.title  = @"解散群聊".nim_localized;
    itemDismiss.action = @selector(dismissTeam);
    itemDismiss.rowHeight = 60.f;
    itemDismiss.type   = TeamCardRowItemTypeRedButton;
    
    NIMTeamCardRowItem *itemAuth = [[NIMTeamCardRowItem alloc] init];
    itemAuth.title  = @"身份验证".nim_localized;
    itemAuth.subTitle = [NIMTeamHelper jonModeText:self.teamListManager.team.joinMode];
    itemAuth.actionDisabled = !canEdit;
    itemAuth.rowHeight = 60.f;
    itemAuth.type   = TeamCardRowItemTypeSelected;
    itemAuth.optionItems = [NIMTeamHelper joinModeItemsWithSeleced:self.teamListManager.team.joinMode];
    itemAuth.selectedBlock = ^(id<NIMKitSelectCardData> item) {
        [weakSelf didupdateTeamJoinMode:[item.value integerValue]];
    };
    
    NIMTeamCardRowItem *itemInvite = [[NIMTeamCardRowItem alloc] init];
    itemInvite.title  = @"邀请他人权限".nim_localized;
    itemInvite.subTitle = [NIMTeamHelper InviteModeText:self.teamListManager.team.inviteMode];
    itemInvite.actionDisabled = !canEdit;
    itemInvite.rowHeight = 60.f;
    itemInvite.type = TeamCardRowItemTypeSelected;
    itemInvite.optionItems = [NIMTeamHelper InviteModeItemsWithSeleced:self.teamListManager.team.inviteMode];
    itemInvite.selectedBlock = ^(id<NIMKitSelectCardData> item) {
        [weakSelf didUpdateTeamInviteMode:[item.value integerValue]];
    };
    
    NIMTeamCardRowItem *itemUpdateInfo = [[NIMTeamCardRowItem alloc] init];
    itemUpdateInfo.title  = @"群资料修改权限".nim_localized;
    itemUpdateInfo.subTitle = [NIMTeamHelper updateInfoModeText:self.teamListManager.team.updateInfoMode];
    itemUpdateInfo.actionDisabled = !canEdit;
    itemUpdateInfo.rowHeight = 60.f;
    itemUpdateInfo.type = TeamCardRowItemTypeSelected;
    itemUpdateInfo.optionItems = [NIMTeamHelper updateInfoModeItemsWithSeleced:self.teamListManager.team.updateInfoMode];
    itemUpdateInfo.selectedBlock = ^(id<NIMKitSelectCardData> item) {
        [weakSelf didUpdateTeamInfoMode:[item.value integerValue]];
    };
    
    NIMTeamCardRowItem *itemBeInvite = [[NIMTeamCardRowItem alloc] init];
    itemBeInvite.title  = @"被邀请人身份验证".nim_localized;
    itemBeInvite.subTitle = [NIMTeamHelper beInviteModeText:self.teamListManager.team.beInviteMode];
    itemBeInvite.actionDisabled = !canEdit;
    itemBeInvite.rowHeight = 60.f;
    itemBeInvite.type = TeamCardRowItemTypeSelected;
    itemBeInvite.optionItems = [NIMTeamHelper beInviteModeItemsWithSeleced:self.teamListManager.team.beInviteMode];
    itemBeInvite.selectedBlock = ^(id<NIMKitSelectCardData> item) {
        [weakSelf didUpdateTeamBeInviteMode:[item.value integerValue]];
    };
    
    NIMTeamCardRowItem *itemTop = [[NIMTeamCardRowItem alloc] init];
    itemTop.title            = @"聊天置顶".nim_localized;
    itemTop.switchOn         = self.option.isTop;
    itemTop.rowHeight        = 50.f;
    itemTop.type             = TeamCardRowItemTypeSwitch;
    itemTop.identify         = NIMTeamCardSwithCellTypeTop;
    
    if (isOwner) {
        ret = @[
                  @[teamMember],
                  @[teamType,teamName,teamNick,teamIntro,teamAnnouncement,teamMute,teamMuteList, teamNotify, itemTop],
                  @[itemAuth],
                  @[itemInvite,itemUpdateInfo,itemBeInvite],
                  @[itemDismiss],
                 ];
    } else if (isManager){
        ret = @[
                 @[teamMember],
                 @[teamType,teamName,teamNick,teamIntro,teamAnnouncement,teamMute, teamMuteList,teamNotify, itemTop],
                 @[itemAuth],
                 @[itemInvite,itemUpdateInfo,itemBeInvite],
                 @[itemQuit],
              ];
    } else {
        ret = @[
                  @[teamMember],
                  @[teamType,teamName,teamNick,teamIntro,teamAnnouncement,teamMute,teamNotify, itemTop],
                  @[itemQuit],
               ];
    }
    return ret;
}

#pragma mark - Refresh
- (void)reloadTableHeaderData {
    _headerView.team = self.teamListManager.team;
}

- (void)reloadTableViewData {
    self.datas = [self buildBodyData];
}

- (void)reloadOtherData {
    [self.teamListManager reloadMyTeamInfo];
    self.navigationItem.title  = self.teamListManager.team.teamName;
    if (self.teamListManager.myTeamInfo.type == NIMTeamMemberTypeOwner) {
        UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                    target:self
                                                                                    action:@selector(onMore:)];
        self.navigationItem.rightBarButtonItem = buttonItem;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

#pragma mark - Actions
- (void)onMore:(id)sender{
    __weak typeof(self) weakSelf = self;
    UIAlertAction *action0 = [UIAlertAction actionWithTitle:@"转让群".nim_localized
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf didOntransferWithLeave:NO];
    }];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"转让群并退出".nim_localized
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf didOntransferWithLeave:YES];
    }];
    
    UIAlertController *alert = [self makeAlertSheetWithTitle:@"请操作".nim_localized
                                                     actions:@[action0, action1]];
    [self showAlert:alert];
}

- (void)onTouchAvatar:(id)sender{
    if(![NIMKitUtil canEditTeamInfo:self.teamListManager.myTeamInfo])
        return ;
    __weak typeof(self) weakSelf = self;
    UIAlertAction *action0 = [UIAlertAction actionWithTitle:@"拍照".nim_localized style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf didUpdateTeamAvatarWithType:UIImagePickerControllerSourceTypeCamera];
    }];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"从相册".nim_localized style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf didUpdateTeamAvatarWithType:UIImagePickerControllerSourceTypePhotoLibrary];
    }];
    
    UIAlertController *alert = [self makeAlertSheetWithTitle:@"设置群头像".nim_localized
                                                     actions:@[action0, action1]];
    [self showAlert:alert];
}

- (void)updateTeamName{
    __weak typeof(self) weakSelf = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"修改群名称".nim_localized message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:nil];
    UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确认".nim_localized style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *input = alert.textFields.firstObject;
        [weakSelf didUpdateTeamName:input.text];
    }];
    [alert addAction:sure];
    [alert addAction:[self makeCancelAction]];
    [self showAlert:alert];
}

- (void)updateTeamNick{
    __weak typeof(self) weakSelf = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"修改群昵称".nim_localized message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:nil];
    UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确认".nim_localized style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *input = alert.textFields.firstObject;
        [weakSelf didUpdateTeamNick:input.text];
    }];
    [alert addAction:sure];
    [alert addAction:[self makeCancelAction]];
    [self showAlert:alert];
}

- (void)updateTeamIntro{
    __weak typeof(self) weakSelf = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"修改群介绍".nim_localized message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:nil];
    UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确认".nim_localized style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *input = alert.textFields.firstObject;
        [weakSelf didUpdateTeamIntro:input.text];
    }];
    [alert addAction:sure];
    [alert addAction:[self makeCancelAction]];
    [self showAlert:alert];
}

- (void)updateTeamAnnouncement{
    NIMTeamAnnouncementListOption *option = [[NIMTeamAnnouncementListOption alloc] init];
    option.canCreateAnnouncement = [NIMKitUtil canEditTeamInfo:self.teamListManager.myTeamInfo];
    option.announcement = self.teamListManager.team.announcement;
    option.nick = self.teamListManager.myTeamInfo.nickname;
    NIMTeamAnnouncementListViewController *vc = [[NIMTeamAnnouncementListViewController alloc] initWithOption:option];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)quitTeam {
    __weak typeof(self) weakSelf = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认退出群聊?".nim_localized message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确认".nim_localized style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf didQuitTeam];
    }];
    [alert addAction:sure];
    [alert addAction:[self makeCancelAction]];
    [self showAlert:alert];
}

- (void)dismissTeam {
    __weak typeof(self) weakSelf = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认解散群聊?".nim_localized message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确认".nim_localized style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf didDismissTeam];
    }];
    [alert addAction:sure];
    [alert addAction:[self makeCancelAction]];
    [self showAlert:alert];
}

- (void)enterMemberCard{
    NIMTeamMemberListViewController *vc = [[NIMTeamMemberListViewController alloc] initWithDataSource:self.teamListManager];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)enterMuteList {
    NIMTeamMuteMemberListViewController *vc = [[NIMTeamMuteMemberListViewController alloc] initWithDataSource:self.teamListManager];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - NIMTeamSwitchProtocol
- (void)cell:(NIMTeamSwitchTableViewCell *)cell onStateChanged:(BOOL)on{
    if (cell.identify == NIMTeamCardSwithCellTypeTop) {
        if ([self.delegate respondsToSelector:@selector(NIMTeamCardVCDidSetTop:)]) {
            [self.delegate NIMTeamCardVCDidSetTop:on];
        }
    }
}

#pragma mark - NIMTeamAnnouncementListVCDelegate
- (void)didUpdateAnnouncement:(NSString *)content
                   completion:(void (^)(NSError *error))completion {
    [self.teamListManager updateTeamAnnouncement:content
                             completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        if (completion) {
            completion(error);
        }
    }];
}

#pragma mark - NIMTeamMemberListCellActionDelegate
- (void)didSelectAddOpeartor{
    NSMutableArray *users = [self.teamListManager memberIds];
    NSString *currentUserID = [self.teamListManager myAccount];
    [users addObject:currentUserID];
    
    NIMContactFriendSelectConfig *config = [[NIMContactFriendSelectConfig alloc] init];
    config.filterIds = users;
    config.needMutiSelected = YES;
    NIMContactSelectViewController *vc = [[NIMContactSelectViewController alloc] initWithConfig:config];
    vc.delegate = self;
    [vc show];
}

#pragma mark - ContactSelectDelegate
- (void)didFinishedSelect:(NSArray *)selectedContacts{
    [self didInviteUsers:selectedContacts completion:nil];
}

#pragma mark - Function
- (void)didOntransferWithLeave:(BOOL)isLeave {
    __weak typeof(self) wself = self;
    __block ContactSelectFinishBlock finishBlock =  ^(NSArray * memeber){
        NSString *newOwnerId = memeber.firstObject;
        [wself didOntransferToUser:newOwnerId leave:isLeave];
    };
    NSString *currentUserID = [self.teamListManager myAccount];
    NIMContactTeamMemberSelectConfig *config = [[NIMContactTeamMemberSelectConfig alloc] init];
    config.session = self.teamListManager.session;
    config.teamType = NIMKitTeamTypeNomal;
    config.teamId = self.teamListManager.team.teamId;
    config.filterIds = @[currentUserID];
    NIMContactSelectViewController *vc = [[NIMContactSelectViewController alloc] initWithConfig:config];
    vc.finshBlock = finishBlock;
    [vc show];
}

#pragma mark - Getter
- (NIMTeamCardHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[NIMTeamCardHeaderView alloc] init];
        _headerView.delegate = self;
        _headerView.team = self.teamListManager.team;
        _headerView.nim_size = [_headerView sizeThatFits:self.view.nim_size];
    }
    return _headerView;
}

@end
