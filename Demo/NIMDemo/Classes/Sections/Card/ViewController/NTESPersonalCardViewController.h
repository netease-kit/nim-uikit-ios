//
//  NTESPersonalCardViewController.h
//  NIM
//
//  Created by chris on 15/8/18.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ContactDataMember;

@interface NTESPersonalCardViewController : UIViewController

- (instancetype)initWithUserId:(NSString *)userId;

@property (nonatomic, strong) UITableView *tableView;

@end
