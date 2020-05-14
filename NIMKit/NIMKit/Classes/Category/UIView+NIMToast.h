//
//  UIView+NIMToast.h
//  NIMKit
//
//  Created by 丁文超 on 2020/3/19.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (NIMToast)

/**
 * 展示一个短暂的Toast
 *
 * @param message 要展示的内容
 * @param duration 显示的时长（秒）
 */
- (void)nim_showToast:(NSString *)message duration:(CGFloat)duration;

@end

NS_ASSUME_NONNULL_END
