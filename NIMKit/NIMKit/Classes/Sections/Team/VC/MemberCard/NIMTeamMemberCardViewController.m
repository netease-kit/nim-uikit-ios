//
//  TeamMemberCardViewController.m
//  NIM
//
//  Created by Xuhui on 15/3/19.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMTeamMemberCardViewController.h"
#import "NIMCommonTableData.h"
#import "NIMCommonTableDelegate.h"
#import "NIMAvatarImageView.h"
#import "NIMTeamCardMemberItem.h"
#import "NIMKitUtil.h"
#import "NIMKitDependency.h"
#import "NIMKit.h"
#import "UIView+NIM.h"
#import "NIMKitColorButtonCell.h"
#import "NIMKitSwitcherCell.h"
#import "NIMKitInfoFetchOption.h"
#import "NIMTeamHelper.h"

@interface NIMTeamMemberCardViewController () <UIActionSheetDelegate>{
    UIAlertView *_kickAlertView;
    UIAlertView *_updateNickAlertView;
}

@property (nonatomic, copy) NSString *memberId;

@property (nonatomic, weak) NIMTeamCardMemberItem *member;

@property (nonatomic, weak) NIMTeamCardMemberItem *viewer;

@property (strong, nonatomic) UITableView *tableView;

@property (nonatomic,strong) NIMCommonTableDelegate *delegator;

@property (nonatomic,weak) id <NIMTeamMemberListDataSource> dataSource;

@property (nonatomic,strong) NSArray *data;

@end

@implementation NIMTeamMemberCardViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithMember:(NSString *)userId
                    dataSource:(id <NIMTeamMemberListDataSource>) dataSource {
    if (self = [super init]) {
        _memberId = userId;
        _dataSource = dataSource;
        extern NSString *kNIMTeamListDataTeamMembersChanged;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(teamMemberUpdate:) name:kNIMTeamListDataTeamMembersChanged object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"群名片".nim_localized;
    [self.view addSubview:self.tableView];
    
    [self refreshData];
    __weak typeof(self) wself = self;
    self.delegator = [[NIMCommonTableDelegate alloc] initWithTableData:^NSArray *{
        return wself.data;
    }];
    self.tableView.delegate   = self.delegator;
    self.tableView.dataSource = self.delegator;
}

- (NSArray *)buildData{
    NIMKitInfoFetchOption *option = [[NIMKitInfoFetchOption alloc] init];
    option.session = _dataSource.session;
    NIMKitInfo *usrInfo = [[NIMKit sharedKit] infoByUser:_member.userId option:option];
    NSDictionary *headerItem = @{
                                 CellClass     : @"NIMTeamMemberCardHeaderCell",
                                 RowHeight     : @(222),
                                 ExtraInfo     : @{@"user":usrInfo, @"userType":@(_member.userType)},
                                 SepLeftEdge   : @(SepLineLeft)
                                 };
    NSDictionary *nickItem = @{
                               Title         : @"群昵称".nim_localized,
                               DetailTitle   : (usrInfo.showName ?: @"未设置".nim_localized),
                               CellAction    : ([self isSelf] || [self canUpdateTeamMember])? @"updateTeamNick" : @"",
                               ShowAccessory : ([self isSelf] || [self canUpdateTeamMember])? @(YES) : @(NO),
                               RowHeight     : @(50),
                               SepLeftEdge   : @(SepLineLeft),
                               };
    
    NSDictionary *userTypeItem = @{
                                   Title         : @"身份".nim_localized,
                                   DetailTitle   : [NIMTeamHelper memberTypeText:self.member.userType],
                                   CellAction    : ([self isOwner] && ![self isSelf])? @"updateTeamRole" : @"",
                                   ShowAccessory : @([self canChangeUserType]),
                                   RowHeight     : @(50),
                                   SepLeftEdge   : @(SepLineLeft),
                                   };
    
    NSDictionary *inviterAccidItem = @{
                                       Title         : @"邀请人".nim_localized,
                                       DetailTitle   : _member.inviterAccid ? (_member.inviterAccid.length ? _member.inviterAccid : _member.userId) : @"本地不存在".nim_localized,
                                       CellAction    : @"",
                                       ShowAccessory : [self isOwner] && ![self isSelf]? @(YES) : @(NO),
                                       RowHeight     : @(50),
                                       SepLeftEdge   : @(SepLineLeft),
                                       };
    
    NSDictionary *isMuteItem =  @{
                                  Title         : @"设置禁言".nim_localized,
                                  CellClass     : @"NIMKitSwitcherCell",
                                  CellAction    : @"updateMute:",
                                  ForbidSelect  : @(YES),
                                  RowHeight     : @(50),
                                  DisableUserInteraction:@(![self canUpdateTeamMember]),
                                  ExtraInfo     : @(_member.isMuted),
                                  SepLeftEdge   : @(SepLineLeft),
                                  };
    
    NSDictionary *kickItem = @{
                               Title         : @"移出本群".nim_localized,
                               CellClass     : @"NIMKitColorButtonCell",
                               CellAction    : @"onKickBtnClick:",
                               ExtraInfo     : @(NIMKitColorButtonCellStyleRed),
                               RowHeight     : @(70),
                               Disable       : @([self isSelf] || ![self canKickTeamMember]),
                               SepLeftEdge   : @(0),
                               };
    
    NSArray *rowContent = nil;
    if (_member.teamType == NIMTeamTypeSuper) {
        rowContent = @[headerItem, nickItem, userTypeItem, isMuteItem, kickItem];
    } else {
        rowContent = @[headerItem, nickItem, userTypeItem, inviterAccidItem, isMuteItem, kickItem];
    }

    NSArray *data = @[
                      @{
                          HeaderTitle:@"",
                          RowContent :rowContent,
                          FooterTitle:@""
                          },
                       ];
    return [NIMCommonTableSection sectionsWithData:data];
}

- (void)refreshData{
    _viewer = _dataSource.myCard;
    _member = [_dataSource memberWithUserId:_memberId];
    self.data = [self buildData];
    [self.tableView reloadData];
}

- (void)onKickBtnClick:(id)sender {
    _kickAlertView = [[UIAlertView alloc] initWithTitle:@""
                                                message:@"移出本群".nim_localized
                                               delegate:self
                                      cancelButtonTitle:@"取消".nim_localized
                                      otherButtonTitles:@"确定".nim_localized, nil];
    [_kickAlertView show];
}

- (void)updateTeamNick
{
    _updateNickAlertView = [[UIAlertView alloc] initWithTitle:@""
                                                      message:@"修改群昵称".nim_localized
                                                     delegate:self
                                            cancelButtonTitle:@"取消".nim_localized
                                            otherButtonTitles:@"确认".nim_localized, nil];
    _updateNickAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [_updateNickAlertView show];
}

- (void)updateTeamRole
{
    if (![self canChangeUserType]) {
        return;
    }
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"管理员操作".nim_localized
                                                       delegate:self
                                              cancelButtonTitle:@"取消".nim_localized
                                         destructiveButtonTitle:nil
                                              otherButtonTitles: self.member.userType == NIMTeamMemberTypeManager ? @"取消管理员".nim_localized : @"设为管理员".nim_localized, nil];
    [sheet showInView:self.view];
}

- (void)updateMute:(UISwitch *)switcher {
    NSString *userId = self.member.userId;
    BOOL mute = switcher.on;
    __block typeof(self) wself = self;
    [_dataSource updateUserMuteState:userId mute:mute completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        [wself showToastMsg:msg];
        if (error) {
            switcher.on = !mute;
        }
        if (wself.delegate && [wself.delegate respondsToSelector:@selector(onTeamMemberMuted:mute:)]) {
            [wself.delegate onTeamMemberMuted:wself.member mute:mute];
        }
    }];
}

- (void)removeManager:(NSString *)memberId{
    NSString *userId = self.member.userId;
    __block typeof(self) wself = self;
    [_dataSource removeManagers:@[userId] completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        [wself showToastMsg:msg];
    }];
}

- (void)addManager:(NSString *)memberId{
    if (!memberId) {
        return;
    }
    __block typeof(self) wself = self;
    [_dataSource addManagers:@[memberId] completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        [wself showToastMsg:msg];
    }];
}

- (void)teamMemberUpdate:(NSNotification *)note {
    [self refreshData];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (alertView == _kickAlertView) {
        if(alertView.cancelButtonIndex != buttonIndex) {
            NSString *userId = self.member.userId;
            __weak typeof(self) weakSelf = self;
            [_dataSource kickUsers:@[userId] completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
                [weakSelf showToastMsg:msg];
                if (!error) {
                    [weakSelf.navigationController popViewControllerAnimated:YES];
                    if([weakSelf.delegate respondsToSelector:@selector(onTeamMemberKicked:)]) {
                        [weakSelf.delegate onTeamMemberKicked:weakSelf.member];
                    }
                }
            }];
        }
    }
    if (alertView == _updateNickAlertView) {
        switch (buttonIndex) {
            case 0://取消
                break;
            case 1:{
                NSString *name = [alertView textFieldAtIndex:0].text;
                NSString *userId = self.member.userId;
                __weak typeof(self) weakSelf = self;
                [_dataSource updateUserNick:userId nick:name completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
                    [weakSelf showToastMsg:msg];
                }];
                break;
            }
            default:
                break;
        }
    }
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(buttonIndex == 0) {
        NSString *userId = self.member.userId;
        NIMTeamMemberType userType = self.member.userType;
        if (userType == NIMTeamMemberTypeManager) {
            [self removeManager:userId];
        }else{
            [self addManager:userId];
        }
    }
}

#pragma mark - Private
- (BOOL)isSelf {
    return [self.viewer.userId isEqualToString:self.member.userId];
}

- (BOOL)isOwner {
    return self.viewer.userType == NIMTeamMemberTypeOwner;
}

- (BOOL)canUpdateTeamMember {
    BOOL ret = NO;
    BOOL viewerIsOwner   = [self isOwner];
    BOOL viewerIsManager = self.viewer.userType == NIMTeamMemberTypeManager;
    BOOL memberIsNormal  = self.member.userType == NIMTeamMemberTypeNormal;
    if (viewerIsOwner) {
        ret = ![self isSelf];
    } else if (viewerIsManager) {
        ret = memberIsNormal;
    }
    return ret;
}

- (BOOL)canChangeUserType {
    BOOL ret = ([self isOwner] && ![self isSelf]);
    return ret;
}

- (BOOL)canKickTeamMember {
    BOOL ret = [self canUpdateTeamMember];
    return ret;
}

- (void)showToastMsg:(NSString *)msg {
    if (msg) {
        [self.view makeToast:msg
                    duration:2.0
                    position:CSToastPositionCenter];
    }
}

#pragma mark - Getter
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.tableFooterView = [UIView new];
    }
    return _tableView;
}

@end


