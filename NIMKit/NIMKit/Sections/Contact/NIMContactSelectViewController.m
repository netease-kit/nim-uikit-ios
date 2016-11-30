//
//  NIMContactSelectViewController.m
//  NIMKit
//
//  Created by chris on 15/9/14.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMContactSelectViewController.h"
#import "NIMContactSelectTabView.h"
#import "NIMContactPickedView.h"
#import "NIMGroupedUsrInfo.h"
#import "NIMGroupedDataCollection.h"
#import "NIMContactDataCell.h"
#import "UIView+NIM.h"
#import "NIMKit.h"
#import "UIView+Toast.h"

@interface NIMContactSelectViewController ()<UITableViewDataSource, UITableViewDelegate, NIMContactPickedViewDelegate>{
    NSMutableArray *_selectecContacts;
}
@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) NIMContactSelectTabView *selectIndicatorView;

@property (nonatomic, assign) NSInteger maxSelectCount;

@property (nonatomic, assign) NIMContactSelectType selectType;

@property (nonatomic, strong) NIMGroupedDataCollection *data;

@end

@implementation NIMContactSelectViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        _maxSelectCount = NSIntegerMax;
    }
    return self;
}

- (instancetype)initWithConfig:(id<NIMContactSelectConfig>) config{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        self.config = config;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    
    [self.view addSubview:self.selectIndicatorView];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.navigationItem.title = [self.config respondsToSelector:@selector(title)] ? [self.config title] : @"选择联系人";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancelBtnClick:)];
    self.selectIndicatorView.pickedView.delegate = self;
    [self.selectIndicatorView.doneButton addTarget:self action:@selector(onDoneBtnClick:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.selectIndicatorView.nim_width = self.view.nim_width;
    self.tableView.nim_height = self.view.nim_height - self.selectIndicatorView.nim_height;
    self.selectIndicatorView.nim_bottom = self.view.nim_height;
}

- (void)show{
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    [vc presentViewController:[[UINavigationController alloc] initWithRootViewController:self] animated:YES completion:nil];
}

- (void)setConfig:(id<NIMContactSelectConfig>)config{
    _config = config;
    if ([config respondsToSelector:@selector(maxSelectedNum)]) {
        _maxSelectCount = [config maxSelectedNum];
    }
    [self makeData];
}

- (void)onCancelBtnClick:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^() {
        if (self.cancelBlock) {
            self.cancelBlock();
            self.cancelBlock = nil;
        }
        if([_delegate respondsToSelector:@selector(didCancelledSelect)]) {
            [_delegate didCancelledSelect];
        }
    }];
}

- (IBAction)onDoneBtnClick:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^() {
        
        if (_selectecContacts.count) {
            if ([self.delegate respondsToSelector:@selector(didFinishedSelect:)]) {
                [self.delegate didFinishedSelect:_selectecContacts];
            }
            if (self.finshBlock) {
                self.finshBlock(_selectecContacts);
                self.finshBlock = nil;
            }
        }
        else {
            if([_delegate respondsToSelector:@selector(didCancelledSelect)]) {
                [_delegate didCancelledSelect];
            }
            if (self.cancelBlock) {
                self.cancelBlock();
                self.cancelBlock = nil;
            }
        }
    }];
}


- (void)makeData{
    self.selectType = NIMContactSelectTypeFriend;
    if ([self.config respondsToSelector:@selector(selectType)]) {
        self.selectType = [self.config selectType];
    }
    switch (self.selectType) {
        case NIMContactSelectTypeFriend:{
            NSMutableArray *data = [[NIMSDK sharedSDK].userManager.myFriends mutableCopy];
            NSMutableArray *myFriendArray = [[NSMutableArray alloc] init];
            for (NIMUser *user in data) {
                [myFriendArray addObject:user.userId];
            }
            NSArray *uids = [self filterData:myFriendArray];
            self.data = [self makeUserInfoData:uids];
            break;
        }
        case NIMContactSelectTypeTeamMember:{
            if ([self.config respondsToSelector:@selector(teamId)]) {
                NSString *teamId = [self.config teamId];
                __weak typeof(self) wself = self;
                [[NIMSDK sharedSDK].teamManager fetchTeamMembers:teamId completion:^(NSError *error, NSArray *members) {
                    if (!error) {
                        NSMutableArray *data = [[NSMutableArray alloc] init];
                        for (NIMTeamMember *member in members) {
                            [data addObject:member.userId];
                        }
                        NSArray *uids = [wself filterData:data];
                        wself.data = [wself makeTeamMemberInfoData:uids teamId:teamId];
                    }
                }];
            }
            break;
        }
        case NIMContactSelectTypeTeam:{
            NSMutableArray *teams = [[NSMutableArray alloc] init];
            NSMutableArray *data = [[NIMSDK sharedSDK].teamManager.allMyTeams mutableCopy];
            for (NIMTeam *team in data) {
                [teams addObject:team.teamId];
            }
            NSArray *uids = [self filterData:teams];
            self.data = [self makeTeamInfoData:uids];
            break;
        }
        default:
            break;
    }
    if ([self.config respondsToSelector:@selector(alreadySelectedMemberId)]) {
        _selectecContacts = [[self.config alreadySelectedMemberId] mutableCopy];
    }
    _selectecContacts = _selectecContacts.count ? _selectecContacts : [NSMutableArray array];
    for (NSString *selectId in _selectecContacts) {
        NIMKitInfo *info;
        if (self.selectType == NIMContactSelectTypeTeam) {
            info = [[NIMKit sharedKit] infoByTeam:selectId];
        }else{
            info = [[NIMKit sharedKit] infoByUser:selectId];
        }
        [self.selectIndicatorView.pickedView addMemberInfo:info];
    }
}

- (NSArray *)filterData:(NSMutableArray *)data{
    if (data) {
        if ([self.config respondsToSelector:@selector(filterIds)]) {
            NSArray *ids = [self.config filterIds];
            [data removeObjectsInArray:ids];
        }
        return data;
    }
    return nil;
}

- (NIMGroupedDataCollection *)makeUserInfoData:(NSArray *)uids{
    NIMGroupedDataCollection *collection = [[NIMGroupedDataCollection alloc] init];
    NSMutableArray *members = [[NSMutableArray alloc] init];
    for (NSString *uid in uids) {
        NIMGroupUser *user = [[NIMGroupUser alloc] initWithUserId:uid];
        [members addObject:user];
    }
    collection.members = members;
    return collection;
}

- (NIMGroupedDataCollection *)makeTeamMemberInfoData:(NSArray *)uids teamId:(NSString *)teamId{
    NIMGroupedDataCollection *collection = [[NIMGroupedDataCollection alloc] init];
    NSMutableArray *members = [[NSMutableArray alloc] init];
    for (NSString *uid in uids) {
        NIMGroupTeamMember *user = [[NIMGroupTeamMember alloc] initWithUserId:uid teamId:teamId];
        [members addObject:user];
    }
    collection.members = members;
    return collection;
}

- (NIMGroupedDataCollection *)makeTeamInfoData:(NSArray *)teamIds{
    NIMGroupedDataCollection *collection = [[NIMGroupedDataCollection alloc] init];
    NSMutableArray *members = [[NSMutableArray alloc] init];
    for (NSString *teamId in teamIds) {
        NIMGroupTeam *team = [[NIMGroupTeam alloc] initWithTeam:teamId];
        [members addObject:team];
    }
    collection.members = members;
    return collection;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.data groupCount];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.data memberCountOfGroup:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.data titleOfGroup:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<NIMGroupMemberProtocol> contactItem = [self.data memberOfIndex:indexPath];
    NIMContactDataCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SelectContactCellID"];
    if (cell == nil) {
        cell = [[NIMContactDataCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SelectContactCellID"];
    }
    cell.accessoryBtn.hidden = NO;
    cell.accessoryBtn.selected = [_selectecContacts containsObject:[contactItem memberId]];
    if (self.selectType == NIMContactSelectTypeTeam) {
        [cell refreshTeam:contactItem];
    }else{
        [cell refreshUser:contactItem];
    }
    return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [self.data sortedGroupTitles];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<NIMGroupMemberProtocol> member = [self.data memberOfIndex:indexPath];
    NSString *memberId = [(id<NIMGroupMemberProtocol>)member memberId];
    NIMContactDataCell *cell = (NIMContactDataCell *)[tableView cellForRowAtIndexPath:indexPath];
    NIMKitInfo *info;
    if (self.selectType == NIMContactSelectTypeTeam) {
        info = [[NIMKit sharedKit] infoByTeam:memberId];
    }else{
        info = [[NIMKit sharedKit] infoByUser:memberId];
    }
    if([_selectecContacts containsObject:memberId]) {
        [_selectecContacts removeObject:memberId];
        cell.accessoryBtn.selected = NO;
        [self.selectIndicatorView.pickedView removeMemberInfo:info];
    } else if(_selectecContacts.count >= _maxSelectCount) {
        if ([self.config respondsToSelector:@selector(selectedOverFlowTip)]) {
            NSString *tip = [self.config selectedOverFlowTip];
            [self.view makeToast:tip duration:2.0 position:CSToastPositionCenter];
        }
        cell.accessoryBtn.selected = NO;
    } else {
        [_selectecContacts addObject:memberId];
        cell.accessoryBtn.selected = YES;
        [self.selectIndicatorView.pickedView addMemberInfo:info];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - ContactPickedViewDelegate

- (void)removeUser:(NSString *)userId {
    [_selectecContacts removeObject:userId];
    [_tableView reloadData];
}


#pragma mark - Private
- (NIMContactSelectTabView *)selectIndicatorView{
    if (_selectIndicatorView) {
        return _selectIndicatorView;
    }
    CGFloat tabHeight = 50.f;
    CGFloat tabWidth  = 320.f;
    _selectIndicatorView = [[NIMContactSelectTabView alloc] initWithFrame:CGRectMake(0, 0, tabWidth, tabHeight)];
    return _selectIndicatorView;
}
@end

