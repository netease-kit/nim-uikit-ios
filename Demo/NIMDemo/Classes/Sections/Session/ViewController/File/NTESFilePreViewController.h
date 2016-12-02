//
//  NTESFilePreViewController.h
//  NIM
//
//  Created by chris on 15/4/21.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMFileObject.h"
@interface NTESFilePreViewController : UIViewController

@property(nonatomic,strong) IBOutlet UIButton *actionBtn;

@property(nonatomic,strong) IBOutlet UIProgressView *progressView;

@property(nonatomic,strong) IBOutlet UILabel *fileNameLabel;

- (instancetype)initWithFileObject:(NIMFileObject*)object;

@end
