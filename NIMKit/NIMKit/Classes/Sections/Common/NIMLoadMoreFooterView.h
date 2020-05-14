//
//  NIMLoadMoreFooterView.h
//  NIMKit
//
//  Created by 丁文超 on 2020/3/19.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NIMLoadMoreFooterView : UIView

@property (nonatomic, strong) UIActivityIndicatorView *activityView;

- (void)startAnimation;
- (void)stopAnimation;
- (BOOL)isAnimating;

@end

NS_ASSUME_NONNULL_END
