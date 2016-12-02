//
//  UIScrollView+NTESPullToRefresh.h
//
//  Created by chris on 15/2/12.
//  Copyright (c) 2015年 Netease. All rights reserved.
//
//

#import <UIKit/UIKit.h>

@class NTESPullToRefreshView;

@interface UIScrollView (NTESPullToRefresh)

typedef NS_ENUM(NSUInteger, NTESPullToRefreshPosition) {
    NTESPullToRefreshPositionTop = 0,
    NTESPullToRefreshPositionBottom,
};

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler;
- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler position:(NTESPullToRefreshPosition)position;
- (void)triggerPullToRefresh;

@property (nonatomic, strong, readonly) NTESPullToRefreshView *pullToRefreshView;
@property (nonatomic, assign) BOOL showsPullToRefresh;

@end


typedef NS_ENUM(NSUInteger, NTESPullToRefreshState) {
    NTESPullToRefreshStateStopped = 0,
    NTESPullToRefreshStateTriggered,
    NTESPullToRefreshStateLoading,
    NTESPullToRefreshStateAll = 10
};

@interface NTESPullToRefreshView : UIView

@property (nonatomic, strong) UIColor *arrowColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subtitleLabel;
@property (nonatomic, strong, readwrite) UIColor *activityIndicatorViewColor;
@property (nonatomic, readwrite) UIActivityIndicatorViewStyle activityIndicatorViewStyle;

@property (nonatomic, readonly) NTESPullToRefreshState state;
@property (nonatomic, readonly) NTESPullToRefreshPosition position;

- (void)setTitle:(NSString *)title forState:(NTESPullToRefreshState)state;
- (void)setSubtitle:(NSString *)subtitle forState:(NTESPullToRefreshState)state;
- (void)setCustomView:(UIView *)view forState:(NTESPullToRefreshState)state;

- (void)startAnimating;
- (void)stopAnimating;


@end

