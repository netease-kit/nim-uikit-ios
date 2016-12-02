//
//  NTESPageView.h
//  NIM
//
//  Created by chris on 15/12/16.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
@class NTESPageView;

@protocol NTESPageViewDataSource <NSObject>
- (NSInteger)numberOfPages: (NTESPageView *)pageView;
- (UIView *)pageView: (NTESPageView *)pageView viewInPage: (NSInteger)index;
@end

@protocol NTESPageViewDelegate <NSObject>
@optional
- (void)pageViewScrollEnd: (NTESPageView *)pageView
             currentIndex: (NSInteger)index
               totolPages: (NSInteger)pages;

- (void)pageViewDidScroll: (NTESPageView *)pageView;
- (BOOL)needScrollAnimation;
@end


@interface NTESPageView : UIView<UIScrollViewDelegate>
@property (nonatomic,strong)    UIScrollView   *scrollView;
@property (nonatomic,weak)    id<NTESPageViewDataSource>  dataSource;
@property (nonatomic,weak)    id<NTESPageViewDelegate>    pageViewDelegate;
- (void)scrollToPage: (NSInteger)pages;
- (void)reloadData;
- (UIView *)viewAtIndex: (NSInteger)index;
- (NSInteger)currentPage;


//旋转相关方法,这两个方法必须配对调用,否则会有问题
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration;

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration;
@end