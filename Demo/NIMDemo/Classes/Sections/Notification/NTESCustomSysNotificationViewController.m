//
//  NTESCustomSysNotificationViewController.m
//  NIM
//
//  Created by chris on 15/5/26.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESCustomSysNotificationViewController.h"
#import "NIMContactSelectViewController.h"
#import "NTESCustomSysNotificationSender.h"
#import "UIAlertView+NTESBlock.h"
#import "NTESCustomNotificationDB.h"
#import "NSDictionary+NTESJson.h"
#import "NTESCustomNotificationObject.h"
#import "UIActionSheet+NTESBlock.h"
#import "NTESNotificationCenter.h"
#import "NTESCustomSysNotificationSender.h"

#define FetchLimit 10
static NSString *reuseIdentifier = @"reuseIdentifier";

@interface NTESCustomSysNotificationViewController ()<NIMContactSelectDelegate>

@property (nonatomic,strong) NSMutableArray *data;

@property (nonatomic,assign) NIMSessionType sendSessionType;

@property (nonatomic,strong) NTESCustomSysNotificationSender *sender;

@end

@implementation NTESCustomSysNotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNav];
    NTESCustomNotificationDB *db = [NTESCustomNotificationDB sharedInstance];
    self.data = [[db fetchNotifications:nil limit:FetchLimit] mutableCopy];
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [db markAllNotificationsAsRead];
    extern NSString *NTESCustomNotificationCountChanged;
    [[NSNotificationCenter defaultCenter] postNotificationName:NTESCustomNotificationCountChanged object:nil];
    
    _sender = [[NTESCustomSysNotificationSender alloc] init];
}

- (void)setupNav{
    self.navigationItem.title = @"自定义系统通知";
    UIBarButtonItem *clearBarBtnItem = [[UIBarButtonItem alloc] initWithTitle:@"清空"
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(clearAll:)];
    
    UIBarButtonItem *addCustomNotiBarBtnItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addCustomNotification:)];
    
    self.navigationItem.rightBarButtonItems = @[clearBarBtnItem,addCustomNotiBarBtnItem];
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 55.f;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSInteger index = [indexPath row];
        NTESCustomNotificationObject *notification = [self.data objectAtIndex:index];
        [self.data removeObjectAtIndex:index];
        NTESCustomNotificationDB *db = [NTESCustomNotificationDB sharedInstance];
        [db deleteNotification:notification];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }
    NTESCustomNotificationObject *notification = [self.data objectAtIndex:[indexPath row]];
    NSString *content = notification.content;
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    if (data)
    {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
                                                             options:0
                                                               error:nil];
        if ([dict isKindOfClass:[NSDictionary class]])
        {
            NSString *text      = [dict jsonString:NTESCustomContent];
            cell.textLabel.text = text;
        }
    }
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.data.count;
}

#pragma mark - Action
- (void)addCustomNotification:(id)sender{
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"选择操作" delegate:nil cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"单聊",@"群组", nil];
    __block NIMContactSelectViewController *vc;
    [sheet showInView:self.view completionHandler:^(NSInteger index) {
        switch (index) {
            case 0:{
                NIMContactFriendSelectConfig *config = [[NIMContactFriendSelectConfig alloc] init];
                vc = [[NIMContactSelectViewController alloc] initWithConfig:config];
                self.sendSessionType = NIMSessionTypeP2P;
                vc.delegate = self;
                break;
            }
            case 1:{
                NIMContactTeamSelectConfig *config = [[NIMContactTeamSelectConfig alloc] init];
                vc = [[NIMContactSelectViewController alloc] initWithConfig:config];
                self.sendSessionType = NIMSessionTypeTeam;
                vc.delegate = self;
                break;
            }
            default:
                return;
        }
        [vc show];
    }];
}

- (void)clearAll:(id)sender{
    NTESCustomNotificationDB *db = [NTESCustomNotificationDB sharedInstance];
    [db deleteAllNotification];
    [self.data removeAllObjects];
    [self.tableView reloadData];
}

#pragma mark - NIMContactSelectDelegate
- (void)didFinishedSelect:(NSArray *)selectedContacts{
    NSString *selectId = selectedContacts.firstObject;
    if (!selectId.length) {
        return;
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"自定义发送内容" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert showAlertWithCompletionHandler:^(NSInteger index) {
        switch (index) {
            case 0://取消
                break;
            case 1:{
                
                NSString *content = [[alert textFieldAtIndex:0].text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                content = [content length] ? content : @"";
                NIMSession *session = [NIMSession session:selectId type:self.sendSessionType];
            
                [_sender sendCustomContent:content
                                 toSession:session];
            }
                break;
            default:
                break;
        }
    }];
}

@end
