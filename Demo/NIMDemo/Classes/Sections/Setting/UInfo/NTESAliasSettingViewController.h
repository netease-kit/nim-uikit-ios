//
//  NTESAliasSettingViewController.h
//  NIM
//
//  Created by chris on 15/11/5.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTESAliasSettingViewController : UIViewController

@property (nonatomic, strong) UITableView *tableView;

- (instancetype)initWithUserId:(NSString *)userId;

@end
