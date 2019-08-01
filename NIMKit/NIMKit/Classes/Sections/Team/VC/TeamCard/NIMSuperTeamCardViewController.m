//
//  NIMSuperTeamCardViewController.m
//  NIMKit
//
//  Created by Netease on 2019/6/10.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "NIMSuperTeamCardViewController.h"
#import "NIMTeamCardHeaderView.h"
#import "NIMTeamCardRowItem.h"
#import "UIView+NIM.h"
#import "UIImage+NIMKit.h"
#import "NIMKitUtil.h"
#import "NIMKitDependency.h"
#import "NIMKitProgressHUD.h"
#import "NIMContactSelectViewController.h"
#import "NIMTeamAnnouncementListViewController.h"
#import "NIMSuperTeamListDataManager.h"
#import "NIMTeamMemberListViewController.h"

#define NIMSuperTeamCardShowMaxMemberCount (10)  //这个页面显示10个已经够了

@interface NIMSuperTeamCardViewController () <NIMTeamManagerDelegate,
                                              NIMTeamCardHeaderViewDelegate,
                                              NIMTeamSwitchProtocol,
                                              NIMTeamMemberListCellActionDelegate,
                                              NIMContactSelectDelegate,
                                              NIMTeamAnnouncementListVCDelegate>

@property (nonatomic, strong) NIMTeamCardHeaderView *headerView;
@property (nonatomic, strong) NIMSuperTeamListDataManager *dataSource;
@property (nonatomic, strong) NIMTeamCardViewControllerOption *option;
@end

@implementation NIMSuperTeamCardViewController

- (void)dealloc {
    [[NIMSDK sharedSDK].superTeamManager removeDelegate:self];
}

- (instancetype)initWithTeam:(NIMTeam *)team
                     session:(NIMSession *)session
                      option:(NIMTeamCardViewControllerOption *)option {
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        _option = option;
        _dataSource = [[NIMSuperTeamListDataManager alloc] initWithTeam:team
                                                                session:session];
        [[NIMSDK sharedSDK].superTeamManager addDelegate:self];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self didLoadTeamMember];
}

#pragma mark - overload
- (UIView *)didGetHeaderView {
    return self.headerView;
}

- (void)didBuildTeamMemberCell:(NIMTeamMemberListCell *)cell {
    cell.delegate = self;
    cell.disableInvite = ![NIMKitUtil canInviteMemberToSuperTeam:_dataSource.myTeamInfo];
    NSMutableArray <NIMKitInfo *>*memberInfos = [NSMutableArray array];
    for (int i = 0; i < MIN(cell.maxShowMemberCount, _dataSource.members.count); i++) {
        NIMTeamMember *obj = _dataSource.members[i];
        NIMKitInfo *info = [[NIMKit sharedKit] infoByUser:obj.userId option:nil];
        [memberInfos addObject:info];
    }
    cell.infos = memberInfos;
}

- (void)didBuildTeamSwitchCell:(NIMTeamSwitchTableViewCell *)cell {
    cell.switchDelegate = self;
}

#pragma mark - Data
- (NSArray<NSArray<NIMTeamCardRowItem *> *> *)buildBodyData {
    NSArray *ret = nil;
    BOOL canEdit = [NIMKitUtil canEditSuperTeamInfo:_dataSource.myTeamInfo];
    BOOL isOwner = _dataSource.myTeamInfo.type == NIMTeamMemberTypeOwner;
    __weak typeof(self) weakSelf = self;
    
    NIMTeamCardRowItem *teamType = [[NIMTeamCardRowItem alloc] init];
    teamType.title = @"群类型";
    teamType.subTitle = @"超大群";
    teamType.rowHeight = 50.f;
    teamType.type   = TeamCardRowItemTypeCommon;
    teamType.actionDisabled = YES;
    
    NIMTeamCardRowItem *teamMember = [[NIMTeamCardRowItem alloc] init];
    teamMember.title  = @"群成员";
    teamMember.rowHeight = 111.f;
    teamMember.action = @selector(enterMemberCard);
    teamMember.type   = TeamCardRowItemTypeTeamMember;
    
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
    
    NIMTeamCardRowItem *itemQuit = [[NIMTeamCardRowItem alloc] init];
    itemQuit.title = @"退出超大群";
    itemQuit.action = @selector(quitTeam);
    itemQuit.rowHeight = 60.f;
    itemQuit.type   = TeamCardRowItemTypeRedButton;
    
    NIMTeamCardRowItem *itemTop = [[NIMTeamCardRowItem alloc] init];
    itemTop.title            = @"聊天置顶";
    itemTop.switchOn         = _option.isTop;
    itemTop.rowHeight        = 50.f;
    itemTop.type             = TeamCardRowItemTypeSwitch;
    
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
    
    if (isOwner) {
        ret = @[
                  @[teamMember],
                  @[teamType,teamName,teamNick,teamIntro,teamAnnouncement, teamNotify, itemTop],
                ];
    } else {
        ret = @[
                  @[teamMember],
                  @[teamType,teamName,teamNick,teamIntro,teamAnnouncement, teamNotify, itemTop],
                  @[itemQuit],
                ];
    }
    return ret;
}

#pragma mark - Refresh
- (void)reloadData {
    [_dataSource reloadMyTeamInfo];
    [self refreshTitle];
    [self refreshTableHeader];
    [self refreshTableBody];
}

- (void)refreshTitle {
    self.navigationItem.title  = _dataSource.team.teamName;
}

- (void)refreshTableHeader {
    _headerView.dataModel.teamName = _dataSource.team.teamName;
    [_headerView reloadData];
}

- (void)refreshTableBody {
    self.datas = [self buildBodyData];
}

#pragma mark - Fountion
- (void)didLoadTeamMember {
    __weak typeof(self) wself = self;
    NIMMembersFetchOption *option = [[NIMMembersFetchOption alloc] init];
    option.isRefresh = YES;
    option.offset = 0;
    NSInteger currentCount = _dataSource.members.count;
    option.count = currentCount == 0 ? NIMSuperTeamCardShowMaxMemberCount : currentCount;
    [_dataSource fetchTeamMembersWithOption:option
                                 completion:^(NSError * _Nullable error, NSString * _Nullable msg) {
        if (!error) {
            [wself reloadData];
        }
        [wself showToastMsg:msg];
    }];
}

- (void)didInviteUsers:(NSArray<NSString *> *)userIds {
    [NIMKitProgressHUD show];
    __weak typeof(self) wself = self;
    [_dataSource inviteUsers:userIds completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        [NIMKitProgressHUD dismiss];
        [wself showToastMsg:msg];
    }];
}

- (void)didUpdateTeamAvatarWithType:(UIImagePickerControllerSourceType)type {
    __weak typeof(self) weakSelf = self;
    [self showImagePicker:type completion:^(UIImage * _Nonnull image) {
        [weakSelf didUpdateTeamAvatar:image];
    }];
}

- (void)didUpdateTeamAvatar:(UIImage *)image {
    UIImage *imageForAvatarUpload = [image nim_imageForAvatarUpload];
    NSString *fileName = [[[[NSUUID UUID] UUIDString] lowercaseString] stringByAppendingPathExtension:@"jpg"];
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    NSData *data = UIImageJPEGRepresentation(imageForAvatarUpload, 1.0);
    BOOL success = data && [data writeToFile:filePath atomically:YES];
    __weak typeof(self) wself = self;
    if (success) {
        [NIMKitProgressHUD show];
        [_dataSource updateTeamAvatar:filePath completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
            [NIMKitProgressHUD dismiss];
            if (!error) {
                NSString *urlString = wself.dataSource.team.avatarUrl;
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

- (void)didUpdateTeamName:(NSString *)name {
    __weak typeof(self) weakSelf = self;
    [_dataSource updateTeamName:name completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        if (!error) {
            [weakSelf reloadData];
        }
        [weakSelf showToastMsg:msg];
    }];
}

- (void)didUpdateTeamNick:(NSString *)nick {
    __weak typeof(self) weakSelf = self;
    [_dataSource updateTeamNick:nick completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        if (!error) {
            [weakSelf reloadData];
        }
        [weakSelf showToastMsg:msg];
    }];
}

- (void)didUpdateTeamIntro:(NSString *)intro {
    __weak typeof(self) weakSelf = self;
    [_dataSource updateTeamIntro:intro completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        if (!error) {
            [weakSelf reloadData];
        }
        [weakSelf showToastMsg:msg];
    }];
}

- (void)didUpdateAnnouncement:(NSString *)content
                   completion:(void (^)(NSError *error))completion {
    [_dataSource updateTeamAnnouncement:content completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        if (completion) {
            completion(error);
        }
    }];
}

- (void)didUpdateTeamNotify:(NIMKitTeamNotifyState)state {
    __weak typeof(self) weakSelf = self;
    [_dataSource updateTeamNotifyState:state
                            completion:^(NSError * _Nullable error, NSString * _Nullable msg) {
                                if (!error) {
                                    [weakSelf reloadData];
                                }
                                [weakSelf showToastMsg:msg];
                            }];
}

- (void)didQuitTeam {
    __weak typeof(self) weakSelf = self;
    [_dataSource quitTeamCompletion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        if (!error) {
            [weakSelf.navigationController popToRootViewControllerAnimated:YES];
        } else {
            [weakSelf showToastMsg:msg];
        }
    }];
}

#pragma mark - Actions
- (void)enterMemberCard {
    NIMTeamMemberListViewController *vc = [[NIMTeamMemberListViewController alloc] initWithDataSource:_dataSource];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onTouchAvatar:(id)sender {
    if(![NIMKitUtil canEditSuperTeamInfo:_dataSource.myTeamInfo])
        return;
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

- (void)updateTeamName {
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

- (void)updateTeamNick {
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

- (void)updateTeamIntro {
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

- (void)updateTeamAnnouncement {
    NIMTeamAnnouncementListOption *option = [[NIMTeamAnnouncementListOption alloc] init];
    option.canCreateAnnouncement = [NIMKitUtil canEditSuperTeamInfo:_dataSource.myTeamInfo];
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

#pragma mark - NIMTeamManagerDelegate
- (void)onSuperTeamMemberChanged:(NIMTeam *)team {
    [self didLoadTeamMember];
}

#pragma mark - NIMTeamSwitchProtocol
- (void)cell:(NIMTeamSwitchTableViewCell *)cell onStateChanged:(BOOL)on {
    if (cell.identify == NIMTeamCardSwithCellTypeTop) {
        if ([self.delegate respondsToSelector:@selector(NIMTeamCardVCDidSetTop:)]) {
            [self.delegate NIMTeamCardVCDidSetTop:on];
        }
    }
}

#pragma mark - <NIMTeamMemberListCellActionDelegate>
- (void)didSelectAddOpeartor {
    NSMutableArray *users = [_dataSource memberIds];
    NSString *currentUserID = [[[NIMSDK sharedSDK] loginManager] currentAccount];
    [users addObject:currentUserID];
    
    NIMContactFriendSelectConfig *config = [[NIMContactFriendSelectConfig alloc] init];
    config.filterIds = users;
    config.needMutiSelected = YES;
    NIMContactSelectViewController *vc = [[NIMContactSelectViewController alloc] initWithConfig:config];
    vc.delegate = self;
    [vc show];
}

#pragma mark - NIMContactSelectDelegate
- (void)didFinishedSelect:(NSArray *)selectedContacts {
    [self didInviteUsers:selectedContacts];
}

#pragma mark - Getter
- (NIMTeamCardHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[NIMTeamCardHeaderView alloc] init];
        NIMTeamCardHeaderViewModel *headerModel = [[NIMTeamCardHeaderViewModel alloc] initWithSuperTeam:_dataSource.team];
        _headerView.dataModel = headerModel;
        _headerView.delegate = self;
        _headerView.nim_size = [_headerView sizeThatFits:self.view.nim_size];
    }
    return _headerView;
}

@end
