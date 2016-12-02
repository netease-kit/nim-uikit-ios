//
//  NTESChatroomSegmentedControl.m
//  NIM
//
//  Created by chris on 15/12/16.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NTESChatroomSegmentedControl.h"
#import "UIView+NTES.h"

@interface NTESChatroomSegmentedControl()

@property (nonatomic,strong) NSMutableArray<UIButton *> *segments;

@property (nonatomic,strong) NSMutableArray<NSInvocation *> *invocations;

@property (nonatomic,assign) NSInteger selectedIndex;

@end

@implementation NTESChatroomSegmentedControl

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        _segments = [[NSMutableArray alloc] init];
        _invocations = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)insertSegmentWithTitle:(NSString *)title{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self action:@selector(onSegmentTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    button.tag = self.segments.count;
    [button setTitle:title forState:UIControlStateNormal];
    [self addSubview:button];
    [self.segments addObject:button];
    [self refresh];
}

- (void)setSelectedSegmentIndex:(NSInteger)index
{
    self.selectedIndex = index;
    [self refresh];
}

- (NSInteger)selectedSegmentIndex
{
    return self.selectedIndex;
}

- (void)setBackgroundImage:(UIImage *)image forState:(UIControlState)state atIndex:(NSInteger)index
{
    UIButton *button = self.segments[index];
    [button setBackgroundImage:image forState:state];
}


- (void)setTitleColor:(UIColor *)color forState:(UIControlState)state atIndex:(NSInteger)index
{
    UIButton *button = self.segments[index];
    [button setTitleColor:color forState:state];
}

- (void)setFont:(UIFont *)font atIndex:(NSInteger)index
{
    UIButton *button = self.segments[index];
    button.titleLabel.font = font;
}


- (void)onSegmentTouchUpInside:(id)sender
{
    NSInteger index = [(UIButton *)sender tag];
    if (index != self.selectedIndex) { //value changed
        self.selectedIndex = index;
        [self refresh];
        [self invokeValueChangedAction];
    }
}

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents
{
    if (controlEvents == UIControlEventValueChanged) {
        UIView *view = self;
        NSMethodSignature *sig = [[target class] instanceMethodSignatureForSelector:action];
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
        [inv setTarget:target];
        [inv setSelector:action];
        [inv setArgument:&view atIndex:2];
        [_invocations addObject:inv];
    }
}


- (void)refresh
{
    for (UIButton *button in self.segments) {
        button.selected = NO;
    }
    self.segments[self.selectedIndex].selected = YES;
}

- (void)invokeValueChangedAction
{
    for (NSInvocation *inv in _invocations) {
        [inv invoke];
    }
}

- (void)layoutSubviews{
    [super layoutSubviews];
    CGFloat left   = 0.0f;
    CGFloat width  = self.width / self.segments.count;
    CGFloat height = self.height;
    for (UIButton *button in self.segments) {
        button.size  = CGSizeMake(width, height);
        button.left  = left;
        left += button.width;
    }
}

@end
