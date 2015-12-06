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
#import "NIMKitColorButtonCell.h"
#import "NIMAdvancedTeamMemberCell.h"
#import "UIView+NIMKitToast.h"
#import "NIMTeamMemberCardViewController.h"
#import "NIMCardMemberItem.h"
#import "NIMContactSelectViewController.h"
#import "NIMGroupedUsrInfo.h"
#import "NIMTeamMemberListViewController.h"
#import "NIMTeamAnnouncementListViewController.h"
#import "NIMKitUtil.h"
#import "NIMTeamSwitchTableViewCell.h"

#pragma mark - Team Header View
#define CardHeaderHeight 89
@interface NIMAdvancedTeamCardHeaderView : UIView

@property (nonatomic,strong) UIImageView *avatar;

@property (nonatomic,strong) UILabel *titleLabel;

@property (nonatomic,strong) UILabel *numberLabel;

@property (nonatomic,strong) UILabel *createTimeLabel;

@property (nonatomic,strong) NIMTeam *team;

@end

@implementation NIMAdvancedTeamCardHeaderView

- (instancetype)initWithTeam:(NIMTeam*)team{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _team = team;
        _avatar          = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"avatar_team"]];
        _titleLabel                      = [[UILabel alloc]initWithFrame:CGRectZero];
        _titleLabel.backgroundColor      = [UIColor clearColor];
        _titleLabel.font                 = [UIFont systemFontOfSize:17.f];
        _titleLabel.textColor            = NIMKit_UIColorFromRGB(0x333333);
        _numberLabel                     = [[UILabel alloc]initWithFrame:CGRectZero];
        _numberLabel.backgroundColor     = [UIColor clearColor];
        _numberLabel.font                = [UIFont systemFontOfSize:14.f];
        _numberLabel.textColor           = NIMKit_UIColorFromRGB(0x999999);
        _createTimeLabel                 = [[UILabel alloc]initWithFrame:CGRectZero];
        _createTimeLabel.backgroundColor = [UIColor clearColor];
        _createTimeLabel.font            = [UIFont systemFontOfSize:14.f];
        _createTimeLabel.textColor       = NIMKit_UIColorFromRGB(0x999999);
        [self addSubview:_avatar];
        [self addSubview:_titleLabel];
        [self addSubview:_numberLabel];
        [self addSubview:_createTimeLabel];
        
        self.backgroundColor = NIMKit_UIColorFromRGB(0xecf1f5);
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size{
    return CGSizeMake(size.width, CardHeaderHeight);
}

- (NSString*)formartCreateTime{
    NSTimeInterval timestamp = self.team.createTime;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:timestamp]];
    if (!dateString.length) {
        return @"未知时间创建";
    }
    return [NSString stringWithFormat:@"于%@创建",dateString];
}


#define AvatarLeft 20
#define AvatarTop  25
#define TitleAndAvatarSpacing 10
#define NumberAndTimeSpacing  10
#define MaxTitleLabelWidth 200
- (void)layoutSubviews{
    [super layoutSubviews];
    _titleLabel.text  = self.team.teamName;
    _numberLabel.text = self.team.teamId;
    _createTimeLabel.text  = [self formartCreateTime];
    [_titleLabel sizeToFit];
    [_createTimeLabel sizeToFit];
    [_numberLabel sizeToFit];

    self.titleLabel.nim_width = self.titleLabel.nim_width > MaxTitleLabelWidth ? MaxTitleLabelWidth : self.titleLabel.nim_width;
    self.avatar.nim_left = AvatarLeft;
    self.avatar.nim_top  = AvatarTop;
    self.titleLabel.nim_left = self.avatar.nim_right + TitleAndAvatarSpacing;
    self.titleLabel.nim_top  = self.avatar.nim_top;
    self.numberLabel.nim_left   = self.titleLabel.nim_left;
    self.numberLabel.nim_bottom = self.avatar.nim_bottom;
    self.createTimeLabel.nim_left   = self.numberLabel.nim_right + NumberAndTimeSpacing;
    self.createTimeLabel.nim_bottom = self.numberLabel.nim_bottom;
}

@end

#pragma mark - Card VC
#define TableCellReuseId        @"tableCell"
#define TableButtonCellReuseId  @"tableButtonCell"
#define TableMemberCellReuseId  @"tableMemberCell"
#define TableSwitchReuseId      @"tableSwitchCell"

@interface NIMAdvancedTeamCardViewController ()<NIMAdvancedTeamMemberCellActionDelegate,NIMContactSelectDelegate,NIMTeamSwitchProtocol,UIActionSheetDelegate,UITableViewDataSource,UITableViewDelegate>{
    
    UIAlertView *_updateTeamNameAlertView;
    UIAlertView *_updateTeamNickAlertView;
    UIAlertView *_updateTeamIntroAlertView;
    UIAlertView *_quitTeamAlertView;
    UIAlertView *_dismissTeamAlertView;
    
    UIActionSheet *_moreActionSheet;
    UIActionSheet *_authActionSheet;
}

@property (nonatomic,strong) UITableView *tableView;

@property(nonatomic,strong) NIMTeam *team;

@property(nonatomic,strong) NIMTeamMember *myTeamInfo;

@property(nonatomic,copy) NSArray *bodyData;

@property(nonatomic,copy) NSArray *memberData;

@end

@implementation NIMAdvancedTeamCardViewController

- (instancetype)initWithTeam:(NIMTeam *)team{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _team = team;
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    NIMAdvancedTeamCardHeaderView *headerView = [[NIMAdvancedTeamCardHeaderView alloc] initWithTeam:self.team];
    headerView.nim_size = [headerView sizeThatFits:self.view.nim_size];
    self.navigationItem.title = self.team.teamName;
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    
    self.tableView.tableHeaderView = headerView;
    self.tableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = NIMKit_UIColorFromRGB(0xecf1f5);
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    __weak typeof(self) wself = self;
    [self requestData:^(NSError *error) {
        if (!error) {
            [wself reloadData];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
}

- (void)reloadData{
    self.myTeamInfo = [[NIMSDK sharedSDK].teamManager teamMember:self.myTeamInfo.userId inTeam:self.myTeamInfo.teamId];
    [self buildBodyData];
    [self.tableView reloadData];
    NIMAdvancedTeamCardHeaderView *headerView = (NIMAdvancedTeamCardHeaderView*)self.tableView.tableHeaderView;
    headerView.titleLabel.text = self.team.teamName;;
    self.navigationItem.title  = self.team.teamName;
    if (self.myTeamInfo.type == NIMTeamMemberTypeOwner) {
        UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(onMore:)];
        self.navigationItem.rightBarButtonItem = buttonItem;
    }else{
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)requestData:(void(^)(NSError *error)) handler{
    __weak typeof(self) wself = self;
    [[NIMSDK sharedSDK].teamManager fetchTeamMembers:self.team.teamId completion:^(NSError *error, NSArray *members) {
        if (!error) {
            for (NIMTeamMember *member in members) {
                if ([member.userId isEqualToString:[NIMSDK sharedSDK].loginManager.currentAccount]) {
                    wself.myTeamInfo = member;
                    break;
                }
            }
            wself.memberData = members;
        }else if(error.code == NIMRemoteErrorCodeTeamNotMember){
            [wself.view nimkit_makeToast:@"你已经不在群里" duration:2
                                position:NIMKitToastPositionCenter];
        }else{
            [wself.view nimkit_makeToast:[NSString stringWithFormat:@"拉好友失败 error: %zd",error.code] duration:2
                                position:NIMKitToastPositionCenter];
        }
        handler(error);
    }];
}

- (void)buildBodyData{
    BOOL isManager = self.myTeamInfo.type == NIMTeamMemberTypeManager || self.myTeamInfo.type == NIMTeamMemberTypeOwner;
    BOOL isOwner   = self.myTeamInfo.type == NIMTeamMemberTypeOwner;
    
    NIMTeamCardRowItem *teamMember = [[NIMTeamCardRowItem alloc] init];
    teamMember.title  = @"群成员";
    teamMember.rowHeight = 111.f;
    teamMember.action = @selector(enterMemberCard);
    teamMember.type   = TeamCardRowItemTypeTeamMember;
    
    NIMTeamCardRowItem *teamName = [[NIMTeamCardRowItem alloc] init];
    teamName.title = @"群名称";
    teamName.subTitle = self.team.teamName;
    teamName.action = @selector(updateTeamName);
    teamName.rowHeight = 50.f;
    teamName.type   = TeamCardRowItemTypeCommon;
    teamName.actionDisabled = !isManager;
    
    NIMTeamCardRowItem *teamNick = [[NIMTeamCardRowItem alloc] init];
    teamNick.title = @"群昵称";
    teamNick.subTitle = self.myTeamInfo.nickname;
    teamNick.action = @selector(updateTeamNick);
    teamNick.rowHeight = 50.f;
    teamNick.type   = TeamCardRowItemTypeCommon;

    
    NIMTeamCardRowItem *teamIntro = [[NIMTeamCardRowItem alloc] init];
    teamIntro.title = @"群介绍";
    teamIntro.subTitle = self.team.intro.length ? self.team.intro : (isManager ? @"点击填写群介绍" : @"");
    teamIntro.action = @selector(updateTeamIntro);
    teamIntro.rowHeight = 50.f;
    teamIntro.type   = TeamCardRowItemTypeCommon;
    teamIntro.actionDisabled = !isManager;
    
    NIMTeamCardRowItem *teamAnnouncement = [[NIMTeamCardRowItem alloc] init];
    teamAnnouncement.title = @"群公告";
    teamAnnouncement.subTitle = @"点击查看群公告";//self.team.announcement.length ? self.team.announcement : (isManager ? @"点击填写群公告" : @"");
    teamAnnouncement.action = @selector(updateTeamAnnouncement);
    teamAnnouncement.rowHeight = 50.f;
    teamAnnouncement.type   = TeamCardRowItemTypeCommon;
    
    
    NIMTeamCardRowItem *teamNotify = [[NIMTeamCardRowItem alloc] init];
    teamNotify.title  = @"消息提醒";
    teamNotify.switchOn = [self.team notifyForNewMsg];
    teamNotify.rowHeight = 50.f;
    teamNotify.type   = TeamCardRowItemTypeSwitch;

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
    itemAuth.subTitle = [self joinModeText:self.team.joinMode];
    itemAuth.action = @selector(changeAuthMode);
    itemAuth.actionDisabled = !isManager;
    itemAuth.rowHeight = 60.f;
    itemAuth.type   = TeamCardRowItemTypeCommon;
    

    
    if (isOwner) {
        self.bodyData = @[
                  @[teamMember],
                  @[teamName,teamNick,teamIntro,teamAnnouncement,teamNotify],
                  @[itemAuth],
                  @[itemDismiss]
                 ];
    }else{
        self.bodyData = @[
                 @[teamMember],
                 @[teamName,teamNick,teamIntro,teamAnnouncement,teamNotify],
                 @[itemAuth],
                 @[itemQuit]
                 ];
    }
}

- (id<NTESCardBodyData>)bodyDataAtIndexPath:(NSIndexPath*)indexpath{
    NSArray *sectionData = self.bodyData[indexpath.section];
    return sectionData[indexpath.row];
}

- (NSIndexPath *)cellIndexPathByTitle:(NSString *)title {
    __block NSInteger section = 0;
    __block NSInteger row = 0;
    [self.bodyData enumerateObjectsUsingBlock:^(NSArray *rows, NSUInteger s, BOOL *stop) {
        __block BOOL stopped = NO;
        [rows enumerateObjectsUsingBlock:^(NIMTeamCardRowItem *item, NSUInteger r, BOOL *stop) {
            if([item.title isEqualToString:title]) {
                section = s;
                row = r;
                *stop = YES;
                stopped = YES;
            }
        }];
        *stop = stopped;
    }];
    return [NSIndexPath indexPathForRow:row inSection:section];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    id<NTESCardBodyData> bodyData = [self bodyDataAtIndexPath:indexPath];
    if ([bodyData respondsToSelector:@selector(actionDisabled)] && bodyData.actionDisabled) {
        return;
    }
    if ([bodyData respondsToSelector:@selector(action)]) {
        if (bodyData.action) {
            NIMKit_SuppressPerformSelectorLeakWarning([self performSelector:bodyData.action]);
        }
    }
}

#pragma mark - UITableViewDataSource
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    id<NTESCardBodyData> bodyData = [self bodyDataAtIndexPath:indexPath];
    return bodyData.rowHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.bodyData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSArray *sectionData = self.bodyData[section];
    return sectionData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    id<NTESCardBodyData> bodyData = [self bodyDataAtIndexPath:indexPath];
    UITableViewCell * cell;
    NIMKitTeamCardRowItemType type = bodyData.type;
    switch (type) {
        case TeamCardRowItemTypeCommon:
            cell = [self builidCommonCell:bodyData];
            break;
        case TeamCardRowItemTypeRedButton:
            cell = [self builidRedButtonCell:bodyData];
            break;
        case TeamCardRowItemTypeTeamMember:
            cell = [self builidTeamMemberCell:bodyData];
            break;
        case TeamCardRowItemTypeSwitch:
            cell = [self buildTeamSwitchCell:bodyData];
            break;
        default:
            break;
    }
    return cell;
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


- (UITableViewCell*)builidCommonCell:(id<NTESCardBodyData>) bodyData{
    UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:TableCellReuseId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:TableCellReuseId];
        CGFloat left = 15.f;
        UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(left, cell.nim_height-1, cell.nim_width, 1.f)];
        sep.backgroundColor = NIMKit_UIColorFromRGB(0xebebeb);
        [cell addSubview:sep];
        sep.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    }
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

- (UITableViewCell*)builidRedButtonCell:(id<NTESCardBodyData>) bodyData{
    NIMKitColorButtonCell * cell = [self.tableView dequeueReusableCellWithIdentifier:TableButtonCellReuseId];
    if (!cell) {
        cell = [[NIMKitColorButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TableButtonCellReuseId];
    }
    cell.button.style = NIMKitColorButtonCellStyleRed;
    [cell.button setTitle:bodyData.title forState:UIControlStateNormal];
    return cell;
}

- (UITableViewCell*)builidTeamMemberCell:(id<NTESCardBodyData>) bodyData{
    NIMAdvancedTeamMemberCell * cell = [self.tableView dequeueReusableCellWithIdentifier:TableMemberCellReuseId];
    if (!cell) {
        cell = [[NIMAdvancedTeamMemberCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:TableMemberCellReuseId];
        cell.delegate = self;
    }
    [cell rereshWithTeam:self.team members:self.memberData width:self.tableView.nim_width];
    cell.textLabel.text = bodyData.title;
    cell.detailTextLabel.text = bodyData.subTitle;
    if ([bodyData respondsToSelector:@selector(actionDisabled)] && bodyData.actionDisabled) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }else{
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

- (UITableViewCell *)buildTeamSwitchCell:(id<NTESCardBodyData>)bodyData
{
    NIMTeamSwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TableSwitchReuseId];
    if (!cell) {
        cell = [[NIMTeamSwitchTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NIMTeamSwitchTableViewCell"];
    }
    cell.textLabel.text = bodyData.title;
    cell.switcher.on = bodyData.switchOn;
    cell.switchDelegate = self;
    
    return cell;
}

#pragma mark - Action
- (void)onMore:(id)sender{
    _moreActionSheet = [[UIActionSheet alloc] initWithTitle:@"请操作" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"转让群",@"转让群并退出",nil];
    [_moreActionSheet showInView:self.view];
}

- (void)updateTeamName{
    _updateTeamNameAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"修改群名称" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
    _updateTeamNameAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [_updateTeamNameAlertView show];
}

- (void)updateTeamNick{
    _updateTeamNickAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"修改群昵称" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
    _updateTeamNickAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [_updateTeamNickAlertView show];
}

- (void)updateTeamIntro{
    _updateTeamIntroAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"修改群介绍" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
    _updateTeamIntroAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [_updateTeamIntroAlertView show];
}

- (void)updateTeamAnnouncement{
    BOOL isManager = self.myTeamInfo.type == NIMTeamMemberTypeManager || self.myTeamInfo.type == NIMTeamMemberTypeOwner;
    NIMTeamAnnouncementListViewController *vc = [[NIMTeamAnnouncementListViewController alloc] initWithNibName:nil bundle:nil];
    vc.team = self.team;
    vc.canCreateAnnouncement = isManager;
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)quitTeam{
    _quitTeamAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"确认退出群聊?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
    [_quitTeamAlertView show];
}

- (void)dismissTeam{
    _dismissTeamAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"确认解散群聊?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
    [_dismissTeamAlertView show];
}


- (void)changeAuthMode{
    _authActionSheet = [[UIActionSheet alloc] initWithTitle:@"更改验证方式" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"允许任何人",@"需要验证",@"拒绝任何人", nil];
    [_authActionSheet showInView:self.view];
}

- (NSString*)joinModeText:(NIMTeamJoinMode)mode{
    switch (mode) {
        case NIMTeamJoinModeNoAuth:
            return @"允许任何人";
        case NIMTeamJoinModeNeedAuth:
            return @"需要验证";
        case NIMTeamJoinModeRejectAll:
            return @"拒绝任何人";
        default:
            break;
    }
}

- (void)enterMemberCard{
    NIMTeamMemberListViewController *vc = [[NIMTeamMemberListViewController alloc] initTeam:self.team members:self.memberData];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onStateChanged:(BOOL)on
{
    __weak typeof(self) weakSelf = self;
    [[[NIMSDK sharedSDK] teamManager] updateNotifyState:on
                                                 inTeam:[self.team teamId]
                                             completion:^(NSError *error) {
                                                 if (error) {
                                                     [weakSelf.view nimkit_makeToast:[NSString stringWithFormat:@"修改失败  error:%zd",error.code]
                                                                            duration:2
                                                                            position:NIMKitToastPositionCenter];
                                                 }
                                                 [weakSelf reloadData];
                                             }];
}


#pragma mark - NIMAdvancedTeamMemberCellActionDelegate

- (void)didSelectAddOpeartor{
    NSMutableArray *users = [[NSMutableArray alloc] init];
    for (NIMTeamMember *member in self.memberData) {
        [users addObject:member.userId];
    }
    NSString *currentUserID = [[[NIMSDK sharedSDK] loginManager] currentAccount];
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
    NSString *postscript = @"邀请你加入群组";
    [[NIMSDK sharedSDK].teamManager addUsers:selectedContacts toTeam:self.team.teamId postscript:postscript completion:^(NSError *error, NSArray *members) {
        if (!error) {
            [self.view nimkit_makeToast:@"邀请成功"
                               duration:2
                               position:NIMKitToastPositionCenter];
        }else{
            [self.view nimkit_makeToast:[NSString stringWithFormat:@"邀请失败 code:%zd",error.code]
                               duration:2
                               position:NIMKitToastPositionCenter];
        }
    }];
}

- (void)didCancelledSelect{
    
}


#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (alertView == _updateTeamNameAlertView) {
        [self updateTeamNameAlert:buttonIndex];
    }
    if (alertView == _updateTeamNickAlertView) {
        [self updateTeamNickAlert:buttonIndex];
    }
    if (alertView == _updateTeamIntroAlertView) {
        [self updateTeamIntroAlert:buttonIndex];
    }
    if (alertView == _quitTeamAlertView) {
        [self quitTeamAlert:buttonIndex];
    }
    if (alertView == _dismissTeamAlertView) {
        [self dismissTeamAlert:buttonIndex];
    }
}

- (void)updateTeamNameAlert:(NSInteger)index{
    switch (index) {
        case 0://取消
            break;
        case 1:{
            NSString *name = [_updateTeamNameAlertView textFieldAtIndex:0].text;
            if (name.length) {
                
                [[NIMSDK sharedSDK].teamManager updateTeamName:name teamId:self.team.teamId completion:^(NSError *error) {
                    if (!error) {
                        self.team.teamName = name;
                        [self.view nimkit_makeToast:@"修改成功" duration:2
                                           position:NIMKitToastPositionCenter];
                        [self reloadData];
                    }else{
                        [self.view nimkit_makeToast:[NSString stringWithFormat:@"修改失败 code:%zd",error.code] duration:2
                                           position:NIMKitToastPositionCenter];
                    }
                }];
            }
            break;
        }
        default:
            break;
    }
}

- (void)updateTeamNickAlert:(NSInteger)index{
    switch (index) {
        case 0://取消
            break;
        case 1:{
            NSString *name = [_updateTeamNickAlertView textFieldAtIndex:0].text;
            if (name.length) {
                NSString *currentUserId = [NIMSDK sharedSDK].loginManager.currentAccount;
                [[NIMSDK sharedSDK].teamManager updateUserNick:currentUserId newNick:name inTeam:self.team.teamId completion:^(NSError *error) {
                    if (!error) {
                        self.myTeamInfo.nickname = name;
                        [self.view nimkit_makeToast:@"修改成功"];
                        [self reloadData];
                    }else{
                        [self.view nimkit_makeToast:[NSString stringWithFormat:@"修改失败 code:%zd",error.code]];
                    }
                }];
            }
            break;
        }
        default:
            break;
    }
}

- (void)updateTeamIntroAlert:(NSInteger)index{
    switch (index) {
        case 0://取消
            break;
        case 1:{
            NSString *intro = [_updateTeamIntroAlertView textFieldAtIndex:0].text;
            if (intro.length) {
                
                [[NIMSDK sharedSDK].teamManager updateTeamIntro:intro teamId:self.team.teamId completion:^(NSError *error) {
                    if (!error) {
                        self.team.intro = intro;
                        [self.view nimkit_makeToast:@"修改成功"];
                        [self reloadData];
                    }else{
                        [self.view nimkit_makeToast:[NSString stringWithFormat:@"修改失败 code:%zd",error.code]];
                    }
                }];
            }
            break;
        }
        default:
            break;
    }
}

- (void)quitTeamAlert:(NSInteger)index{
    switch (index) {
        case 0://取消
            break;
        case 1:{
            [[NIMSDK sharedSDK].teamManager quitTeam:self.team.teamId completion:^(NSError *error) {
                if (!error) {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }else{
                    [self.view nimkit_makeToast:[NSString stringWithFormat:@"退出失败 code:%zd",error.code]];
                }
            }];
            break;
        }
        default:
            break;
    }

}

- (void)dismissTeamAlert:(NSInteger)index{
    switch (index) {
        case 0://取消
            break;
        case 1:{
            [[NIMSDK sharedSDK].teamManager dismissTeam:self.team.teamId completion:^(NSError *error) {
                if (!error) {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }else{
                    [self.view nimkit_makeToast:[NSString stringWithFormat:@"解散失败 code:%zd",error.code]];
                }
            }];
            break;
        }
        default:
            break;
    }
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)index{
    if (actionSheet == _moreActionSheet) {
        BOOL isLeave = NO;
        switch (index) {
            case 0:{
                isLeave = NO;
                break;
            case 1:
                isLeave = YES;
                break;
            }
            default:
                return;
                break;
        }
        __weak typeof(self) wself = self;
        __block ContactSelectFinishBlock finishBlock =  ^(NSArray * memeber){
            [[NIMSDK sharedSDK].teamManager transferManagerWithTeam:wself.team.teamId newOwnerId:memeber.firstObject isLeave:isLeave completion:^(NSError *error) {
                if (!error) {
                    [wself.view nimkit_makeToast:@"转移成功！" duration:2.0 position:NIMKitToastPositionCenter];
                    if (isLeave) {
                        [wself.navigationController popToRootViewControllerAnimated:YES];
                    }else{
                        [wself reloadData];
                    }
                }else{
                    [wself.view nimkit_makeToast:[NSString stringWithFormat:@"转移失败！code:%zd",error.code] duration:2.0 position:NIMKitToastPositionCenter];
                }
            }];
        };
        NSString *currentUserID = [[[NIMSDK sharedSDK] loginManager] currentAccount];
        NIMContactTeamMemberSelectConfig *config = [[NIMContactTeamMemberSelectConfig alloc] init];
        config.teamId = self.team.teamId;
        config.filterIds = @[currentUserID];
        NIMContactSelectViewController *vc = [[NIMContactSelectViewController alloc] initWithConfig:config];
        vc.finshBlock = finishBlock;
        [vc show];
    }
    
    if (actionSheet == _authActionSheet) {
        if (index == _authActionSheet.cancelButtonIndex) {
            return;
        }
        [[NIMSDK sharedSDK].teamManager updateTeamJoinMode:index teamId:self.team.teamId completion:^(NSError *error) {
            if (!error) {
                self.team.joinMode = index;
                [self.view nimkit_makeToast:@"修改成功"];
                [self reloadData];
            }else{
                [self.view nimkit_makeToast:[NSString stringWithFormat:@"修改失败 code:%zd",error.code]];
            }
            
        }];
    }
}


#pragma mark - 旋转处理 (iOS7)

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    NSIndexPath *reloadIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[reloadIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - 旋转处理 (iOS8 or above)
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        NSIndexPath *reloadIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView reloadRowsAtIndexPaths:@[reloadIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } completion:nil];
}



@end


