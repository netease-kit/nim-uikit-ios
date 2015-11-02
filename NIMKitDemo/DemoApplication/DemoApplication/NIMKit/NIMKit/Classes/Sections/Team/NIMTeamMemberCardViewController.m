//
//  TeamMemberCardViewController.m
//  NIM
//
//  Created by Xuhui on 15/3/19.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMTeamMemberCardViewController.h"
#import "NIMAvatarImageView.h"
#import "NIMCardMemberItem.h"
#import "NIMUsrInfoData.h"
#import "NIMKitUtil.h"
#import "UIView+NIMKitToast.h"
#import "NIMKit.h"
#import "UIView+NIM.h"

typedef NS_ENUM(NSInteger, TeamMemberCardSectionType) {
    TeamMemberCardSectionHead,
    TeamMemberCardSectionNick,
    TeamMemberCardSectionMemberType,
    TeamMemberCardSectionAction,
    TeamMemberCardSectionCount
};

@interface NIMTeamMemberCardViewController () <UITableViewDelegate, UITableViewDataSource,UIActionSheetDelegate>{
    UIAlertView *_kickAlertView;
    UIAlertView *_updateNickAlertView;
}

@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) NIMUsrInfo *usrInfo;

@end

@implementation NIMTeamMemberCardViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {

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
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    NIMUsrInfo *user = [[NIMUsrInfo alloc] init];
    user.info = [[NIMKit sharedKit] infoByUser:self.member.memberId];
    self.usrInfo = user;
}

- (NSString *)memberTypeString:(NIMTeamMemberType)type {
    if(type == NIMTeamMemberTypeNormal) {
        return @"普通群员";
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

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    switch (row) {
        case TeamMemberCardSectionHead: {
            return 222;
        } break;
        case TeamMemberCardSectionNick: {
            return 50;
        } break;
        case TeamMemberCardSectionMemberType: {
            return 50;
        } break;
        case TeamMemberCardSectionAction: {
            return 70;
        } break;
        default: {
            return 0;
        } break;
    }

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSInteger row = indexPath.row;
    if(row == TeamMemberCardSectionNick) {
        _updateNickAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"修改群昵称" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
        _updateNickAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [_updateNickAlertView show];
        
    } else if (row == TeamMemberCardSectionMemberType) {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"管理员操作" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles: self.member.type == NIMTeamMemberTypeManager ? @"取消管理员" : @"设为管理员", nil];
        [sheet showInView:self.view];
    }
   
}

- (void)removeManager:(NSString *)memberId{
    __block typeof(self) wself = self;
    [[NIMSDK sharedSDK].teamManager removeManagersFromTeam:self.member.team.teamId users:@[self.member.memberId] completion:^(NSError *error) {
        if (!error) {
            wself.member.type = NIMTeamMemberTypeNormal;
            [wself.view nimkit_makeToast:@"修改成功"];
            [wself.tableView reloadData];
            if([_delegate respondsToSelector:@selector(onTeamMemberInfoChaneged:)]) {
                [_delegate onTeamMemberInfoChaneged:wself.member];
            }
        }else{
            [wself.view nimkit_makeToast:@"修改失败"];
        }
        
    }];
}

- (void)addManager:(NSString *)memberId{
    __block typeof(self) wself = self;
    [[NIMSDK sharedSDK].teamManager addManagersToTeam:self.member.team.teamId users:@[self.member.memberId] completion:^(NSError *error) {
        if (!error) {
            wself.member.type = NIMTeamMemberTypeManager;
            [wself.view nimkit_makeToast:@"修改成功"];
            [wself.tableView reloadData];
            if([_delegate respondsToSelector:@selector(onTeamMemberInfoChaneged:)]) {
                [_delegate onTeamMemberInfoChaneged:wself.member];
            }
        }else{
            [wself.view nimkit_makeToast:@"修改失败"];
        }
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return TeamMemberCardSectionCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    switch (row) {
        case TeamMemberCardSectionHead: {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TeamMemberCardHeadCell"];
            NIMAvatarImageView *avatarView = [[NIMAvatarImageView alloc] initWithFrame:CGRectMake(125, 52, 70, 70)];
            avatarView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            NSURL *avatarURL;
            if (self.usrInfo.info.avatarUrlString.length) {
                avatarURL = [NSURL URLWithString:self.usrInfo.info.avatarUrlString];
            }
            [avatarView nim_setImageWithURL:avatarURL placeholderImage:self.usrInfo.info.avatarImage];
            [cell addSubview:avatarView];
            
            UILabel *nickLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            nickLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            nickLabel.font = [UIFont systemFontOfSize:17];
            nickLabel.textColor = [UIColor colorWithRed:51.0 / 255 green:51.0 / 255 blue:51.0 / 255 alpha:1.0];
            NIMSession *session = [NIMSession session:self.member.team.teamId type:NIMSessionTypeTeam];
            nickLabel.text = [NIMKitUtil showNick:self.member.memberId inSession:session];
            [nickLabel sizeToFit];
            nickLabel.nim_centerX = avatarView.nim_centerX;
            nickLabel.nim_top = avatarView.nim_bottom + 10;
            [cell addSubview:nickLabel];
            cell.userInteractionEnabled = NO;
            return cell;
            
        } break;
        case TeamMemberCardSectionNick: {
            NIMTeamMember *member = [[NIMSDK sharedSDK].teamManager teamMember:self.member.memberId inTeam:self.member.team.teamId];
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"TeamMemberCardHeadCell"];
            cell.textLabel.text = @"群昵称";
            if (member.nickname.length) {
                cell.detailTextLabel.text = member.nickname;
            }else{
                cell.detailTextLabel.text = @"未设置";
            }
            if(self.viewer.type == NIMTeamMemberTypeNormal && ![self.viewer.memberId isEqualToString:self.member.memberId]){
                cell.userInteractionEnabled = NO;
                cell.accessoryType = UITableViewCellAccessoryNone;
            } else {
                cell.userInteractionEnabled = YES;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            return cell;
        } break;
        case TeamMemberCardSectionMemberType: {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"TeamMemberCardHeadCell"];
            cell.textLabel.text = @"身份";
            cell.detailTextLabel.text = [self memberTypeString:self.member.type];
            if(self.viewer.type == NIMTeamMemberTypeOwner && ![self.viewer.memberId isEqualToString:self.member.memberId]) {
                cell.userInteractionEnabled = YES;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            } else {
                cell.userInteractionEnabled = NO;
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            return cell;
        } break;
        case TeamMemberCardSectionAction: {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TeamMemberCardActionCell"];
            UIButton *kickBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            kickBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            kickBtn.frame = CGRectMake(8, 25, 305, 45);
            [kickBtn setBackgroundImage:[UIImage imageNamed:@"icon_cell_red_normal"] forState:UIControlStateNormal];
            kickBtn.titleLabel.font = [UIFont systemFontOfSize:19];
            [kickBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [kickBtn setTitle:@"移出本群" forState:UIControlStateNormal];
            [kickBtn addTarget:self action:@selector(onKickBtnClick:) forControlEvents:UIControlEventTouchUpInside];
            [cell addSubview:kickBtn];
            if(self.viewer.type == NIMTeamMemberTypeNormal || [self.viewer.memberId isEqualToString:self.member.memberId]) {
                kickBtn.hidden = YES;
                cell.userInteractionEnabled = NO;
            } else {
                kickBtn.hidden = NO;
                cell.userInteractionEnabled = YES;
            }
            return cell;
        } break;
        default: {
            return nil;
        } break;
    }
}


#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (alertView == _kickAlertView) {
        if(alertView.cancelButtonIndex != buttonIndex) {
            [[NIMSDK sharedSDK].teamManager kickUsers:@[self.member.memberId] fromTeam:self.member.team.teamId completion:^(NSError *error) {
                if(!error) {
                    [self.view nimkit_makeToast:@"踢人成功"];
                    [self.navigationController popViewControllerAnimated:YES];
                    if([_delegate respondsToSelector:@selector(onTeamMemberKicked:)]) {
                        [_delegate onTeamMemberKicked:self.member];
                    }
                } else {
                    [self.view nimkit_makeToast:@"踢人失败"];
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
                if (name.length) {
                    [[NIMSDK sharedSDK].teamManager updateUserNick:self.member.memberId newNick:name inTeam:self.member.team.teamId completion:^(NSError *error) {
                        if (!error) {
                            [self.view nimkit_makeToast:@"修改成功"];
                            [self.tableView reloadData];
                            if([_delegate respondsToSelector:@selector(onTeamMemberInfoChaneged:)]) {
                                [_delegate onTeamMemberInfoChaneged:self.member];
                            }
                        }else{
                            [self.view nimkit_makeToast:@"修改失败"];
                        }
                    }];
                }
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

@end
