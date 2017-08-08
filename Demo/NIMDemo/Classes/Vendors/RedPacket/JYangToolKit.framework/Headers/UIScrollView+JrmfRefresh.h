//
//  UIScrollView+JrmfRefresh.h
//  JrmfRefreshExample
//
//  Created by MJ Lee on 14-5-28.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

// 版权属于原作者
// http://code4app.com (cn) http://code4app.net (en)
// 发布代码于最专业的源码分享网站: Code4App.com

#import <UIKit/UIKit.h>

@interface UIScrollView (JrmfRefresh)
#pragma mark - 下拉刷新
/**
 *  添加一个下拉刷新头部控件
 *
 *  @param callback 回调
 */
- (void)addJrmfHeaderWithCallback:(void (^)())callback;

/**
 *  添加一个下拉刷新头部控件
 *
 *  @param target 目标
 *  @param action 回调方法
 */
- (void)addJrmfHeaderWithTarget:(id)target action:(SEL)action;

/**
 *  移除下拉刷新头部控件
 */
- (void)removeJrmfHeader;

/**
 *  主动让下拉刷新头部控件进入刷新状态
 */
- (void)JrmfheaderBeginRefreshing;

/**
 *  让下拉刷新头部控件停止刷新状态
 */
- (void)JrmfheaderEndRefreshing;

/**
 *  下拉刷新头部控件的可见性
 */
@property (nonatomic, assign, getter = isJrmfHeaderHidden) BOOL JrmfheaderHidden;

/**
 *  是否正在下拉刷新
 */
@property (nonatomic, assign, readonly, getter = isJrmfHeaderRefreshing) BOOL headerRefreshing;

#pragma mark - 上拉刷新
/**
 *  添加一个上拉刷新尾部控件
 *
 *  @param callback 回调
 */
- (void)addJrmfFooterWithCallback:(void (^)())callback;

/**
 *  添加一个上拉刷新尾部控件
 *
 *  @param target 目标
 *  @param action 回调方法
 */
- (void)addJrmfFooterWithTarget:(id)target action:(SEL)action;

/**
 *  移除上拉刷新尾部控件
 */
- (void)removeJrmfFooter;

/**
 *  主动让上拉刷新尾部控件进入刷新状态
 */
- (void)JrmffooterBeginRefreshing;

/**
 *  让上拉刷新尾部控件停止刷新状态
 */
- (void)JrmffooterEndRefreshing;

/**
 *  上拉刷新头部控件的可见性
 */
@property (nonatomic, assign, getter = isJrmfFooterHidden) BOOL JrmffooterHidden;

/**
 *  是否正在上拉刷新
 */
@property (nonatomic, assign, readonly, getter = isJrmfFooterRefreshing) BOOL footerRefreshing;

/**
 *  设置尾部控件的文字
 */
@property (copy, nonatomic) NSString *JrmffooterPullToRefreshText; // 默认:@"上拉可以加载更多数据"
@property (copy, nonatomic) NSString *JrmffooterReleaseToRefreshText; // 默认:@"松开立即加载更多数据"
@property (copy, nonatomic) NSString *JrmffooterRefreshingText; // 默认:@"正在加载数据..."

/**
 *  设置头部控件的文字
 */
@property (copy, nonatomic) NSString *JrmfheaderPullToRefreshText; // 默认:@"下拉可以刷新"
@property (copy, nonatomic) NSString *JrmfheaderReleaseToRefreshText; // 默认:@"松开立即刷新"
@property (copy, nonatomic) NSString *JrmfheaderRefreshingText; // 默认:@"正在刷新..."
@end
