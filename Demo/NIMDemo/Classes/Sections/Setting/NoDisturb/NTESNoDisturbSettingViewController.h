//
//  NTESNoDisturbSettingViewController.h
//  NIM
//
//  Created by chris on 15/7/7.
//  Copyright © 2015年 Netease. All rights reserved.
//
typedef void(^NTESNoDisturbCompleteHandler)(void);
#import <UIKit/UIKit.h>

@interface NTESNoDisturbSettingViewController : UIViewController

@property (nonatomic,strong) IBOutlet UITableView *tableView;

@property (nonatomic,copy)NTESNoDisturbCompleteHandler handler;

@end
