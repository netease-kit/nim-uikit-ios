//
//  NTESLogViewController.h
//  NIM
//
//  Created by Xuhui on 15/4/1.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTESLogViewController : UIViewController
- (instancetype)initWithFilepath:(NSString *)path;
- (instancetype)initWithContent:(NSString *)content;
@end
