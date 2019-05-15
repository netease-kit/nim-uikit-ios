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
#import "NIMUsrInfoData.h"
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

@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) NIMUsrInfo *usrInfo;

@property (nonatomic,strong) NIMCommonTableDelegate *delegator;

@property (nonatomic,strong) NSArray *data;

@end

@implementation NIMTeamMemberCardViewController

- (instancetype)initWithUserId:(NSString *)userId team:(NSString *)teamId{
    self = [super initWithNibName:nil bundle:nil];
    if(self) {
        _member = [[NIMTeamCardMemberItem alloc] initWithMember:[[NIMSDK sharedSDK].teamManager teamMember:userId inTeam:teamId]];
        _viewer = [[NIMTeamCardMemberItem alloc] initWithMember:[[NIMSDK sharedSDK].teamManager teamMember:[NIMSDK sharedSDK].loginManager.currentAccount inTeam:teamId]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"群名片";
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];
    self.tableView.tableFooterView = [UIView new];
    
    NIMUsrInfo *user = [[NIMUsrInfo alloc] init];
    user.info = [[NIMKit sharedKit] infoByUser:self.member.memberId option:nil];
    self.usrInfo = user;

    [self buildData];
    __weak typeof(self) wself = self;
    self.delegator = [[NIMCommonTableDelegate alloc] initWithTableData:^NSArray *{
        return wself.data;
    }];
    self.tableView.delegate   = self.delegator;
    self.tableView.dataSource = self.delegator;

}


- (void)buildData{
    NIMTeamMember *member = [[NIMSDK sharedSDK].teamManager teamMember:self.member.memberId inTeam:self.member.team.teamId];
    
    NSArray *data = @[
                      @{
                          HeaderTitle:@"",
                          RowContent :@[
                                  @{
                                      CellClass     : @"NIMTeamMemberCardHeaderCell",
                                      RowHeight     : @(222),
                                      ExtraInfo     : @{@"user":self.usrInfo,@"team":self.member.team},
                                      SepLeftEdge   : @(SepLineLeft),
                                  },
                                  @{
                                      Title         : @"群昵称",
                                      DetailTitle   : member.nickname.length? member.nickname : @"未设置",
                                      CellAction    : ([self isSelf] || [self canUpdateTeamMember])? @"updateTeamNick" : @"",
                                      ShowAccessory : ([self isSelf] || [self canUpdateTeamMember])? @(YES) : @(NO),
                                      RowHeight     : @(50),
                                      SepLeftEdge   : @(SepLineLeft),
                                      },
                                  @{
                                      Title         : @"身份",
                                      DetailTitle   : [self memberTypeString:self.member.type],
                                      CellAction    : ([self isOwner] && ![self isSelf])? @"updateTeamRole" : @"",
                                      ShowAccessory : [self isOwner] && ![self isSelf]? @(YES) : @(NO),
                                      RowHeight     : @(50),
                                      SepLeftEdge   : @(SepLineLeft),
                                    },
                                  @{
                                      Title         : @"设置禁言",
                                      CellClass     : @"NIMKitSwitcherCell",
                                      CellAction    : @"updateMute:",
                                      ForbidSelect  : @(YES),
                                      RowHeight     : @(50),
                                      Disable       : @(![self canUpdateTeamMember]),
                                      ExtraInfo     : @(member.isMuted),
                                      SepLeftEdge   : @(SepLineLeft),
                                    },
                                  @{
                                      Title         : @"移出本群",
                                      CellClass     : @"NIMKitColorButtonCell",
                                      CellAction    : @"onKickBtnClick:",
                                      ExtraInfo     : @(NIMKitColorButtonCellStyleRed),
                                      RowHeight     : @(70),
                                      Disable       : @(![self canUpdateTeamMember]),
                                      SepLeftEdge   : @(0),
                                    }
                                  ],
                          FooterTitle:@""
                          },
                       ];
    self.data = [NIMCommonTableSection sectionsWithData:data];
}

- (void)refreshData{
    [self buildData];
    [self.tableView reloadData];
}


- (NSString *)memberTypeString:(NIMTeamMemberType)type {
    if(type == NIMTeamMemberTypeNormal) {
        return @"普通成员";
    } else if (type == NIMTeamMemberTypeOwner) {
        return @"群主";
    } else if (type == NIMTeamMemberTypeManager) {
        return @"管理员";
    }
    return @"";
}


- (void)onKickBtnClick:(id)sender {
    _kickAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"移出本群" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [_kickAlertView show];
}

- (void)updateTeamNick
{
    _updateNickAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"修改群昵称" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
    _updateNickAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [_updateNickAlertView show];
}

- (void)updateTeamRole
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"管理员操作" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles: self.member.type == NIMTeamMemberTypeManager ? @"取消管理员" : @"设为管理员", nil];
    [sheet showInView:self.view];
}

- (void)updateMute:(UISwitch *)switcher
{
    __block typeof(self) wself = self;
    BOOL mute = switcher.on;
    [[NIMSDK sharedSDK].teamManager updateMuteState:mute userId:self.member.memberId inTeam:self.member.team.teamId completion:^(NSError *error) {
        if (error) {
            [wself.view makeToast:@"修改失败"];
            switcher.on = !mute;
        }
    }];
}


- (void)removeManager:(NSString *)memberId{
    __block typeof(self) wself = self;
    [[NIMSDK sharedSDK].teamManager removeManagersFromTeam:self.member.team.teamId users:@[self.member.memberId] completion:^(NSError *error) {
        typeof(wself) strongSelf = wself;
        if (!strongSelf) return;

        if (!error) {
            strongSelf.member.type = NIMTeamMemberTypeNormal;
            [strongSelf.view makeToast:@"修改成功"];
            [strongSelf refreshData];
            if([strongSelf.delegate respondsToSelector:@selector(onTeamMemberInfoChaneged:)]) {
                [strongSelf.delegate onTeamMemberInfoChaneged:strongSelf.member];
            }
        }else{
            [strongSelf.view makeToast:@"修改失败"];
        }
        
    }];
}

- (void)addManager:(NSString *)memberId{
    __block typeof(self) wself = self;
    [[NIMSDK sharedSDK].teamManager addManagersToTeam:self.member.team.teamId users:@[self.member.memberId] completion:^(NSError *error) {
        typeof(wself) strongSelf = wself;
        if (!strongSelf) return;

        if (!error) {
            strongSelf.member.type = NIMTeamMemberTypeManager;
            [strongSelf.view makeToast:@"修改成功"];
            [strongSelf refreshData];
            if([strongSelf.delegate respondsToSelector:@selector(onTeamMemberInfoChaneged:)]) {
                [strongSelf.delegate onTeamMemberInfoChaneged:strongSelf.member];
            }
        }else{
            [strongSelf.view makeToast:@"修改失败"];
        }
    }];
}


#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (alertView == _kickAlertView) {
        if(alertView.cancelButtonIndex != buttonIndex) {
            __weak typeof(self) weakSelf = self;
            [[NIMSDK sharedSDK].teamManager kickUsers:@[self.member.memberId] fromTeam:self.member.team.teamId completion:^(NSError *error) {
                typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;

                if(!error) {
                    [strongSelf.view makeToast:@"踢人成功"];
                    [strongSelf.navigationController popViewControllerAnimated:YES];
                    if([strongSelf.delegate respondsToSelector:@selector(onTeamMemberKicked:)]) {
                        [strongSelf.delegate onTeamMemberKicked:strongSelf.member];
                    }
                } else {
                    [strongSelf.view makeToast:@"踢人失败"];
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
                __weak typeof(self) weakSelf = self;
                [[NIMSDK sharedSDK].teamManager updateUserNick:self.member.memberId newNick:name inTeam:self.member.team.teamId completion:^(NSError *error) {
                    typeof(weakSelf) strongSelf = weakSelf;
                    if (!strongSelf) return;

                    if (!error) {
                        [strongSelf.view makeToast:@"修改成功"];
                        [strongSelf refreshData];
                        if([strongSelf.delegate respondsToSelector:@selector(onTeamMemberInfoChaneged:)]) {
                            [strongSelf.delegate onTeamMemberInfoChaneged:strongSelf.member];
                        }
                    }else{
                        [strongSelf.view makeToast:@"修改失败"];
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
        if (self.member.type == NIMTeamMemberTypeManager) {
            [self removeManager:self.member.memberId];
        }else{
            [self addManager:self.member.memberId];
        }
    }
}

#pragma mark - Private

- (BOOL)isSelf
{
    return [self.viewer.memberId isEqualToString:self.member.memberId];
}

- (BOOL)isOwner
{
    return self.viewer.member.type == NIMTeamMemberTypeOwner;
}

- (BOOL)canModifyTeamInfo
{
    return [NIMKitUtil canEditTeamInfo:self.viewer.member];
}

- (BOOL)canUpdateTeamMember
{
    BOOL viewerIsOwner   = [self isOwner];
    BOOL viewerIsManager = self.viewer.member.type == NIMTeamMemberTypeManager;
    BOOL memberIsNormal  = self.member.member.type == NIMTeamMemberTypeNormal;
    if (viewerIsOwner) {
        return ![self isSelf];
    }
    if (viewerIsManager) {
        return memberIsNormal;
    }
    return NO;
}

@end


