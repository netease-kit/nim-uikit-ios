//
//  UIButton+NIMKit.m
//  NIMKit
//
//  Created by 丁文超 on 2020/4/16.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import "UIButton+NIMKit.h"
#import "UIView+NIM.h"

@implementation UIButton (NIMKit)

- (void)nim_verticalCenterImageAndTitleWithSpacing:(CGFloat)spacing
{
    CGSize imageSize = self.imageView.intrinsicContentSize;
    CGSize titleSize = self.titleLabel.intrinsicContentSize;
    CGFloat totalHeight = (imageSize.height + titleSize.height + spacing);
    self.imageEdgeInsets = UIEdgeInsetsMake(-(totalHeight - imageSize.height), 0.0, 0.0, -titleSize.width);
    self.titleEdgeInsets = UIEdgeInsetsMake(0.0, -imageSize.width, -(totalHeight - titleSize.height), 0.0);
}

@end
