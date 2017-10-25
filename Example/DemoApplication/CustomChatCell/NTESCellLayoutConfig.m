//
//  NTESCellLayoutConfig.m
//  DemoApplication
//
//  Created by chris on 15/11/1.
//  Copyright © 2015年 chris. All rights reserved.
//

#import "NTESCellLayoutConfig.h"

@implementation NTESCellLayoutConfig

- (CGSize)contentSize:(NIMMessageModel *)model cellWidth:(CGFloat)width{
    if ([self canLayout:model]) {
        return CGSizeMake(200, 50);
    }
    return [super contentSize:model cellWidth:width];
}

- (NSString *)cellContent:(NIMMessageModel *)model{
    if ([self canLayout:model]) {
        //填入自定义的气泡contentView
        return @"NTESContentView";
    }
    return [super cellContent:model];
}

- (UIEdgeInsets)cellInsets:(NIMMessageModel *)model{
    if ([self canLayout:model]) {
        //填入气泡距cell的边距,选填
        return UIEdgeInsetsMake(5, 5, 5, 5);
    }
    return [super cellInsets:model];
    
}


- (UIEdgeInsets)contentViewInsets:(NIMMessageModel *)model{
    if ([self canLayout:model]) {
        //填入内容距气泡的边距,选填
        return UIEdgeInsetsMake(5, 5, 5, 5);
    }
    return [super contentViewInsets:model];
    
}


- (BOOL)canLayout:(NIMMessageModel *)model
{
    return model.message.messageType == NIMMessageTypeCustom;
}


@end
