//
//  NIMAdvancedTeamCardViewController.m
//  NIM
//
//  Created by chris on 15/3/25.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMAdvancedTeamCardViewController.h"
#import "NIMTeamCardRowItem.h"
#import "UIView+NIM.h"
#import "UIImage+NIMKit.h"
#import "NIMKitDependency.h"
#import "NIMTeamMemberCardViewController.h"
#import "NIMCardMemberItem.h"
#import "NIMContactSelectViewController.h"
#import "NIMTeamMemberListViewController.h"
#import "NIMTeamAnnouncementListViewController.h"
#import "NIMKitUtil.h"
#import "NIMKitProgressHUD.h"
#import "NIMTeamCardHeaderView.h"
#import "NIMTeamListDataManager.h"

@interface NIMAdvancedTeamCardViewController ()<NIMTeamMemberListCellActionDelegate,
                                                NIMContactSelectDelegate,
                                                NIMTeamSwitchProtocol,
                                                NIMTeamManagerDelegate,
                                                NIMTeamCardHeaderViewDelegate,
                                                NIMTeamAnnouncementListVCDelegate>

@property (nonatomic,strong) NIMTeamCardHeaderView *headerView;
@property (nonatomic,strong) NIMTeamCardViewControllerOption *option;
@property (nonatomic, strong) NIMTeamListDataManager *dataSource;

@end

@implementation NIMAdvancedTeamCardViewController

- (void)dealloc {
    [[NIMSDK sharedSDK].teamManager removeDelegate:self];
}

- (instancetype)initWithTeam:(NIMTeam *)team
                     session:(NIMSession *)session
                      option:(NIMTeamCardViewControllerOption *)option {
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        _option = option;
        _dataSource = [[NIMTeamListDataManager alloc] initWithTeam:team
                                                           session:session];
        [[NIMSDK sharedSDK].teamManager addDelegate:self];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self didFetchTeamMember];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
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
    cell.disableInvite = ![NIMKitUtil canInviteMemberToTeam:_dataSource.myTeamInfo];
    NSMutableArray <NIMKitInfo *>*memberInfos = [NSMutableArray array];
    for (int i = 0; i < MIN(cell.maxShowMemberCount, _dataSource.members.count); i++) {
        NIMTeamMember *obj = _dataSource.members[i];
        NIMKitInfo *info = [[NIMKit sharedKit] infoByUser:obj.userId option:nil];
        [memberInfos addObject:info];
    }
    cell.infos = memberInfos;
}

#pragma mark - Data
- (NSArray<NSArray<NIMTeamCardRowItem *> *> *)buildBodyData{
    NSArray *ret = nil;
    __weak typeof(self) weakSelf = self;
    BOOL canEdit = [NIMKitUtil canEditTeamInfo:_dataSource.myTeamInfo];
    BOOL isOwner    = _dataSource.myTeamInfo.type == NIMTeamMemberTypeOwner;
    BOOL isManager  = _dataSource.myTeamInfo.type == NIMTeamMemberTypeManager;
    
    NIMTeamCardRowItem *teamMember = [[NIMTeamCardRowItem alloc] init];
    teamMember.title  = @"群成员";
    teamMember.rowHeight = 111.f;
    teamMember.action = @selector(enterMemberCard);
    teamMember.type   = TeamCardRowItemTypeTeamMember;
    
    NIMTeamCardRowItem *teamType = [[NIMTeamCardRowItem alloc] init];
    teamType.title = @"群类型";
    teamType.subTitle = @"高级群";
    teamType.rowHeight = 50.f;
    teamType.type   = TeamCardRowItemTypeCommon;
    teamType.actionDisabled = YES;
    
    NIMTeamCardRowItem *teamName = [[NIMTeamCardRowItem alloc] init];
    teamName.title = @"群名称";
    teamName.subTitle = _dataSource.team.teamName;
    teamName.action = @selector(updateTeamName);
    teamName.rowHeight = 50.f;
    teamName.type   = TeamCardRowItemTypeCommon;
    teamName.actionDisabled = !canEdit;
    
    NIMTeamCardRowItem *teamNick = [[NIMTeamCardRowItem alloc] init];
    teamNick.title = @"群昵称";
    teamNick.subTitle = _dataSource.myTeamInfo.nickname;
    teamNick.action = @selector(updateTeamNick);
    teamNick.rowHeight = 50.f;
    teamNick.type   = TeamCardRowItemTypeCommon;

    
    NIMTeamCardRowItem *teamIntro = [[NIMTeamCardRowItem alloc] init];
    teamIntro.title = @"群介绍";
    teamIntro.subTitle = _dataSource.team.intro.length ? _dataSource.team.intro : (canEdit ? @"点击填写群介绍" : @"");
    teamIntro.action = @selector(updateTeamIntro);
    teamIntro.rowHeight = 50.f;
    teamIntro.type   = TeamCardRowItemTypeCommon;
    teamIntro.actionDisabled = !canEdit;
    
    NIMTeamCardRowItem *teamAnnouncement = [[NIMTeamCardRowItem alloc] init];
    teamAnnouncement.title = @"群公告";
    teamAnnouncement.subTitle = @"点击查看群公告";//self.team.announcement.length ? self.team.announcement : (isManager ? @"点击填写群公告" : @"");
    teamAnnouncement.action = @selector(updateTeamAnnouncement);
    teamAnnouncement.rowHeight = 50.f;
    teamAnnouncement.type   = TeamCardRowItemTypeCommon;
    
    NIMTeamCardRowItem *teamNotify = [[NIMTeamCardRowItem alloc] init];
    teamNotify.title  = @"消息提醒";
    teamNotify.subTitle = _dataSource.notifyStateText;
    teamNotify.rowHeight = 50.f;
    teamNotify.type = TeamCardRowItemTypeSelected;
    teamNotify.optionItems = [self itemsWithListDic:_dataSource.allNotifyStates
                                        selectValue:_dataSource.notifyState];
    teamNotify.selectedBlock = ^(id<NIMKitSelectCardData> item) {
        [weakSelf didUpdateTeamNotify:[item.value integerValue]];
    };

    NIMTeamCardRowItem *itemQuit = [[NIMTeamCardRowItem alloc] init];
    itemQuit.title = @"退出高级群";
    itemQuit.action = @selector(quitTeam);
    itemQuit.rowHeight = 60.f;
    itemQuit.type   = TeamCardRowItemTypeRedButton;
    
    NIMTeamCardRowItem *itemDismiss = [[NIMTeamCardRowItem alloc] init];
    itemDismiss.title  = @"解散群聊";
    itemDismiss.action = @selector(dismissTeam);
    itemDismiss.rowHeight = 60.f;
    itemDismiss.type   = TeamCardRowItemTypeRedButton;
    
    
    NIMTeamCardRowItem *itemAuth = [[NIMTeamCardRowItem alloc] init];
    itemAuth.title  = @"身份验证";
    itemAuth.subTitle = _dataSource.joinModeText;
    itemAuth.actionDisabled = !canEdit;
    itemAuth.rowHeight = 60.f;
    itemAuth.type   = TeamCardRowItemTypeSelected;
    itemAuth.optionItems = [self itemsWithListDic:_dataSource.allJoinModes
                                      selectValue:_dataSource.team.joinMode];
    itemAuth.selectedBlock = ^(id<NIMKitSelectCardData> item) {
        [weakSelf didUpdateTeamJoneMode:[item.value integerValue]];
    };
    
    NIMTeamCardRowItem *itemInvite = [[NIMTeamCardRowItem alloc] init];
    itemInvite.title  = @"邀请他人权限";
    itemInvite.subTitle = _dataSource.inviteModeText;
    itemInvite.actionDisabled = !canEdit;
    itemInvite.rowHeight = 60.f;
    itemInvite.type = TeamCardRowItemTypeSelected;
    itemInvite.optionItems = [self itemsWithListDic:_dataSource.allInviteModes
                                        selectValue:_dataSource.team.inviteMode];
    itemInvite.selectedBlock = ^(id<NIMKitSelectCardData> item) {
        [weakSelf didUpdateTeamInviteMode:[item.value integerValue]];
    };
    
    NIMTeamCardRowItem *itemUpdateInfo = [[NIMTeamCardRowItem alloc] init];
    itemUpdateInfo.title  = @"群资料修改权限";
    itemUpdateInfo.subTitle = _dataSource.updateInfoModeText;
    itemUpdateInfo.actionDisabled = !canEdit;
    itemUpdateInfo.rowHeight = 60.f;
    itemUpdateInfo.type = TeamCardRowItemTypeSelected;
    itemUpdateInfo.optionItems = [self itemsWithListDic:_dataSource.allUpdateInfoModes
                                            selectValue:_dataSource.team.updateInfoMode];
    itemUpdateInfo.selectedBlock = ^(id<NIMKitSelectCardData> item) {
        [weakSelf didUpdateTeamInfoMode:[item.value integerValue]];
    };
    
    NIMTeamCardRowItem *itemBeInvite = [[NIMTeamCardRowItem alloc] init];
    itemBeInvite.title  = @"被邀请人身份验证";
    itemBeInvite.subTitle = _dataSource.beInviteModeText;
    itemBeInvite.actionDisabled = !canEdit;
    itemBeInvite.rowHeight = 60.f;
    itemBeInvite.type = TeamCardRowItemTypeSelected;
    itemBeInvite.optionItems = [self itemsWithListDic:_dataSource.allBeInviteModes
                                          selectValue:_dataSource.team.beInviteMode];
    itemBeInvite.selectedBlock = ^(id<NIMKitSelectCardData> item) {
        [weakSelf didUpdateTeamBeInviteMode:[item.value integerValue]];
    };
    
    NIMTeamCardRowItem *itemTop = [[NIMTeamCardRowItem alloc] init];
    itemTop.title            = @"聊天置顶";
    itemTop.switchOn         = _option.isTop;
    itemTop.rowHeight        = 50.f;
    itemTop.type             = TeamCardRowItemTypeSwitch;
    itemTop.identify         = NIMTeamCardSwithCellTypeTop;
    
    if (isOwner) {
        ret = @[
                  @[teamMember],
                  @[teamType,teamName,teamNick,teamIntro,teamAnnouncement,teamNotify, itemTop],
                  @[itemAuth],
                  @[itemInvite,itemUpdateInfo,itemBeInvite],
                  @[itemDismiss],
                 ];
    } else if (isManager){
        ret = @[
                 @[teamMember],
                 @[teamType,teamName,teamNick,teamIntro,teamAnnouncement,teamNotify, itemTop],
                 @[itemAuth],
                 @[itemInvite,itemUpdateInfo,itemBeInvite],
                 @[itemQuit],
              ];
    } else {
        ret = @[
                  @[teamMember],
                  @[teamType,teamName,teamNick,teamIntro,teamAnnouncement,teamNotify, itemTop],
                  @[itemQuit],
               ];
    }
    return ret;
}

#pragma mark - Refresh
- (void)reloadData{
    [_dataSource reloadMyTeamInfo];
    [self refreshTitle];
    [self refreshTableHeader];
    [self refreshTableBody];
}

- (void)refreshTitle {
    self.navigationItem.title  = _dataSource.team.teamName;
    if (_dataSource.myTeamInfo.type == NIMTeamMemberTypeOwner) {
        UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                    target:self
                                                                                    action:@selector(onMore:)];
        self.navigationItem.rightBarButtonItem = buttonItem;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)refreshTableHeader {
    _headerView.dataModel.teamName = _dataSource.team.teamName;
    [_headerView reloadData];
}

- (void)refreshTableBody {
    self.datas = [self buildBodyData];
}

#pragma mark - NIMTeamManagerDelegate
- (void)onTeamMemberChanged:(NIMTeam *)team {
    [self didFetchTeamMember];
}

#pragma mark - Actions
- (void)onMore:(id)sender{
    __weak typeof(self) weakSelf = self;
    UIAlertAction *action0 = [UIAlertAction actionWithTitle:@"转让群"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf didOntransferWithLeave:NO];
    }];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"转让群并退出"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf didOntransferWithLeave:YES];
    }];
    
    UIAlertController *alert = [self makeAlertSheetWithTitle:@"请操作"
                                                     actions:@[action0, action1]];
    [self showAlert:alert];
}

- (void)onTouchAvatar:(id)sender{
    if(![NIMKitUtil canEditTeamInfo:_dataSource.myTeamInfo])
        return ;
    __weak typeof(self) weakSelf = self;
    UIAlertAction *action0 = [UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf didUpdateTeamAvatarWithType:UIImagePickerControllerSourceTypeCamera];
    }];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"从相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf didUpdateTeamAvatarWithType:UIImagePickerControllerSourceTypePhotoLibrary];
    }];
    
    UIAlertController *alert = [self makeAlertSheetWithTitle:@"设置群头像"
                                                     actions:@[action0, action1]];
    [self showAlert:alert];
}

- (void)updateTeamName{
    __weak typeof(self) weakSelf = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"修改群名称" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:nil];
    UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *input = alert.textFields.firstObject;
        [weakSelf didUpdateTeamName:input.text];
    }];
    [alert addAction:sure];
    [alert addAction:[self makeCancelAction]];
    [self showAlert:alert];
}

- (void)updateTeamNick{
    __weak typeof(self) weakSelf = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"修改群昵称" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:nil];
    UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *input = alert.textFields.firstObject;
        [weakSelf didUpdateTeamNick:input.text];
    }];
    [alert addAction:sure];
    [alert addAction:[self makeCancelAction]];
    [self showAlert:alert];
}

- (void)updateTeamIntro{
    __weak typeof(self) weakSelf = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"修改群介绍" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:nil];
    UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *input = alert.textFields.firstObject;
        [weakSelf didUpdateTeamIntro:input.text];
    }];
    [alert addAction:sure];
    [alert addAction:[self makeCancelAction]];
    [self showAlert:alert];
}

- (void)updateTeamAnnouncement{
    NIMTeamAnnouncementListOption *option = [[NIMTeamAnnouncementListOption alloc] init];
    option.canCreateAnnouncement = [NIMKitUtil canEditTeamInfo:_dataSource.myTeamInfo];
    option.announcement = _dataSource.team.announcement;
    option.nick = _dataSource.myTeamInfo.nickname;
    NIMTeamAnnouncementListViewController *vc = [[NIMTeamAnnouncementListViewController alloc] initWithOption:option];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)quitTeam {
    __weak typeof(self) weakSelf = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认退出群聊?" message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf didQuitTeam];
    }];
    [alert addAction:sure];
    [alert addAction:[self makeCancelAction]];
    [self showAlert:alert];
}

- (void)dismissTeam {
    __weak typeof(self) weakSelf = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认解散群聊?" message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf didDismissTeam];
    }];
    [alert addAction:sure];
    [alert addAction:[self makeCancelAction]];
    [self showAlert:alert];
}

- (void)enterMemberCard{
    NIMTeamMemberListViewController *vc = [[NIMTeamMemberListViewController alloc] initWithDataSource:_dataSource];
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
    [_dataSource updateTeamAnnouncement:content
                             completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        if (completion) {
            completion(error);
        }
    }];
}

#pragma mark - NIMTeamMemberListCellActionDelegate
- (void)didSelectAddOpeartor{
    NSMutableArray *users = [_dataSource memberIds];
    NSString *currentUserID = [_dataSource myAccount];
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
    if (!selectedContacts.count) {
        return;
    }
    NSDictionary *info = @{
                           @"postscript" : @"邀请你加入群组",
                           @"attach" : @"扩展消息"
                           };
    __weak typeof(self) weakself = self;
    [_dataSource addUsers:selectedContacts
                     info:info
               completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        [weakself showToastMsg:msg];
    }];
}

#pragma mark - Function
- (void)didFetchTeamMember {
    __weak typeof(self) wself = self;
    [_dataSource fetchTeamMembersWithOption:nil
                                 completion:^(NSError * _Nullable error, NSString * _Nullable msg) {
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
            [weakSelf reloadData];
        }
        [weakSelf showToastMsg:msg];
    }];
}

- (void)didUpdateTeamNick:(NSString *)nick{
    if (!nick) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [_dataSource updateTeamNick:nick completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        if (!error) {
            [weakSelf reloadData];
        }
        [weakSelf showToastMsg:msg];
    }];
}

- (void)didUpdateTeamIntro:(NSString *)intro{
    if (!intro) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [_dataSource updateTeamIntro:intro completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        if (!error) {
            [weakSelf reloadData];
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

- (void)didDismissTeam{
    __weak typeof(self) weakSelf = self;
    [_dataSource dismissTeamCompletion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        if (!error) {
            [weakSelf.navigationController popToRootViewControllerAnimated:YES];
        }
        [weakSelf showToastMsg:msg];
    }];
}

- (void)didUpdateTeamAvatarWithType:(UIImagePickerControllerSourceType)type {
    __weak typeof(self) weakSelf = self;
    [self showImagePicker:type completion:^(UIImage * _Nonnull image) {
        [weakSelf uploadImage:image];
    }];
}

- (void)didOntransferWithLeave:(BOOL)isLeave {
    __weak typeof(self) wself = self;
    __block ContactSelectFinishBlock finishBlock =  ^(NSArray * memeber){
        NSString *newOwnerId = memeber.firstObject;
        [wself.dataSource ontransferWithNewOwnerId:newOwnerId
                                             leave:isLeave
                                        completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
            if (isLeave) {
                [wself.navigationController popToRootViewControllerAnimated:YES];
            }else{
                [wself reloadData];
            }
            [wself showToastMsg:msg];
        }];
    };
    NSString *currentUserID = [_dataSource myAccount];
    NIMContactTeamMemberSelectConfig *config = [[NIMContactTeamMemberSelectConfig alloc] init];
    config.session = _dataSource.session;
    config.teamType = NIMKitTeamTypeNomal;
    config.teamId = _dataSource.team.teamId;
    config.filterIds = @[currentUserID];
    NIMContactSelectViewController *vc = [[NIMContactSelectViewController alloc] initWithConfig:config];
    vc.finshBlock = finishBlock;
    [vc show];
}

- (void)didUpdateTeamJoneMode:(NIMTeamJoinMode)mode {
    __weak typeof(self) weakSelf = self;
    [_dataSource updateTeamJoneMode:mode completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        if (!error) {
            [weakSelf reloadData];
        }
        [weakSelf showToastMsg:msg];
    }];
}

- (void)didUpdateTeamInviteMode:(NIMTeamInviteMode)mode {
    __weak typeof(self) weakSelf = self;
    [_dataSource updateTeamInviteMode:mode completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        if (!error) {
            [weakSelf reloadData];
        }
        [weakSelf showToastMsg:msg];
    }];
}

- (void)didUpdateTeamInfoMode:(NIMTeamUpdateInfoMode)mode {
    __weak typeof(self) weakSelf = self;
    [_dataSource updateTeamInfoMode:mode completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        if (!error) {
            [weakSelf reloadData];
        }
        [weakSelf showToastMsg:msg];
    }];
}

- (void)didUpdateTeamBeInviteMode:(NIMTeamBeInviteMode)mode {
    __weak typeof(self) weakSelf = self;
    [_dataSource updateTeamBeInviteMode:mode completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        if (!error) {
            [weakSelf reloadData];
        }
        [weakSelf showToastMsg:msg];
    }];
}

- (void)didUpdateTeamNotify:(NIMKitTeamNotifyState)state {
    __weak typeof(self) weakSelf = self;
    [_dataSource updateTeamNotifyState:state completion:^(NSError * _Nullable error, NSString * _Nullable msg) {
        if (!error) {
            [weakSelf reloadData];
        }
        [weakSelf showToastMsg:msg];
    }];
}

#pragma mark - Private
- (void)uploadImage:(UIImage *)image {
    UIImage *imageForAvatarUpload = [image nim_imageForAvatarUpload];
    NSString *fileName = [[[[NSUUID UUID] UUIDString] lowercaseString] stringByAppendingPathExtension:@"jpg"];
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    NSData *data = UIImageJPEGRepresentation(imageForAvatarUpload, 1.0);
    BOOL success = data && [data writeToFile:filePath atomically:YES];
    __weak typeof(self) wself = self;
    if (success) {
        [NIMKitProgressHUD show];
        __weak typeof(self) weakSelf = self;
        [_dataSource updateTeamAvatar:filePath completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
            if (!error) {
                NSString *urlString = weakSelf.dataSource.team.avatarUrl;
                SDWebImageManager *sdManager = [SDWebImageManager sharedManager];
                [sdManager.imageCache storeImage:imageForAvatarUpload
                                       imageData:data
                                          forKey:urlString
                                       cacheType:SDImageCacheTypeAll
                                      completion:nil];
                wself.headerView.dataModel.avatarUrl = urlString;
                [wself.headerView reloadData];
            }
            [wself showToastMsg:msg];
        }];
    } else {
        [wself showToastMsg:@"图片保存失败，请重试"];
    }
}

#pragma mark - Helper


#pragma mark - Getter
- (NIMTeamCardHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[NIMTeamCardHeaderView alloc] init];
        NIMTeamCardHeaderViewModel *headerModel = [[NIMTeamCardHeaderViewModel alloc] initWithTeam:_dataSource.team];
        _headerView.dataModel = headerModel;
        _headerView.delegate = self;
        _headerView.nim_size = [_headerView sizeThatFits:self.view.nim_size];
    }
    return _headerView;
}

@end
