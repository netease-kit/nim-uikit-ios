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
#import "NIMCardMemberItem.h"
#import "NIMKitUtil.h"
#import "NIMKitDependency.h"
#import "NIMKit.h"
#import "UIView+NIM.h"
#import "NIMKitColorButtonCell.h"
#import "NIMKitSwitcherCell.h"

@interface NIMTeamMemberCardViewController () <UIActionSheetDelegate>{
    UIAlertView *_kickAlertView;
    UIAlertView *_updateNickAlertView;
}

@property (nonatomic, strong) NIMTeamCardMemberItem *member;

@property (nonatomic, strong) NIMTeamCardMemberItem *viewer;

@property (strong, nonatomic) UITableView *tableView;

@property (nonatomic,strong) NIMCommonTableDelegate *delegator;

@property (nonatomic,weak) id <NIMTeamMemberListDataSource> dataSource;

@property (nonatomic,strong) NSArray *data;

@end

@implementation NIMTeamMemberCardViewController

- (instancetype)initWithMember:(NIMTeamCardMemberItem *)member
                    dataSource:(id <NIMTeamMemberListDataSource>) dataSource {
    if (self = [super init]) {
        _member = member;
        _dataSource = dataSource;
        _viewer = dataSource.myCard;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"群名片";
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
    NIMKitInfo *usrInfo = [[NIMKit sharedKit] infoByUser:_member.userId option:nil];
    NSDictionary *headerItem = @{
                                 CellClass     : @"NIMTeamMemberCardHeaderCell",
                                 RowHeight     : @(222),
                                 ExtraInfo     : @{@"user":usrInfo},
                                 SepLeftEdge   : @(SepLineLeft)
                                 };
    NSDictionary *nickItem = @{
                               Title         : @"群昵称",
                               DetailTitle   : (usrInfo.showName ?: @"未设置"),
                               CellAction    : ([self isSelf] || [self canUpdateTeamMember])? @"updateTeamNick" : @"",
                               ShowAccessory : ([self isSelf] || [self canUpdateTeamMember])? @(YES) : @(NO),
                               RowHeight     : @(50),
                               SepLeftEdge   : @(SepLineLeft),
                               };
    
    NSDictionary *userTypeItem = @{
                                   Title         : @"身份",
                                   DetailTitle   : [_dataSource memberTypeString:self.member.userType],
                                   CellAction    : ([self isOwner] && ![self isSelf])? @"updateTeamRole" : @"",
                                   ShowAccessory : @([self canChangeUserType]),
                                   RowHeight     : @(50),
                                   SepLeftEdge   : @(SepLineLeft),
                                   };
    
    NSDictionary *inviterAccidItem = @{
                                       Title         : @"邀请人",
                                       DetailTitle   : _member.inviterAccid ? (_member.inviterAccid.length ? _member.inviterAccid : _member.userId) : @"本地不存在",
                                       CellAction    : @"",
                                       ShowAccessory : [self isOwner] && ![self isSelf]? @(YES) : @(NO),
                                       RowHeight     : @(50),
                                       SepLeftEdge   : @(SepLineLeft),
                                       };
    
    NSDictionary *isMuteItem =  @{
                                  Title         : @"设置禁言",
                                  CellClass     : @"NIMKitSwitcherCell",
                                  CellAction    : @"updateMute:",
                                  ForbidSelect  : @(YES),
                                  RowHeight     : @(50),
                                  DisableUserInteraction:@(![self canUpdateTeamMember]),
                                  ExtraInfo     : @(_member.isMuted),
                                  SepLeftEdge   : @(SepLineLeft),
                                  };
    
    NSDictionary *kickItem = @{
                               Title         : @"移出本群",
                               CellClass     : @"NIMKitColorButtonCell",
                               CellAction    : @"onKickBtnClick:",
                               ExtraInfo     : @(NIMKitColorButtonCellStyleRed),
                               RowHeight     : @(70),
                               Disable       : @([self isSelf] || ![self canKickTeamMember]),
                               SepLeftEdge   : @(0),
                               };
    
    NSArray *rowContent = @[];
    if (_member.teamType == NIMKitTeamCardTypeNormal) {
        rowContent = @[headerItem, nickItem, userTypeItem, inviterAccidItem, isMuteItem, kickItem];
    } else if (_member.teamType == NIMKitTeamCardTypeSuper) {
        rowContent = @[headerItem, nickItem, userTypeItem, isMuteItem, kickItem];
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
    self.data = [self buildData];
    [self.tableView reloadData];
}

- (void)onKickBtnClick:(id)sender {
    _kickAlertView = [[UIAlertView alloc] initWithTitle:@""
                                                message:@"移出本群"
                                               delegate:self
                                      cancelButtonTitle:@"取消"
                                      otherButtonTitles:@"确定", nil];
    [_kickAlertView show];
}

- (void)updateTeamNick
{
    _updateNickAlertView = [[UIAlertView alloc] initWithTitle:@""
                                                      message:@"修改群昵称"
                                                     delegate:self
                                            cancelButtonTitle:@"取消"
                                            otherButtonTitles:@"确认", nil];
    _updateNickAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [_updateNickAlertView show];
}

- (void)updateTeamRole
{
    if (![self canChangeUserType]) {
        return;
    }
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"管理员操作"
                                                       delegate:self
                                              cancelButtonTitle:@"取消"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles: self.member.userType == NIMKitTeamMemberTypeManager ? @"取消管理员" : @"设为管理员", nil];
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
    }];
}

- (void)removeManager:(NSString *)memberId{
    NSString *userId = self.member.userId;
    __block typeof(self) wself = self;
    [_dataSource removeManagers:@[userId] completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        if (!error) {
            [wself.member setUserType:NIMKitTeamMemberTypeNormal];
            [wself refreshData];
            if([wself.delegate respondsToSelector:@selector(onTeamMemberInfoChaneged:)]) {
                [wself.delegate onTeamMemberInfoChaneged:wself.member];
            }
        }
        [wself showToastMsg:msg];
    }];
}

- (void)addManager:(NSString *)memberId{
    if (!memberId) {
        return;
    }
    __block typeof(self) wself = self;
    [_dataSource addManagers:@[memberId] completion:^(NSError * _Nonnull error, NSString * _Nonnull msg) {
        if (!error) {
            [wself.member setUserType:NIMKitTeamMemberTypeManager];
            [wself refreshData];
            if([wself.delegate respondsToSelector:@selector(onTeamMemberInfoChaneged:)]) {
                [wself.delegate onTeamMemberInfoChaneged:wself.member];
            }
        }
        [wself showToastMsg:msg];
    }];
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
                    if (!error) {
                        [weakSelf refreshData];
                        if([weakSelf.delegate respondsToSelector:@selector(onTeamMemberInfoChaneged:)]) {
                            [weakSelf.delegate onTeamMemberInfoChaneged:weakSelf.member];
                        }
                    }
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
        NIMKitTeamMemberType userType = self.member.userType;
        if (userType == NIMKitTeamMemberTypeManager) {
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
    return self.viewer.userType == NIMKitTeamMemberTypeOwner;
}

- (BOOL)canUpdateTeamMember {
    BOOL ret = NO;
    BOOL viewerIsOwner   = [self isOwner];
    BOOL viewerIsManager = self.viewer.userType == NIMKitTeamMemberTypeManager;
    BOOL memberIsNormal  = self.member.userType == NIMKitTeamMemberTypeNormal;
    if (viewerIsOwner) {
        ret = ![self isSelf];
    } else if (viewerIsManager) {
        ret = memberIsNormal;
    }
    return ret;
}

- (BOOL)canChangeUserType {
    BOOL ret = NO;
    if (_member.teamType == NIMKitTeamCardTypeNormal) {
        ret = ([self isOwner] && ![self isSelf]);
    }
    return ret;
}

- (BOOL)canKickTeamMember {
    BOOL ret = NO;
    ret = [self canUpdateTeamMember];
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


