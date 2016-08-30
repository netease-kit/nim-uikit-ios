//
//  UITableView+NTESScrollToBottom.m
//  NIMDemo
//
//  Created by chris.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "UITableView+NIMScrollToBottom.h"

@implementation UITableView (NIMKit)

- (void)nim_scrollToBottom:(BOOL)animation
{
    if (self.contentSize.height + self.contentInset.top > self.frame.size.height)
    {
        CGPoint offset = CGPointMake(0, self.contentSize.height - self.frame.size.height);
        NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
        NSLog(@"content height %.3f",self.contentSize.height);
        NSLog(@"frame height %.3f",self.frame.size.height);
        NSLog(@"offset y : %.3f",offset.y);
        NSLog(@"offset animate begin %.3f",time);
        [self setContentOffset:offset animated:animation];
        NSLog(@"offset animate end %.3f",time);
        NSLog(@"=======================");
    }
}


@end
