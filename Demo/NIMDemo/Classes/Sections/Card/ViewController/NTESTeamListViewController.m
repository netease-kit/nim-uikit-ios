//
//  NTESTeamListViewController.m
//  NIM
//
//  Created by Xuhui on 15/3/3.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESTeamListViewController.h"
#import "NTESSessionViewController.h"

@interface NTESTeamListViewController () <UITableViewDelegate, UITableViewDataSource,NIMTeamManagerDelegate> {
}
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *myTeams;

@end

@implementation NTESTeamListViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)dealloc{
    [[NIMSDK sharedSDK].teamManager removeDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.myTeams = [self fetchTeams];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc]init];
    [[NIMSDK sharedSDK].teamManager addDelegate:self];
}

- (NSMutableArray *)fetchTeams{
    //subclass override
    return nil;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _myTeams.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TeamListCell"];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TeamListCell"];
    }
    NIMTeam *team = [_myTeams objectAtIndex:indexPath.row];
    cell.textLabel.text = team.teamName;
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 55.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NIMTeam *team = [_myTeams objectAtIndex:indexPath.row];
    NIMSession *session = [NIMSession session:team.teamId type:NIMSessionTypeTeam];
    NTESSessionViewController *vc = [[NTESSessionViewController alloc] initWithSession:session];
    [self.navigationController pushViewController:vc animated:YES];
}

@end



@implementation NTESAdvancedTeamListViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:@"NTESTeamListViewController" bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    self.navigationItem.title = @"高级群组";
}

- (NSMutableArray *)fetchTeams{
    NSMutableArray *myTeams = [[NSMutableArray alloc]init];
    for (NIMTeam *team in [NIMSDK sharedSDK].teamManager.allMyTeams) {
        if (team.type == NIMTeamTypeAdvanced) {
            [myTeams addObject:team];
        }
    }
    return myTeams;
}

- (void)onTeamAdded:(NIMTeam *)team{
    if (team.type == NIMTeamTypeAdvanced) {
        self.myTeams = [self fetchTeams];
    }
    [self.tableView reloadData];
}

- (void)onTeamUpdated:(NIMTeam *)team{
    if (team.type == NIMTeamTypeAdvanced) {
        self.myTeams = [self fetchTeams];
    }
    [self.tableView reloadData];
}


- (void)onTeamRemoved:(NIMTeam *)team{
    if (team.type == NIMTeamTypeAdvanced) {
        self.myTeams = [self fetchTeams];
    }
    [self.tableView reloadData];
}


@end


@implementation NTESNormalTeamListViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:@"NTESTeamListViewController" bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    self.navigationItem.title = @"讨论组";
}

- (NSMutableArray *)fetchTeams{
    NSMutableArray *myTeams = [[NSMutableArray alloc]init];
    for (NIMTeam *team in [NIMSDK sharedSDK].teamManager.allMyTeams) {
        if (team.type == NIMTeamTypeNormal) {
            [myTeams addObject:team];
        }
    }
    return myTeams;
}

- (void)onTeamUpdated:(NIMTeam *)team{
    if (team.type == NIMTeamTypeNormal) {
        self.myTeams = [self fetchTeams];
    }
    [self.tableView reloadData];
}


- (void)onTeamRemoved:(NIMTeam *)team{
    if (team.type == NIMTeamTypeNormal) {
        self.myTeams = [self fetchTeams];
    }
    [self.tableView reloadData];
}

- (void)onTeamAdded:(NIMTeam *)team{
    if (team.type == NIMTeamTypeNormal) {
        self.myTeams = [self fetchTeams];
    }
    [self.tableView reloadData];
}
@end

