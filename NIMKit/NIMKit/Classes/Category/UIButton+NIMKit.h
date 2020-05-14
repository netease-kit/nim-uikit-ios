//
//  UIButton+NIMKit.h
//  NIMKit
//
//  Created by 丁文超 on 2020/4/16.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIButton (NIMKit)

/**
*  垂直居中按钮 image 和 title
*
*  @param spacing - image 和 title 的垂直间距, 单位point
*/
- (void)nim_verticalCenterImageAndTitleWithSpacing:(CGFloat)spacing;

@end

NS_ASSUME_NONNULL_END
