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
#import "NIMKitDependency.h"
#import "NIMKitProgressHUD.h"
#import "NIMGlobalMacro.h"

@interface NIMTeamAnnouncementListViewController () <UITableViewDelegate,
                                                     UITableViewDataSource,
                                                     NTESCreateTeamAnnouncementDelegate>

@property (nonatomic,strong) NSMutableArray *announcements;;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NIMTeamAnnouncementListOption *option;

@end

@implementation NIMTeamAnnouncementListViewController

- (instancetype)initWithOption:(NIMTeamAnnouncementListOption *)option {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.option = option;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)setupUI {
    [self.view addSubview:self.tableView];
    self.navigationItem.title = @"群公告".nim_localized;
    if(_option.canCreateAnnouncement) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"新建".nim_localized style:UIBarButtonItemStylePlain target:self action:@selector(onCreateAnnouncement:)];
    }
}

- (void)setOption:(NIMTeamAnnouncementListOption *)option {
    _option = option;
    [self updateAnnouncementsWithContent:option.announcement];
}

- (void)updateAnnouncementsWithContent:(NSString *)content {
    if (content) {
        NSData *contentData = [content dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *datas = [NSJSONSerialization JSONObjectWithData:contentData options:0 error:0];
        _announcements = [NSMutableArray arrayWithArray:datas];
    } else {
        _announcements = nil;
    }
}

- (void)onCreateAnnouncement:(id)sender {
    NIMCreateTeamAnnouncement *vc = [[NIMCreateTeamAnnouncement alloc] initWithNibName:nil bundle:nil];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _announcements.lastObject ? 1 : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *announcement = _announcements.lastObject;
    NIMTeamAnnouncementListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NIMTeamAnnouncementListCell"];
    [cell refreshData:announcement nick:_option.nick];
    cell.userInteractionEnabled = NO;
    return cell;
}

#pragma mark - CreateTeamAnnouncementDelegate
- (void)createTeamAnnouncementCompleteWithTitle:(NSString *)title content:(NSString *)content {
    NSString *ret = nil;
    NSDictionary *announcement = @{@"title": title ?: @"",
                                   @"content": content ?: @"",
                                   @"creator": [[NIMSDK sharedSDK].loginManager currentAccount],
                                   @"time": @((NSInteger)[NSDate date].timeIntervalSince1970)};
    NSData *data = [NSJSONSerialization dataWithJSONObject:@[announcement] options:0 error:nil];
    ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    [NIMKitProgressHUD show];
    if ([_delegate respondsToSelector:@selector(didUpdateAnnouncement:completion:)]) {
        __weak typeof(self) wself = self;
        [_delegate didUpdateAnnouncement:ret completion:^(NSError *error) {
            [NIMKitProgressHUD dismiss];
            if(!error) {
                [wself.view makeToast:@"创建成功".nim_localized];
                [wself updateAnnouncementsWithContent:ret];
                [wself.tableView reloadData];
            } else {
                [wself.view makeToast:@"创建失败".nim_localized];
            }
        }];
    }
}

#pragma mark - Getter
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [_tableView registerClass:[NIMTeamAnnouncementListCell class] forCellReuseIdentifier:@"NIMTeamAnnouncementListCell"];
        _tableView.rowHeight = 267;
        [_tableView setTableFooterView:[UIView new]];
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

@end

@implementation NIMTeamAnnouncementListOption
@end
