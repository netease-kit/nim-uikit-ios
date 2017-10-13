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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSInteger row = [self numberOfRowsInSection:0] - 1;
        if (row > 0)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
            [self scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:animation];
        }
    });
}


@end
