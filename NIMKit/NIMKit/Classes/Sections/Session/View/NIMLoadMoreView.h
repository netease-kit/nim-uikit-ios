//
//  NIMLoadMoreView.h
//  NIMKit
//
//  Created by emily on 04/02/2018.
//  Copyright © 2018 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NIMLoadMoreView : UICollectionReusableView

@property (nonatomic, retain) UIActivityIndicatorView *activityView;


- (void)startAnimation;
- (void)stopAnimation;
- (BOOL)isAnimating;

@end
