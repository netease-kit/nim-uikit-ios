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
    //填入内容大小
    return CGSizeMake(200, 50);
}

- (NSString *)cellContent:(NIMMessageModel *)model{
    //填入自定义的气泡contentView
    return @"ContentView";
}

- (UIEdgeInsets)cellInsets:(NIMMessageModel *)model{
    //填入气泡距cell的边距,选填
    return UIEdgeInsetsMake(5, 5, 5, 5);
}


- (UIEdgeInsets)contentViewInsets:(NIMMessageModel *)model{
    //填入内容距气泡的边距,选填
    return UIEdgeInsetsMake(5, 5, 5, 5);
}


@end
