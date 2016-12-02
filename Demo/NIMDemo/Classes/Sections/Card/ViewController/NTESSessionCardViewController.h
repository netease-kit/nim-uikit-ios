//
//  NTESSessionCardViewController.h
//  NIM
//
//  Created by chris on 15/10/20.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTESSessionCardViewController : UIViewController

@property (nonatomic,strong) UITableView *tableView;

- (instancetype)initWithSession:(NIMSession *)session;

@end
