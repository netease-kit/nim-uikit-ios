//
//  UIScrollView+NTESDirection.h
//  NIM
//
//  Created by chris on 16/1/24.
//  Copyright © 2016年 Netease. All rights reserved.
//


#import <UIKit/UIKit.h>


typedef enum NTESScrollViewDirection {
    NTESScrollViewDirectionNone,
    NTESScrollViewDirectionRight,
    NTESScrollViewDirectionLeft,
    NTESScrollViewDirectionUp,
    NTESScrollViewDirectionDown,
} NTESScrollViewDirection;


@interface UIScrollView (Direction)

- (void)startObservingDirection;
- (void)stopObservingDirection;

@property (readonly, nonatomic) NTESScrollViewDirection horizontalScrollingDirection;
@property (readonly, nonatomic) NTESScrollViewDirection verticalScrollingDirection;

@end
