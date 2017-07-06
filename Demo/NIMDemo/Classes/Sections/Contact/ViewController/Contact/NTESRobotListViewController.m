//
//  NTESRobotListViewController.m
//  NIM
//
//  Created by chris on 2017/6/23.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import "NTESRobotListViewController.h"
#import "UIView+NTES.h"
#import "NTESUserListCell.h"
#import "SVProgressHUD.h"
#import "NTESContactDataMember.h"
#import "UIView+Toast.h"
#import "NTESRobotCardViewController.h"
#import "NTESSessionViewController.h"

@interface NTESRobotListViewController ()<UITableViewDelegate,UITableViewDataSource,NIMUserManagerDelegate,NTESUserListCellDelegate>

@property (nonatomic,strong) NSMutableArray *data;
@end

@implementation NTESRobotListViewController


- (void)dealloc
{
    [self removeListenr];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpNavItem];
    [self addListener];
    self.data = self.robots;
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}


- (void)setUpNavItem{
    self.navigationItem.title = @"智能机器人";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60.f;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identity = @"cell";
    NTESUserListCell *cell = [tableView dequeueReusableCellWithIdentifier:identity];
    if (!cell) {
        cell = [[NTESUserListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identity];
        cell.delegate = self;
    }
    NTESContactDataMember *member = self.data[indexPath.row];
    [cell refreshWithMember:member];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NTESContactDataMember *member = self.data[indexPath.row];

    NTESRobotCardViewController *vc = [[NTESRobotCardViewController alloc] initWithUserId:member.info.infoId];
    [self.navigationController pushViewController:vc animated:YES];
}



#pragma mark - NTESUserListCellDelegate
- (void)didTouchUserListAvatar:(NSString *)userId{
    NTESRobotCardViewController *vc = [[NTESRobotCardViewController alloc] initWithUserId:userId];
    [self.navigationController pushViewController:vc animated:YES];
}


#pragma mark - Notification
- (void)onUserInfoChanged:(NSNotification *)notification
{
    self.data = self.robots;
    [self.tableView reloadData];
}

#pragma mark - Private

- (void)addListener
{
    extern NSString *NIMKitUserInfoHasUpdatedNotification;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoChanged:) name:NIMKitUserInfoHasUpdatedNotification object:nil];
}

- (void)removeListenr
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSMutableArray *)robots{
    NSMutableArray *list = [[NSMutableArray alloc] init];
    for (NIMRobot *robot in [NIMSDK sharedSDK].robotManager.allRobots) {
        NTESContactDataMember *member = [[NTESContactDataMember alloc] init];
        NIMKitInfo *info = [[NIMKit sharedKit] infoByUser:robot.userId option:nil];
        member.info = info;
        [list addObject:member];
    }
    return list;
}


@end
