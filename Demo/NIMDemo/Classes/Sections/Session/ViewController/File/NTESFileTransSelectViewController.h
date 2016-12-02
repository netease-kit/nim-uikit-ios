//
//  FileTransSelectViewController.h
//  NIM
//
//  Created by chris on 15/4/20.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^NTESFileTransCompletionBlock)(id sender,NSString* ext);

@interface NTESFileTransSelectViewController : UIViewController

@property(nonatomic,strong) IBOutlet UITableView *tableView;

@property(nonatomic,copy)NTESFileTransCompletionBlock completionBlock;

@end
