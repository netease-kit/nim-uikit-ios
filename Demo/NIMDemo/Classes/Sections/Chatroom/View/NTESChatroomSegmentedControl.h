//
//  NTESChatroomSegmentedControl.h
//  NIM
//
//  Created by chris on 15/12/16.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTESChatroomSegmentedControl : UIView

@property(nonatomic) NSInteger selectedSegmentIndex;

- (void)insertSegmentWithTitle:(NSString *)title;

- (void)setBackgroundImage:(UIImage *)image forState:(UIControlState)state atIndex:(NSInteger)index;

- (void)setTitleColor:(UIColor *)color forState:(UIControlState)state atIndex:(NSInteger)index;

- (void)setFont:(UIFont *)font atIndex:(NSInteger)index;

//只有UIControlEventValueChanged有效
- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;

@end
