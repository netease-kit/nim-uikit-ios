//
//  NTESNormalTeamCardViewController.m
//  NIM
//
//  Created by chris on 15/3/10.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMNormalTeamCardViewController.h"
#import "NIMCardMemberItem.h"
#import "NIMTeamCardOperationItem.h"
#import "NIMTeam.h"
#import "UIView+NIMKitToast.h"
#import "NIMTeamCardRowItem.h"
#import "NIMTeamCardHeaderCell.h"
#import "NIMTeamMemberCardViewController.h"
#import "NIMUsrInfoData.h"

@interface NIMNormalTeamCardViewController ()<NIMTeamManagerDelegate, NIMTeamMemberCardActionDelegate>{
    UIAlertView *_updateTeamNameAlertView;
    UIAlertView *_quitTeamAlertView;
    UIAlertView *_dismissTeamAlertView;
}

//@property (nonatomic,strong) NIMKitTeamInfoOption *option;

@property (nonatomic,strong) NIMTeamMember *myTeamInfo;

@property (nonatomic,strong) NIMTeam *team;

@property (nonatomic,copy) NSArray *teamMembers;

@end

@implementation NIMNormalTeamCardViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NIMSDK sharedSDK].teamManager addDelegate:self];
    }
    return self;
}


- (instancetype)initWithTeam:(NIMTeam *)team{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        _team = team;
    }
    return self;
}

- (void)dealloc{
    [[NIMSDK sharedSDK].teamManager removeDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    __weak typeof(self) wself = self;
    [self requestData:^(NSError *error, NSArray *data) {
        NSArray * operaData = [wself buildOpearationData];
        if (operaData) {
            data = [data arrayByAddingObjectsFromArray:operaData];
        }
        [wself refreshWithMembers:data];
    }];
}

- (NSString*)title{
    return self.team.teamName;
}


#pragma mark - Data
- (void)requestData:(void(^)(NSError *error,NSArray *data)) handler{
    __weak typeof(self) wself = self;
    [[NIMSDK sharedSDK].teamManager fetchTeamMembers:self.team.teamId completion:^(NSError *error, NSArray *members) {
        NSMutableArray *array = nil;
        if (!error) {
            NSString *myAccount = [[NIMSDK sharedSDK].loginManager currentAccount];
            for (NIMTeamMember *item in members) {
                if ([item.userId isEqualToString:myAccount]) {
                    wself.myTeamInfo = item;
                }
            }
            array = [[NSMutableArray alloc]init];
            for (NIMTeamMember *member in members) {
                NIMTeamCardMemberItem *item = [[NIMTeamCardMemberItem alloc] initWithMember:member];
                [array addObject:item];
            }
            wself.teamMembers = members;
        }else if(error.code == NIMRemoteErrorCodeTeamNotMember){
            [wself.view nimkit_makeToast:@"你已经不在群里"];
        }else{
            [wself.view nimkit_makeToast:@"拉好友失败"];
        }
        handler(error,array);
    }];
}

- (NSArray*)buildOpearationData{
    NIMTeam *team = [[NIMSDK sharedSDK].teamManager teamById:self.team.teamId];
    //加号
    NIMTeamCardOperationItem *add = [[NIMTeamCardOperationItem alloc] initWithOperation:CardHeaderOpeatorAdd];
    //减号
    NIMTeamCardOperationItem *remove = [[NIMTeamCardOperationItem alloc] initWithOperation:CardHeaderOpeatorRemove];
    NSString *uid = [NIMSDK sharedSDK].loginManager.currentAccount;
    NIMTeamMember *member = [[NIMSDK sharedSDK].teamManager teamMember:uid inTeam:team.teamId];
    if (member.type == NIMTeamMemberTypeOwner) {
        return @[add,remove];
    }
    return @[add];
}

- (NSArray*)buildBodyData{
    
    NIMTeamCardRowItem *itemName = [[NIMTeamCardRowItem alloc] init];
    itemName.title            = @"群名称";
    itemName.subTitle         = self.team.teamName;
    itemName.action           = @selector(updateTeamInfoName);
    itemName.rowHeight        = 50.f;
    itemName.type             = TeamCardRowItemTypeCommon;
    
    NIMTeamCardRowItem *teamNotify = [[NIMTeamCardRowItem alloc] init];
    teamNotify.title            = @"消息提醒";
    teamNotify.switchOn         = [self.team notifyForNewMsg];
    teamNotify.rowHeight        = 50.f;
    teamNotify.type             = TeamCardRowItemTypeSwitch;

    NIMTeamCardRowItem *itemQuit = [[NIMTeamCardRowItem alloc] init];
    itemQuit.title            = @"退出群聊";
    itemQuit.action           = @selector(quitTeam);
    itemQuit.rowHeight        = 60.f;
    itemQuit.type             = TeamCardRowItemTypeRedButton;
    
    return @[@[itemName,teamNotify,],@[itemQuit]];
}


- (void)addHeaderDatas:(NSArray*)members{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (NIMTeamMember *member in members) {
        NIMTeamCardMemberItem* item = [[NIMTeamCardMemberItem alloc] initWithMember:member];
        [array addObject:item];
    }
    [self addMembers:array];
}

- (void)removeHeaderDatas:(NSArray*)datas{
    [self removeMembers:datas];
}

#pragma mark - UITableViewAction
- (void)updateTeamInfoName{
    _updateTeamNameAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"修改群名称" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
    _updateTeamNameAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [_updateTeamNameAlertView show];
}

- (void)quitTeam{
    _quitTeamAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"确认退出群聊?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
    [_quitTeamAlertView show];
}

- (void)dismissTeam{
    _dismissTeamAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"确认解散群聊?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
    [_dismissTeamAlertView show];
}

#pragma mark - ContactSelectDelegate

- (void)didFinishedSelect:(NSArray *)selectedContacts{
    if (selectedContacts.count) {
        __weak typeof(self) wself = self;
        switch (self.currentOpera) {
            case CardHeaderOpeatorAdd:{
                [[NIMSDK sharedSDK].teamManager addUsers:selectedContacts
                                                  toTeam:self.team.teamId
                                              postscript:@"邀请你加入群组"
                                              completion:^(NSError *error,NSArray *members) {
                    if (!error) {
                        if (self.team.type == NIMTeamTypeNormal) {
                            [wself addHeaderDatas:members];
                        }else{
                            [wself.view nimkit_makeToast:@"邀请成功，等待验证" duration:2.0 position:NIMKitToastPositionCenter];
                        }

                    }else{
                        [wself.view nimkit_makeToast:@"邀请失败"];
                    }
                    wself.currentOpera = CardHeaderOpeatorNone;
                    [wself refreshTableHeader];
                    
                }];
            }
                break;
            case CardHeaderOpeatorRemove:{
                [[NIMSDK sharedSDK].teamManager kickUsers:selectedContacts fromTeam:self.team.teamId completion:^(NSError *error) {
                    if (!error) {
                        [wself removeHeaderDatas:selectedContacts];
                    }else{
                        [wself.view nimkit_makeToast:@"移除失败"];
                    }
                    [wself refreshTableHeader];
                }];
            }
                break;
            default:
                break;
        }
    }
}

- (void)didCancelledSelect{
    self.currentOpera = CardHeaderOpeatorNone;
}

#pragma mark - TeamSwitchProtocol
- (void)onStateChanged:(BOOL)on
{
    __weak typeof(self) weakSelf = self;
    [[[NIMSDK sharedSDK] teamManager] updateNotifyState:on
                                                 inTeam:[self.team teamId]
                                             completion:^(NSError *error) {
                                                 [weakSelf refreshTableBody];
                                             }];
    //override
}


#pragma mark - NIMTeamManagerDelegate
- (void)onTeamUpdated:(NIMTeam *)team{
    if ([team.teamId isEqualToString:self.team.teamId]) {
        self.navigationItem.title = [self title];
        __weak typeof(self) wself = self;
        [self requestData:^(NSError *error, NSArray *data) {
            NSArray * operaData = [wself buildOpearationData];
            if (operaData) {
                data = [data arrayByAddingObjectsFromArray:operaData];
            }
            [wself refreshWithMembers:data];
        }];
    }
}


- (void)cellDidSelected:(NIMTeamCardHeaderCell*)cell{
    [super cellDidSelected:cell];
    id<NIMKitCardHeaderData> data = cell.data;
    NSString *memberId;
    if ([data respondsToSelector:@selector(memberId)]) {
        memberId = data.memberId;
    }
    NSString *uid = [NIMSDK sharedSDK].loginManager.currentAccount;
    NIMTeamMember *myInfo = [self teamInfo:uid];
    
    if (memberId.length && self.team.type == NIMTeamTypeAdvanced) {
        NIMTeamMember *memberInfo = [self teamInfo:memberId];
        if((myInfo.type == NIMTeamMemberTypeOwner || myInfo.type == NIMTeamMemberTypeManager) && ![myInfo.userId isEqualToString:memberInfo.userId]) {
            NIMTeamMemberCardViewController *vc = [[NIMTeamMemberCardViewController alloc] initWithNibName:nil bundle:nil];
            vc.delegate = self;
            vc.member = [[NIMTeamCardMemberItem alloc] initWithMember:memberInfo];
            vc.viewer = [[NIMTeamCardMemberItem alloc] initWithMember:myInfo];
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
    
    
    
}


- (NIMTeamMember*)teamInfo:(NSString*)uid{
    for (NIMTeamMember *member in self.teamMembers) {
        if ([member.userId isEqualToString:uid]) {
            return member;
        }
    }
    return nil;
}

- (void)transferOwner:(NSString *)memberId isLeave:(BOOL)isLeave{
    __block typeof(self) wself = self;
    NIMTeamMember *memberInfo = [self teamInfo:memberId];
    [[NIMSDK sharedSDK].teamManager transferManagerWithTeam:self.team.teamId newOwnerId:memberId isLeave:isLeave completion:^(NSError *error) {
        if (!error) {
            memberInfo.type = NIMTeamMemberTypeOwner;
            [wself.view nimkit_makeToast:@"修改成功"];
        }else{
            [wself.view nimkit_makeToast:@"修改失败"];
        }
    }];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (alertView == _updateTeamNameAlertView) {
        switch (buttonIndex) {
            case 0://取消
                break;
            case 1:{
                NSString *name = [alertView textFieldAtIndex:0].text;
                if (name.length) {
                    [[NIMSDK sharedSDK].teamManager updateTeamName:name teamId:self.team.teamId completion:^(NSError *error) {
                        if (!error) {
                            self.team = [[[NIMSDK sharedSDK] teamManager] teamById:self.team.teamId];
                            [self.view nimkit_makeToast:@"修改成功"];
                            [self refreshTableBody];
                            [self refreshTitle];
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
    
    if (alertView == _quitTeamAlertView) {
        switch (buttonIndex) {
            case 0://取消
                break;
            case 1:{
                [[NIMSDK sharedSDK].teamManager quitTeam:self.team.teamId completion:^(NSError *error) {
                    if (!error) {
                        [self.navigationController popToRootViewControllerAnimated:YES];
                    }else{
                        [self.view nimkit_makeToast:@"退出失败"];
                    }
                }];
                break;
            }
            default:
                break;
        }
    }
    
    if (alertView == _dismissTeamAlertView) {
        switch (buttonIndex) {
            case 0://取消
                break;
            case 1:{
                [[NIMSDK sharedSDK].teamManager dismissTeam:self.team.teamId completion:^(NSError *error) {
                    if (!error) {
                        [self.navigationController popToRootViewControllerAnimated:YES];
                    }else{
                        [self.view nimkit_makeToast:@"解散失败"];
                    }
                }];
                break;
            }
            default:
                break;
        }
    }
}

@end
