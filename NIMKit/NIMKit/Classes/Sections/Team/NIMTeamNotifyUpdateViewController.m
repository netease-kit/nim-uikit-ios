//
//  NIMTeamNotifyUpdateViewController.m
//  NIMKit
//
//  Created by chris on 2017/9/20.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import "NIMTeamNotifyUpdateViewController.h"
#import "NIMTeamCardRowItem.h"
#import <NIMSDK/NIMSDK.h>
#import "NIMGlobalMacro.h"
#import "NIMKitProgressHUD.h"
#import "UIView+Toast.h"

@interface NIMTeamNotifyUpdateViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,strong) NIMTeam *team;

@property (nonatomic,strong) UITableView *tableView;

@property (nonatomic,strong) NSArray *bodyData;   //表身数据

@property (nonatomic,assign) NIMTeamNotifyState selectState;

@end

@implementation NIMTeamNotifyUpdateViewController

- (instancetype)initTeam:(NIMTeam *)team
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        _team = team;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"消息提醒";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor blackColor];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    
    self.tableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = NIMKit_UIColorFromRGB(0xecf1f5);
    
    self.selectState = [[NIMSDK sharedSDK].teamManager notifyStateForNewMsg:self.team.teamId];
    self.bodyData = [self buildBodyData];
}


- (void)onDone:(id)sender
{
    if ([[NIMSDK sharedSDK].teamManager notifyStateForNewMsg:self.team.teamId] != self.selectState)
    {
        [NIMKitProgressHUD show];
        __weak typeof(self) weakSelf = self;
        [[NIMSDK sharedSDK].teamManager updateNotifyState:self.selectState inTeam:self.team.teamId completion:^(NSError * _Nullable error)
        {
            [NIMKitProgressHUD dismiss];
            if (!error)
            {
                [weakSelf.navigationController popViewControllerAnimated:YES];
                [weakSelf.navigationController.view makeToast:@"修改成功" duration:2.0 position:CSToastPositionCenter];
            }
            else
            {
                [weakSelf.view makeToast:@"修改失败" duration:2.0 position:CSToastPositionCenter];
            }
            
        }];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (NSArray*)buildBodyData
{
    NIMTeamNotifyState state = self.selectState;
    
    NIMTeamCardRowItem *notifyAll = [[NIMTeamCardRowItem alloc] init];
    notifyAll.title               = @"提醒所有消息";
    notifyAll.rowHeight           = 50.f;
    notifyAll.type                = (state == NIMTeamNotifyStateAll)? TeamCardRowItemTypeCheckMark : TeamCardRowItemTypeCommon;
    notifyAll.value               = @(NIMTeamNotifyStateAll);
    
    NIMTeamCardRowItem *notifyManager = [[NIMTeamCardRowItem alloc] init];
    notifyManager.title            = @"只提醒管理员消息";
    notifyManager.rowHeight        = 50.f;
    notifyManager.type             = (state == NIMTeamNotifyStateOnlyManager)? TeamCardRowItemTypeCheckMark : TeamCardRowItemTypeCommon;
    notifyManager.value            = @(NIMTeamNotifyStateOnlyManager);

    NIMTeamCardRowItem *notifyNone = [[NIMTeamCardRowItem alloc] init];
    notifyNone.title               = @"不提醒任何消息";
    notifyNone.rowHeight           = 50.f;
    notifyNone.type                = (state == NIMTeamNotifyStateNone)? TeamCardRowItemTypeCheckMark : TeamCardRowItemTypeCommon;
    notifyNone.value               = @(NIMTeamNotifyStateNone);
    
    return @[@[notifyAll,notifyManager,notifyNone]];
}



#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.bodyData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionData = self.bodyData[section];
    return sectionData.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<NTESCardBodyData> bodyData = [self bodyDataAtIndexPath:indexPath];
    return bodyData.rowHeight;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = NIMKit_UIColorFromRGB(0xecf1f5);
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    id<NTESCardBodyData> bodyData = [self bodyDataAtIndexPath:indexPath];
    static NSString *NIMTeamTableCellReuseId = @"cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:NIMTeamTableCellReuseId];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NIMTeamTableCellReuseId];
    }
    cell.accessoryType  = (bodyData.type == TeamCardRowItemTypeCheckMark)? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.textLabel.text = bodyData.title;
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *scections = self.bodyData[indexPath.section];
    id<NTESCardBodyData> bodyData = scections[indexPath.row];
    self.selectState = [[bodyData value] integerValue];
    self.bodyData = [self buildBodyData];
    [self.tableView reloadData];
}


- (id<NTESCardBodyData>)bodyDataAtIndexPath:(NSIndexPath*)indexpath{
    NSArray *sectionData = self.bodyData[indexpath.section];
    return sectionData[indexpath.row];
}

@end
