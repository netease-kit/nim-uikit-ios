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
#import "NIMTeamCardOperationItem.h"
#import "NIMKitDependency.h"
#import "NIMTeamCardRowItem.h"
#import "NIMTeamCardHeaderCell.h"
#import "NIMTeamMemberCardViewController.h"
#import "NIMUsrInfoData.h"
#import "UIView+NIM.h"
#import "NIMMemberGroupView.h"
#import "NIMKitColorButtonCell.h"
#import "NIMTeamSwitchTableViewCell.h"
#import "NIMContactSelectConfig.h"
#import "NIMContactSelectViewController.h"
#import "NIMGlobalMacro.h"
#import "NIMKitProgressHUD.h"

#define TableCellReuseId        @"tableCell"
#define TableButtonCellReuseId  @"tableButtonCell"
#define TableSwitchReuseId      @"tableSwitchReuseId"
#define TableSepTag 10001

@interface NIMNormalTeamCardViewController ()<NIMTeamManagerDelegate, NIMTeamMemberCardActionDelegate,UITableViewDataSource,UITableViewDelegate,NIMTeamSwitchProtocol,NIMContactSelectDelegate,NIMMemberGroupViewDelegate>{
    UIAlertView *_updateTeamNameAlertView;
    UIAlertView *_quitTeamAlertView;
}

@property (nonatomic,strong) NIMTeamMember *myTeamInfo;

@property (nonatomic,strong) NIMTeam *team;

@property (nonatomic,copy)   NSArray *teamMembers;

@property (nonatomic,strong) NIMMemberGroupView *headerView;

@property (nonatomic,strong) UITableView *tableView;

@property (nonatomic,assign) NIMKitCardHeaderOpeator currentOpera;

@property (nonatomic,strong) NSMutableArray *headerData; //表头collectionView数据

@property (nonatomic,strong) NSArray *bodyData;   //表身数据

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
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = NIMKit_UIColorFromRGB(0xecf1f5);
    [self.view addSubview:self.tableView];
    __weak typeof(self) wself = self;
    [self requestData:^(NSError *error, NSArray *data) {
        if (!error) {
           [wself refreshWithMembers:data];
        }else{
            [wself.view makeToast:@"讨论组成员获取失败"];
        }

    }];
}

- (void)viewDidLayoutSubviews{
    [self refreshTableHeader:self.view.nim_width];
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
            [wself.view makeToast:@"你已经不在讨论组里"];
        }else{
            [wself.view makeToast:@"拉好友失败"];
        }
        handler(error,array);
    }];
}

- (NSArray*)buildBodyData{
    
    NIMTeamCardRowItem *itemName = [[NIMTeamCardRowItem alloc] init];
    itemName.title            = @"讨论组名称";
    itemName.subTitle         = self.team.teamName;
    itemName.action           = @selector(updateTeamInfoName);
    itemName.rowHeight        = 50.f;
    itemName.type             = TeamCardRowItemTypeCommon;
    
    NIMTeamCardRowItem *teamNotify = [[NIMTeamCardRowItem alloc] init];
    teamNotify.title            = @"消息提醒";
    //普通群没有只接受管理员
    teamNotify.switchOn         = [self.team notifyStateForNewMsg] == NIMTeamNotifyStateAll;
    teamNotify.rowHeight        = 50.f;
    teamNotify.type             = TeamCardRowItemTypeSwitch;

    NIMTeamCardRowItem *itemQuit = [[NIMTeamCardRowItem alloc] init];
    itemQuit.title            = @"退出讨论组";
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

#pragma mark - UITableViewAction
- (void)updateTeamInfoName{
    _updateTeamNameAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"修改讨论组名称" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
    _updateTeamNameAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [_updateTeamNameAlertView show];
}

- (void)quitTeam{
    _quitTeamAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"确认退出讨论组?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
    [_quitTeamAlertView show];
}

#pragma mark - ContactSelectDelegate

- (void)didFinishedSelect:(NSArray *)selectedContacts{
    if (selectedContacts.count) {
        __weak typeof(self) wself = self;
        switch (self.currentOpera) {
            case CardHeaderOpeatorAdd:{
                [NIMKitProgressHUD show];
                [[NIMSDK sharedSDK].teamManager addUsers:selectedContacts
                                                  toTeam:self.team.teamId
                                              postscript:@"邀请你加入讨论组"
                                              completion:^(NSError *error,NSArray *members) {
                    [NIMKitProgressHUD dismiss];
                    if (!error) {
                        if (self.team.type == NIMTeamTypeNormal) {
                            [wself addHeaderDatas:members];
                        }else{
                            [wself.view makeToast:@"邀请成功，等待验证" duration:2.0 position:CSToastPositionCenter];
                        }
                        [wself refreshTableHeader:self.view.nim_width];
                    }else{
                        [wself.view makeToast:@"邀请失败"];
                    }
                    wself.currentOpera = CardHeaderOpeatorNone;
                    
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
    NIMTeamNotifyState state = on? NIMTeamNotifyStateAll : NIMTeamNotifyStateNone;
    [[[NIMSDK sharedSDK] teamManager] updateNotifyState:state
                                                 inTeam:[self.team teamId]
                                             completion:^(NSError *error) {
                                                 [weakSelf refreshTableBody];
                                             }];
}


#pragma mark - NIMTeamManagerDelegate
- (void)onTeamUpdated:(NIMTeam *)team{
    if ([team.teamId isEqualToString:self.team.teamId]) {
        self.navigationItem.title = [self title];
        __weak typeof(self) wself = self;
        [self requestData:^(NSError *error, NSArray *data) {
            [wself refreshWithMembers:data];
        }];
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
            [wself.view makeToast:@"修改成功"];
        }else{
            [wself.view makeToast:@"修改失败"];
        }
    }];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.bodyData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSArray *sectionData = self.bodyData[section];
    return sectionData.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    id<NTESCardBodyData> bodyData = [self bodyDataAtIndexPath:indexPath];
    return bodyData.rowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return 0.0f;
    }
    return 20.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = NIMKit_UIColorFromRGB(0xecf1f5);
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    id<NTESCardBodyData> bodyData = [self bodyDataAtIndexPath:indexPath];
    UITableViewCell * cell;
    NIMKitTeamCardRowItemType type = bodyData.type;
    switch (type) {
        case TeamCardRowItemTypeCommon:
            cell = [self builidCommonCell:bodyData indexPath:indexPath];
            break;
        case TeamCardRowItemTypeRedButton:
            cell = [self builidRedButtonCell:bodyData indexPath:indexPath];
            break;
        case TeamCardRowItemTypeBlueButton:
            cell = [self builidBlueButtonCell:bodyData indexPath:indexPath];
            break;
        case TeamCardRowItemTypeSwitch:
            cell = [self buildTeamSwitchCell:bodyData indexPath:indexPath];
            break;
        default:
            break;
    }
    return cell;
}

- (UITableViewCell*)builidCommonCell:(id<NTESCardBodyData>) bodyData indexPath:(NSIndexPath *)indexPath{
    UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:TableCellReuseId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:TableCellReuseId];
        CGFloat left   = 15.f;
        CGFloat height = 1.f;
        UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(left, cell.nim_height - height, cell.nim_width, height)];
        sep.backgroundColor = NIMKit_UIColorFromRGB(0xebebeb);
        [cell addSubview:sep];
        [sep setTag:TableSepTag];
        sep.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    }
    UIView *sep = [cell viewWithTag:TableSepTag];
    sep.hidden = (indexPath.row + 1 == [self.tableView numberOfRowsInSection:indexPath.section]);
    
    cell.textLabel.text = bodyData.title;
    if ([bodyData respondsToSelector:@selector(subTitle)]) {
        cell.detailTextLabel.text = bodyData.subTitle;
    }
    
    if ([bodyData respondsToSelector:@selector(actionDisabled)] && bodyData.actionDisabled) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }else{
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
    
}

- (UITableViewCell*)builidRedButtonCell:(id<NTESCardBodyData>) bodyData indexPath:(NSIndexPath *)indexPath{
    NIMKitColorButtonCell * cell = [self.tableView dequeueReusableCellWithIdentifier:TableButtonCellReuseId];
    if (!cell) {
        cell = [[NIMKitColorButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TableButtonCellReuseId];
    }
    cell.button.style = NIMKitColorButtonCellStyleRed;
    [cell.button setTitle:bodyData.title forState:UIControlStateNormal];
    return cell;
}


- (UITableViewCell*)builidBlueButtonCell:(id<NTESCardBodyData>) bodyData indexPath:(NSIndexPath *)indexPath{
    NIMKitColorButtonCell * cell = [self.tableView dequeueReusableCellWithIdentifier:TableButtonCellReuseId];
    if (!cell) {
        cell = [[NIMKitColorButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TableButtonCellReuseId];
    }
    cell.button.style = NIMKitColorButtonCellStyleBlue;
    [cell.button setTitle:bodyData.title forState:UIControlStateNormal];
    return cell;
}

- (UITableViewCell *)buildTeamSwitchCell:(id<NTESCardBodyData>)bodyData indexPath:(NSIndexPath *)indexPath
{
    NIMTeamSwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TableSwitchReuseId];
    if (!cell) {
        cell = [[NIMTeamSwitchTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NIMTeamSwitchTableViewCell"];
        CGFloat left   = 15.f;
        CGFloat height = 1.f;
        UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(left, cell.nim_height - height, cell.nim_width, height)];
        sep.backgroundColor = NIMKit_UIColorFromRGB(0xebebeb);
        [cell addSubview:sep];
        [sep setTag:TableSepTag];
        sep.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    }
    UIView *sep = [cell viewWithTag:TableSepTag];
    sep.hidden = (indexPath.row + 1 == [self.tableView numberOfRowsInSection:indexPath.section]);
    cell.textLabel.text = bodyData.title;
    cell.switcher.on = bodyData.switchOn;
    cell.switchDelegate = self;
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *scections = self.bodyData[indexPath.section];
    id<NTESCardBodyData> bodyData = scections[indexPath.row];
    if ([bodyData respondsToSelector:@selector(actionDisabled)] && bodyData.actionDisabled) {
        return;
    }
    if ([bodyData respondsToSelector:@selector(action)]) {
        if (bodyData.action) {
            NIMKit_SuppressPerformSelectorLeakWarning([self performSelector:bodyData.action]);
        }
    }
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
                            [self.view makeToast:@"修改成功"];
                            [self refreshTableBody];
                            [self refreshTitle];
                        }else{
                            [self.view makeToast:@"修改失败"];
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
                        [self.view makeToast:@"退出失败"];
                    }
                }];
                break;
            }
            default:
                break;
        }
    }
}


#pragma mark - NIMMemberGroupViewDelegate
- (void)didSelectRemoveButtonWithMemberId:(NSString *)uid{
    __weak typeof(self) wself = self;
    [NIMKitProgressHUD show];
    [[NIMSDK sharedSDK].teamManager kickUsers:@[uid] fromTeam:self.team.teamId completion:^(NSError *error) {
        [NIMKitProgressHUD dismiss];
        if (!error) {
            [wself removeMembers:@[uid]];
            [wself refreshTableHeader:self.view.nim_width];
        }else{
            [wself.view makeToast:@"移除失败"];
        }
    }];
}

- (void)didSelectOperator:(NIMKitCardHeaderOpeator)opera{
    switch (opera) {
        case CardHeaderOpeatorAdd:{
            self.currentOpera = CardHeaderOpeatorAdd;
            NSMutableArray *users = [[NSMutableArray alloc] init];
            NSString *currentUserID = [[[NIMSDK sharedSDK] loginManager] currentAccount];
            [users addObject:currentUserID];
            [users addObjectsFromArray:self.headerUserIds];
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

#pragma mark - Refresh
- (void)refreshWithMembers:(NSArray*)members{
    self.headerData = [members mutableCopy];
    [self setUpTableView];
    [self refreshTableBody];
    [self refreshTableHeader:self.view.nim_width];
}

- (void)refreshTableHeader:(CGFloat)width{
    [self setupTableHeader:width];
}

- (void)refreshTableBody{
    self.bodyData = [self buildBodyData];
    [self.tableView reloadData];
}

- (void)refreshTitle{
    self.navigationItem.title = self.title;
}


- (void)setUpTableView{
    [self setupTableHeader:self.view.nim_width];
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.delegate        = self;
    self.tableView.dataSource      = self;
}

- (void)setupTableHeader:(CGFloat)width{
    self.headerView = [[NIMMemberGroupView alloc] initWithFrame:CGRectZero];
    self.headerView.delegate = self;
    NIMKitCardHeaderOpeator opeartor;
    if (self.myTeamInfo.type == NIMTeamMemberTypeOwner) {
        opeartor = CardHeaderOpeatorAdd | CardHeaderOpeatorRemove;
    }else{
        opeartor = CardHeaderOpeatorAdd;
    }
    [self.headerView refreshUids:self.headerUserIds operators:opeartor];
    CGSize size = [self.headerView sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    self.headerView.nim_size = size;
    self.headerView.enableRemove = self.currentOpera == CardHeaderOpeatorRemove;
    self.tableView.tableHeaderView = self.headerView;
}


#pragma mark - Private
- (NSArray*)headerUserIds{
    NSMutableArray * uids = [[NSMutableArray alloc] init];
    for (id<NIMKitCardHeaderData> data in self.headerData) {
        if ([data respondsToSelector:@selector(memberId)] && data.memberId.length) {
            [uids addObject:data.memberId];
        }
    }
    return uids;
}


- (id<NTESCardBodyData>)bodyDataAtIndexPath:(NSIndexPath*)indexpath{
    NSArray *sectionData = self.bodyData[indexpath.section];
    return sectionData[indexpath.row];
}

- (void)addMembers:(NSArray*)members{
    NSInteger opeatorCount = 0;
    for (id<NIMKitCardHeaderData> data in self.headerData.reverseObjectEnumerator.allObjects) {
        if ([data respondsToSelector:@selector(opera)]) {
            opeatorCount++;
        }else{
            break;
        }
    }
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(self.headerData.count - opeatorCount, members.count)];
    [self.headerData insertObjects:members atIndexes:indexSet];
    [self refreshWithMembers:self.headerData];
}

- (void)removeMembers:(NSArray*)members{
    for (id object in members) {
        if ([object isKindOfClass:[NSString class]]) {
            for (id<NIMKitCardHeaderData> data in self.headerData) {
                if ([data respondsToSelector:@selector(memberId)] && [data.memberId isEqualToString:object]) {
                    [self.headerData removeObject:data];
                    break;
                }
            }
        }else{
            [self.headerData removeObject:object];
        }
    }
    [self refreshWithMembers:self.headerData];
}


@end
