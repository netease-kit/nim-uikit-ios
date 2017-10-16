//
//  NTESContactViewController.m
//  DemoApplication
//
//  Created by chris on 2017/10/16.
//  Copyright © 2017年 chrisRay. All rights reserved.
//

#import "NTESContactViewController.h"
#import "NTESSessionViewController.h"

@interface NTESContactViewController ()

@property (nonatomic,copy) NSArray *contact;

@end

@implementation NTESContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self makeData];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
}

- (void)makeData
{
    //以下账号均为测试账号，均可以登录，密码都为 123456
    _contact =  @[
                      @"hanmeimei",
                      @"lintao",
                      @"tom",
                      @"lily",
                      @"lucy",
                      @"lilei",
                 ];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.contact.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    NSString *title = [self.contact objectAtIndex:indexPath.row];
    cell.textLabel.text = title;
    return cell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSString *sessionId = [self.contact objectAtIndex:indexPath.row];
    NIMSession *session = [NIMSession session:sessionId type:NIMSessionTypeP2P];
    NTESSessionViewController *vc = [[NTESSessionViewController alloc] initWithSession:session];
    [self.navigationController pushViewController:vc animated:YES];
}


@end
