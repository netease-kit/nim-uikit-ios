//
//  UIAlertView+NTESBlock.h
//  eim_iphone
//
//  Created by amao on 12-11-7.
//  Copyright (c) 2012年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^AlertBlock)(NSInteger);

@interface UIAlertView (NTESBlock)
- (void)showAlertWithCompletionHandler: (AlertBlock)block;
- (void)clearActionBlock;
@end
