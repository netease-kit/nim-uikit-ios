//
//  NTESSessionListViewController.m
//  DemoApplication
//
//  Created by chris on 2017/10/16.
//  Copyright © 2017年 chrisRay. All rights reserved.
//

#import "NTESSessionListViewController.h"
#import "NTESSessionViewController.h"
#import "NTESContactViewController.h"

@interface NTESSessionListViewController ()

@end

@implementation NTESSessionListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"会话";
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addSession)];
    self.navigationItem.rightBarButtonItem = item;
}


- (void)onSelectedRecent:(NIMRecentSession *)recent
             atIndexPath:(NSIndexPath *)indexPath
{
    NTESSessionViewController *vc = [[NTESSessionViewController alloc] initWithSession:recent.session];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)addSession
{
    NTESContactViewController *vc = [[NTESContactViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
