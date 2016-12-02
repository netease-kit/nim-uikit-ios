//
//  UIActionSheet+NTESBlock.h
//  eim_iphone
//
//  Created by amao on 12-11-23.
//  Copyright (c) 2012年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^ActionSheetBlock)(NSInteger);

@interface UIActionSheet (NTESBlock)<UIActionSheetDelegate>
- (void)showInView: (UIView *)view completionHandler: (ActionSheetBlock)block;
- (void)clearActionBlock;
@end
