//
//  UIResponder+NTESFirstResponder.m
//  NIM
//
//  Created by chris on 15/9/26.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "UIResponder+NTESFirstResponder.h"
static __weak id currentFirstResponder;
static __weak id currentSecodResponder;

@implementation UIResponder (NTESFirstResponder)

+ (instancetype)currentFirstResponder {
    currentFirstResponder = nil;
    currentSecodResponder = nil;
    [[UIApplication sharedApplication] sendAction:@selector(findFirstResponder:) to:nil from:nil forEvent:nil];
    return currentFirstResponder;
}

+ (instancetype)currentSecondResponder{
    currentFirstResponder = nil;
    currentSecodResponder = nil;
    [[UIApplication sharedApplication] sendAction:@selector(findFirstResponder:) to:nil from:nil forEvent:nil];
    return currentSecodResponder;
}

- (void)findFirstResponder:(id)sender {
    currentFirstResponder = self;
    [self.nextResponder findSecondResponder:sender];
}


- (void)findSecondResponder:(id)sender{
    currentSecodResponder = self;
}

@end
