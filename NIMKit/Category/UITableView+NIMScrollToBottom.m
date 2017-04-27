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
        [self setContentOffset:offset animated:animation];
    }
}


@end
