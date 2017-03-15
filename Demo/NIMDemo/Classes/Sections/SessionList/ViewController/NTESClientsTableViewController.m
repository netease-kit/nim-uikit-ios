//
//  NTESClientsTableViewController.m
//  NIM
//
//  Created by amao on 6/1/15.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import "NTESClientsTableViewController.h"
#import "NTESSessionUtil.h"
#import "UIView+NTES.h"
#import "NTESMutiClientsCell.h"
#import "UIView+Toast.h"

NSString *Identifier = @"client_cell";

@interface NTESClientsTableViewController ()<NIMLoginManagerDelegate>
@property (nonatomic,strong)    NSArray *clients;
@end

@implementation NTESClientsTableViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NIMSDK sharedSDK].loginManager addDelegate:self];
    }
    return self;
}

- (void)dealloc{
    [[NIMSDK sharedSDK].loginManager removeDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"多端登录管理";
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = UIColorFromRGB(0xecf1f5);
    [self.tableView registerNib:[UINib nibWithNibName:@"NTESMutiClientsCell" bundle:nil] forCellReuseIdentifier:Identifier];
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    self.clients = [[[NIMSDK sharedSDK] loginManager] currentLoginClients];
}

- (void)viewDidLayoutSubviews{
    NTESClientsTableHeader *header = [[NTESClientsTableHeader alloc] initWithFrame:CGRectZero];
    CGSize size = [header sizeThatFits:self.view.size];
    header.size = size;
    self.tableView.tableHeaderView = header;
}

- (void)reload
{
    self.clients = [[[NIMSDK sharedSDK] loginManager] currentLoginClients];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_clients count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NTESMutiClientsCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    NIMLoginClient *client = [_clients objectAtIndex:[indexPath row]];
    [cell refreshWidthCilent:client];
    return cell;
}



- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}



- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {

        __weak typeof(self) weakSelf = self;
        NIMLoginClient *client = [_clients objectAtIndex:[indexPath row]];
        [[[NIMSDK sharedSDK] loginManager] kickOtherClient:client
                                                completion:^(NSError *error) {
                                                    [weakSelf reload];
                                                }];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NIMLoginClient *client = [_clients objectAtIndex:[indexPath row]];
    __weak typeof(self) wself = self;
    [[NIMSDK sharedSDK].loginManager kickOtherClient:client completion:^(NSError *error) {
        if (error) {
            [wself.view makeToast:@"踢出失败"
                         duration:2
                         position:CSToastPositionCenter];
        }
        [wself reload];
    }];
}


#pragma mark - NIMLoginManagerDelegate
- (void)onMultiLoginClientsChanged{
    self.clients = [[[NIMSDK sharedSDK] loginManager] currentLoginClients];
    if (self.clients.count) {
        [self reload];
    }else{
        [self.navigationController.view makeToast:@"已没有其他设备连接"
                                         duration:2
                                         position:CSToastPositionCenter];
        [self.navigationController popViewControllerAnimated:YES];

    }
}

#pragma mark - 旋转处理 (iOS7)

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    UIView *header = self.tableView.tableHeaderView;
    CGSize size = [header sizeThatFits:self.view.size];
    header.size = size;
    self.tableView.tableHeaderView = header;
}

#pragma mark - 旋转处理 (iOS8 or above)
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    UIView *header = self.tableView.tableHeaderView;
    CGSize headerSize = [header sizeThatFits:size];
    header.size = headerSize;
    self.tableView.tableHeaderView = header;
}


@end



@implementation NTESClientsTableHeader

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        _icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_clients"]];
        [self addSubview:_icon];
    }
    return self;
}

CGFloat TableHeaderBottom = 75.f;
CGFloat NavBarHeight      = 44.f;
- (CGSize)sizeThatFits:(CGSize)size{
    CGFloat height = size.height - NavBarHeight - [UIApplication sharedApplication].statusBarFrame.size.height - TableHeaderBottom;
    return CGSizeMake(size.width, height);
}


CGFloat IconTop = 73.f;
- (void)layoutSubviews{
    [super layoutSubviews];
    self.icon.top     = IconTop;
    self.icon.centerX = self.width * .5f;
}


@end
