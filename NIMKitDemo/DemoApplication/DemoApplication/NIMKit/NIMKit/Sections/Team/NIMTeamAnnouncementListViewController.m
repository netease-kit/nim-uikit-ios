//
//  TeamAnnouncementListViewController.m
//  NIM
//
//  Created by Xuhui on 15/3/31.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMTeamAnnouncementListViewController.h"
#import "NIMUsrInfoData.h"
#import "NIMCreateTeamAnnouncement.h"
#import "NIMTeamAnnouncementListCell.h"
#import "UIView+Toast.h"
#import "SVProgressHUD.h"

typedef NS_ENUM(NSInteger, TeamAnnouncementSectionType) {
    TeamAnnouncementSectionTitle = 1,
    TeamAnnouncementSectionInfo = 2,
    TeamAnnouncementSectionLine = 3,
    TeamAnnouncementSectionContent = 4
};

@interface NIMTeamAnnouncementListViewController () <UITableViewDelegate, UITableViewDataSource, NTESCreateTeamAnnouncementDelegate> {
    
}

@property (nonatomic,strong) NSMutableArray *announcements;;

@property (nonatomic,strong) UITableView *tableView;

@end

@implementation NIMTeamAnnouncementListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if(_canCreateAnnouncement) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"新建" style:UIBarButtonItemStylePlain target:self action:@selector(onCreateAnnouncement:)];
    }
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    self.navigationItem.title = @"群公告";
    [self.tableView registerClass:[NIMTeamAnnouncementListCell class] forCellReuseIdentifier:@"NIMTeamAnnouncementListCell"];
    self.tableView.rowHeight = 267;
    [self.tableView setTableFooterView:[UIView new]];
    if (self.team.announcement.length) {
        NSArray *data = [NSJSONSerialization JSONObjectWithData:[self.team.announcement dataUsingEncoding:NSUTF8StringEncoding] options:0 error:0];
        _announcements = [NSMutableArray arrayWithArray:data];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)onCreateAnnouncement:(id)sender {
    NIMCreateTeamAnnouncement *vc = [[NIMCreateTeamAnnouncement alloc] initWithNibName:nil bundle:nil];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _announcements.lastObject ? 1 : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *announcement = _announcements.lastObject;
    NIMTeamAnnouncementListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NIMTeamAnnouncementListCell"];
    [cell refreshData:announcement team:self.team];
    cell.userInteractionEnabled = NO;
    return cell;
}

#pragma mark - CreateTeamAnnouncementDelegate
NSString *NTESCreatAnnouncementNotification = @"NTESCreatAnnouncementNotification";

- (void)createTeamAnnouncementCompleteWithTitle:(NSString *)title content:(NSString *)content {
    if (title.length && content.length) {
        NSDictionary *announcement = @{@"title": title,
                                       @"content": content,
                                       @"creator": [[NIMSDK sharedSDK].loginManager currentAccount],
                                       @"time": @((NSInteger)[NSDate date].timeIntervalSince1970)};
        NSData *data = [NSJSONSerialization dataWithJSONObject:@[announcement] options:0 error:nil];
        self.team.announcement = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }else{
        self.team.announcement = nil;
    }
    __weak typeof(self) wself = self;
    [SVProgressHUD show];
    [[NIMSDK sharedSDK].teamManager updateTeamAnnouncement:[self.team.announcement copy] teamId:self.team.teamId completion:^(NSError *error) {
        [SVProgressHUD dismiss];
        if(!error && wself) {
            [wself.view makeToast:@"创建成功"];
            if (self.team.announcement.length) {
                NSArray *data = [NSJSONSerialization JSONObjectWithData:[self.team.announcement dataUsingEncoding:NSUTF8StringEncoding] options:0 error:0];
                wself.announcements = [NSMutableArray arrayWithArray:data];
            }else{
                wself.announcements = nil;
            }
            
            [wself.tableView reloadData];
            [[NSNotificationCenter defaultCenter] postNotificationName:NTESCreatAnnouncementNotification object:nil];
        } else {
            [wself.view makeToast:@"创建失败"];
        }
    }];

}

@end
