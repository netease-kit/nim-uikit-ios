//
//  CellLayoutConfig.m
//  DemoApplication
//
//  Created by chris on 15/11/1.
//  Copyright © 2015年 chris. All rights reserved.
//

#import "CellLayoutConfig.h"

@implementation CellLayoutConfig

- (CGSize)contentSize:(NIMMessageModel *)model cellWidth:(CGFloat)width{
    return CGSizeMake(200, 50);
}

- (NSString *)cellContent:(NIMMessageModel *)model{
    //填入自定义的气泡contentView
    return @"ContentView";
}

- (UIEdgeInsets)cellInsets:(NIMMessageModel *)model{
    return UIEdgeInsetsMake(5, 5, 5, 5);
}


- (UIEdgeInsets)contentViewInsets:(NIMMessageModel *)model{
    return UIEdgeInsetsMake(5, 5, 5, 5);
}


@end
