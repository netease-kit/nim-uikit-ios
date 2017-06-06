//
//  NTESTeamMeetingMutesViewController.m
//  NIM
//
//  Created by chris on 2017/5/8.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import "NTESTeamMeetingMutesViewController.h"
#import "NTESTeamMeetingMuteCell.h"

@interface NTESTeamMeetingMutesViewController ()

@property (nonatomic,strong) NSArray *members;

@property (nonatomic,strong) NSMutableDictionary *muteMembers;

@end

@implementation NTESTeamMeetingMutesViewController


- (instancetype)initWithMeetingMembers:(NSArray *)members
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        _members = [NSArray arrayWithArray:members];
        _muteMembers = [[NSMutableDictionary alloc] init];
        for (NTESTeamMeetingMuteUser *user in _members) {
            [_muteMembers setObject:[user copy] forKey:user.userId];
        }
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[NTESTeamMeetingMuteCell class] forCellReuseIdentifier:@"cell"];
    self.tableView.tableFooterView = [UIView new];
    [self setUpNav];
}

- (void)setUpNav
{
    self.navigationItem.title = @"屏蔽音频";
    self.navigationItem.leftBarButtonItem  = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(done:)];
}

- (void)cancel:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)done:(id)sender
{
    NSMutableArray *muteStateChangeUsers = [[NSMutableArray alloc] init];
    for (NTESTeamMeetingMuteUser *user in self.members) {
        NTESTeamMeetingMuteUser *data = [self.muteMembers objectForKey:user.userId];
        if (user.mute != data.mute) {
            [muteStateChangeUsers addObject:data];
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(onTeamMembersMuteStateChange:)]) {
        [self.delegate onTeamMembersMuteStateChange:muteStateChangeUsers];
    }
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.members.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NTESTeamMeetingMuteCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.team = self.team;
    NTESTeamMeetingMuteUser *user = [self findUser:indexPath];
    [cell refresh:user.userId muted:user.mute];
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NTESTeamMeetingMuteUser *user = [self findUser:indexPath];
    user.mute = !user.mute;
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}


- (NTESTeamMeetingMuteUser *)findUser:(NSIndexPath *)indexPath
{
    NTESTeamMeetingMuteUser *user = self.members[indexPath.row];
    return [self.muteMembers objectForKey:user.userId];
}


@end


@implementation NTESTeamMeetingMuteUser

- (instancetype)copyWithZone:(NSZone *)zone
{
    NTESTeamMeetingMuteUser *user = [[[self class] allocWithZone:zone] init];
    user.userId = self.userId;
    user.mute = self.mute;
    return user;
}

@end
