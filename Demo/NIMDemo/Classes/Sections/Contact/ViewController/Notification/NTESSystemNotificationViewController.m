//
//  SystemNotificationViewController.m
//  NIM
//
//  Created by amao on 3/17/15.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import "NTESSystemNotificationViewController.h"
#import "NTESSystemNotificationCell.h"
#import "UIView+Toast.h"

static const NSInteger MaxNotificationCount = 20;
static NSString *reuseIdentifier = @"reuseIdentifier";

@interface NTESSystemNotificationViewController ()<NIMSystemNotificationManagerDelegate,NIMSystemNotificationCellDelegate,NIMTeamManagerDelegate>
@property (nonatomic,strong)    NSMutableArray  *notifications;
@property (nonatomic,assign)    BOOL shouldMarkAsRead;
@end

@implementation NTESSystemNotificationViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.edgesForExtendedLayout = UIRectEdgeAll;
    }
    return self;
}

- (void)dealloc
{
    if (_shouldMarkAsRead)
    {
        [[[NIMSDK sharedSDK] systemNotificationManager] markAllNotificationsAsRead];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"验证消息";
    [self.tableView registerNib:[UINib nibWithNibName:@"NTESSystemNotificationCell" bundle:nil]
           forCellReuseIdentifier:reuseIdentifier];
    
    _notifications = [NSMutableArray array];
    
    id<NIMSystemNotificationManager> systemNotificationManager = [[NIMSDK sharedSDK] systemNotificationManager];
    [systemNotificationManager addDelegate:self];
    
    NSArray *notifications = [systemNotificationManager fetchSystemNotifications:nil
                                                         limit:MaxNotificationCount];
    
    if ([notifications count])
    {
        [_notifications addObjectsFromArray:notifications];
        if (![[notifications firstObject] read])
        {
            _shouldMarkAsRead = YES;
            
        }
    }
    if (notifications.count >= MaxNotificationCount) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        [button setFrame:CGRectMake(0, 0, 320, 40)];
        [button addTarget:self
                   action:@selector(loadMore:)
         forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:@"载入更多" forState:UIControlStateNormal];
        self.tableView.tableFooterView = button;
    }else{
        self.tableView.tableFooterView = [[UIView alloc] init];
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"清空"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(clearAll:)];
}




- (void)loadMore:(id)sender
{
    NSArray *notifications = [[[NIMSDK sharedSDK] systemNotificationManager] fetchSystemNotifications:[_notifications lastObject]
                                                                                                limit:MaxNotificationCount];
    if ([notifications count])
    {
        [_notifications addObjectsFromArray:notifications];
        [self.tableView reloadData];
    }
}

- (void)clearAll:(id)sender
{
    [[[NIMSDK sharedSDK] systemNotificationManager] deleteAllNotifications];
    [_notifications removeAllObjects];
    [self.tableView reloadData];
    
}

- (void)onReceiveSystemNotification:(NIMSystemNotification *)notification
{
    [_notifications insertObject:notification atIndex:0];
    _shouldMarkAsRead = YES;
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_notifications count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NTESSystemNotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    NIMSystemNotification *notification = [_notifications objectAtIndex:[indexPath row]];
    [cell update:notification];
    cell.actionDelegate = self;
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSInteger index = [indexPath row];
        NIMSystemNotification *notification = [_notifications objectAtIndex:index];
        [_notifications removeObjectAtIndex:index];
        [[[NIMSDK sharedSDK] systemNotificationManager] deleteNotification:notification];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}


#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - SystemNotificationCell
- (void)onAccept:(NIMSystemNotification *)notification
{
    __weak typeof(self) wself = self;
    switch (notification.type) {
        case NIMSystemNotificationTypeTeamApply:{
            [[NIMSDK sharedSDK].teamManager passApplyToTeam:notification.targetID userId:notification.sourceID completion:^(NSError *error, NIMTeamApplyStatus applyStatus) {
                if (!error) {
                    [wself.navigationController.view makeToast:@"同意成功"
                                                      duration:2
                                                      position:CSToastPositionCenter];
                    notification.handleStatus = NotificationHandleTypeOk;
                    [wself.tableView reloadData];
                }else {
                    if(error.code == NIMRemoteErrorCodeTimeoutError) {
                        [wself.navigationController.view makeToast:@"网络问题，请重试"
                                                          duration:2
                                                          position:CSToastPositionCenter];
                    } else {
                        notification.handleStatus = NotificationHandleTypeOutOfDate;
                    }
                    [wself.tableView reloadData];
                    DDLogDebug(@"%@",error.localizedDescription);
                }
            }];
            break;
        }
        case NIMSystemNotificationTypeTeamInvite:{
            [[NIMSDK sharedSDK].teamManager acceptInviteWithTeam:notification.targetID invitorId:notification.sourceID completion:^(NSError *error) {
                if (!error) {
                    [wself.navigationController.view makeToast:@"接受成功"
                                                      duration:2
                                                      position:CSToastPositionCenter];
                    notification.handleStatus = NotificationHandleTypeOk;
                    [wself.tableView reloadData];
                }else {
                    if(error.code == NIMRemoteErrorCodeTimeoutError) {
                        [wself.navigationController.view makeToast:@"网络问题，请重试"
                                                          duration:2
                                                          position:CSToastPositionCenter];
                    }
                    else if (error.code == NIMRemoteErrorCodeTeamNotExists) {
                        [wself.navigationController.view makeToast:@"群不存在"
                                                          duration:2
                                                          position:CSToastPositionCenter];
                    }
                    else {
                        notification.handleStatus = NotificationHandleTypeOutOfDate;
                    }
                    [wself.tableView reloadData];
                    DDLogDebug(@"%@",error.localizedDescription);
                }
            }];
        }
            break;
        case NIMSystemNotificationTypeFriendAdd:
        {
            NIMUserRequest *request = [[NIMUserRequest alloc] init];
            request.userId = notification.sourceID;
            request.operation = NIMUserOperationVerify;
            
            [[[NIMSDK sharedSDK] userManager] requestFriend:request
                                                 completion:^(NSError *error) {
                                                     if (!error) {
                                                         [wself.navigationController.view makeToast:@"验证成功"
                                                                                           duration:2
                                                                                           position:CSToastPositionCenter];
                                                         notification.handleStatus = NotificationHandleTypeOk;
                                                     }
                                                     else
                                                     {
                                                         [wself.navigationController.view makeToast:@"验证失败,请重试"
                                                                                           duration:2
                                                                                           position:CSToastPositionCenter];
                                                     }
                                                     [wself.tableView reloadData];
                                                     DDLogDebug(@"%@",error.localizedDescription);
                                                 }];
        }
            break;
        default:
            break;
    }
}

- (void)onRefuse:(NIMSystemNotification *)notification
{
    __weak typeof(self) wself = self;
    switch (notification.type) {
        case NIMSystemNotificationTypeTeamApply:{
            [[NIMSDK sharedSDK].teamManager rejectApplyToTeam:notification.targetID userId:notification.sourceID rejectReason:@"" completion:^(NSError *error) {
                if (!error) {
                    [wself.navigationController.view makeToast:@"拒绝成功"
                                                      duration:2
                                                      position:CSToastPositionCenter];
                    notification.handleStatus = NotificationHandleTypeNo;
                    [wself.tableView reloadData];
                }else {
                    if(error.code == NIMRemoteErrorCodeTimeoutError) {
                        [wself.navigationController.view makeToast:@"网络问题，请重试"
                                                          duration:2
                                                          position:CSToastPositionCenter];
                    } else {
                        notification.handleStatus = NotificationHandleTypeOutOfDate;
                    }
                    [wself.tableView reloadData];
                    DDLogDebug(@"%@",error.localizedDescription);
                }
            }];
        }
           break;

        case NIMSystemNotificationTypeTeamInvite:{
            [[NIMSDK sharedSDK].teamManager rejectInviteWithTeam:notification.targetID invitorId:notification.sourceID rejectReason:@"" completion:^(NSError *error) {
                if (!error) {
                    [wself.navigationController.view makeToast:@"拒绝成功"
                                                      duration:2
                                                      position:CSToastPositionCenter];
                    notification.handleStatus = NotificationHandleTypeNo;
                    [wself.tableView reloadData];
                }else {
                    if(error.code == NIMRemoteErrorCodeTimeoutError) {
                        [wself.navigationController.view makeToast:@"网络问题，请重试"
                                                          duration:2
                                                          position:CSToastPositionCenter];
                    }
                    else if (error.code == NIMRemoteErrorCodeTeamNotExists) {
                        [wself.navigationController.view makeToast:@"群不存在"
                                                          duration:2
                                                          position:CSToastPositionCenter];
                    }
                    else {
                        notification.handleStatus = NotificationHandleTypeOutOfDate;
                    }
                    [wself.tableView reloadData];
                    DDLogDebug(@"%@",error.localizedDescription);
                }
            }];

        }
            break;
        case NIMSystemNotificationTypeFriendAdd:
        {
            NIMUserRequest *request = [[NIMUserRequest alloc] init];
            request.userId = notification.sourceID;
            request.operation = NIMUserOperationReject;
            
            [[[NIMSDK sharedSDK] userManager] requestFriend:request
                                                 completion:^(NSError *error) {
                                                     if (!error) {
                                                         [wself.navigationController.view makeToast:@"拒绝成功"
                                                                                           duration:2
                                                                                           position:CSToastPositionCenter];
                                                         notification.handleStatus = NotificationHandleTypeNo;
                                                     }
                                                     else
                                                     {
                                                         [wself.navigationController.view makeToast:@"拒绝失败,请重试"
                                                                                           duration:2
                                                                                           position:CSToastPositionCenter];
                                                     }
                                                     [wself.tableView reloadData];
                                                     DDLogDebug(@"%@",error.localizedDescription);
                                                 }];
        }
            break;
        default:
            break;
    }
}


@end
