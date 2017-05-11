//
//  NIMInputPageView.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMPageView.h"

@interface NIMPageView ()
{
    NSInteger   _currentPage;
    NSInteger   _currentPageForRotation;
}

@property (nonatomic,strong)    NSMutableArray  *pages;

- (void)setupControls;

//重新载入的流程
- (void)calculatePageNumbers;
- (void)reloadPage;
- (void)raisePageIndexChangedDelegate;
@end

@implementation NIMPageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setupControls];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self setupControls];
    }
    return self;
}

- (void)setFrame:(CGRect)frame{
    CGFloat originalWidth = self.frame.size.width;
    [super setFrame:frame];
    if (originalWidth != frame.size.width) {
        [self reloadData];
    }
}

- (void)dealloc
{
    _scrollView.delegate = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [_scrollView setFrame:self.bounds];
    
    CGSize size = self.bounds.size;
    [self.scrollView setContentSize:CGSizeMake(size.width * [self.pages count], size.height)];
    for (NSInteger i = 0; i < [self.pages count]; i++)
    {
        id obj = [self.pages objectAtIndex:i];
        if ([obj isKindOfClass:[UIView class]])
        {
            [(UIView *)obj setFrame:CGRectMake(size.width * i, 0, size.width, size.height)];
        }
    }
    
    //CGSize size = self.bounds.size;
    BOOL animation = NO;
    if (self.pageViewDelegate && [self.pageViewDelegate respondsToSelector:@selector(needScrollAnimation)])
    {
        animation = [self.pageViewDelegate needScrollAnimation];
    }
    [self.scrollView scrollRectToVisible:CGRectMake(_currentPage * size.width, 0, size.width, size.height)
                                animated:animation];
    
}

- (void)setupControls
{
    if (_scrollView == nil)
    {
        _scrollView = [[UIScrollView alloc]initWithFrame:self.bounds];
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:_scrollView];
        _scrollView.pagingEnabled = YES;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.delegate = self;
        _scrollView.scrollsToTop = NO;
    }
}

#pragma mark - 对外接口
- (void)scrollToPage: (NSInteger)page
{
    if (_currentPage != page || page == 0)
    {
        _currentPage = page;
        [self reloadData];
    }
    
}

- (void)reloadData
{
    [self calculatePageNumbers];
    [self reloadPage];
}

- (UIView *)viewAtIndex: (NSInteger)index
{
    UIView *view = nil;
    if (index >= 0 && index < [_pages count])
    {
        id obj = [_pages objectAtIndex:index];
        if ([obj isKindOfClass:[UIView class]])
        {
            view = obj;
        }
    }
    return view;
}

- (NSInteger)currentPage
{
    return _currentPage;
}

- (NSInteger)pageInBound:(NSInteger)value min:(NSInteger)min max:(NSInteger)max{
    if (max < min) {
        max = min;
    }
    NSInteger bounded = value;
    if (bounded > max) {
        bounded = max;
    }
    if (bounded < min) {
        bounded = min;
    }
    return bounded;
}

#pragma mark - Page载入和销毁
- (void)loadPagesForCurrentPage:(NSInteger)currentPage
{
    NSUInteger count = [_pages count];
    if (count == 0)
    {
        return;
    }
    NSInteger first = [self pageInBound:currentPage - 1 min:0 max:count - 1];
    NSInteger last  = [self pageInBound:currentPage + 1 min:0 max:count - 1];
    NSRange range = NSMakeRange(first, last - first + 1);
    
    for (NSUInteger index = 0; index < count; index++)
    {
        if (NSLocationInRange(index, range))
        {
            id obj = [_pages objectAtIndex:index];
            if (![obj isKindOfClass:[UIView class]])
            {
                if (_dataSource && [_dataSource respondsToSelector:@selector(pageView:viewInPage:)])
                {
                    UIView *view = [_dataSource pageView:self viewInPage:index];
                    [_pages replaceObjectAtIndex:index withObject:view];
                    [self.scrollView addSubview:view];
                    CGSize size = self.bounds.size;
                    [view setFrame:CGRectMake(size.width * index, 0, size.width, size.height)];
                }
                else
                {
                    assert(0);
                }
            }
            
        }
        else
        {
            id obj = [_pages objectAtIndex:index];
            if ([obj isKindOfClass:[UIView class]])
            {
                [obj removeFromSuperview];
                [_pages replaceObjectAtIndex:index withObject:[NSNull null]];
            }
        }
    }
}


- (void)calculatePageNumbers
{
    NSInteger numberOfPages = 0;
    for (id obj in _pages)
    {
        if ([obj isKindOfClass:[UIView class]])
        {
            [(UIView *)obj removeFromSuperview];
        }
    }
    if(_dataSource && [_dataSource respondsToSelector:@selector(numberOfPages:)])
    {
        numberOfPages = [_dataSource numberOfPages:self];
    }
    self.pages = [NSMutableArray arrayWithCapacity:numberOfPages];
    for (NSInteger i = 0; i < numberOfPages; i ++)
    {
        [_pages addObject:[NSNull null]];
    }
    //注意，这里设置delegate是因为计算contentsize的时候会引起scrollViewDidScroll执行，修改currentpage的值，这样在贴图（举个例子）前面的分类页数比后面的分类页数多，前面的分类滚动到最后面一页后，再显示后面的分类，会显示不正确
    self.scrollView.delegate = nil;
    CGSize size = self.bounds.size;
    [self.scrollView setContentSize:CGSizeMake(size.width * numberOfPages, size.height)];
    self.scrollView.delegate = self;
}

- (void)reloadPage
{
    //reload的时候尽量记住上次的位置
    if (_currentPage >= [_pages count])
    {
        _currentPage = [_pages count] - 1;
    }
    if (_currentPage < 0)
    {
        _currentPage = 0;
    }
    
    [self loadPagesForCurrentPage:_currentPage];
    [self raisePageIndexChangedDelegate];
    [self setNeedsLayout];
}


#pragma mark - ScrollView Delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat width = scrollView.bounds.size.width;
    CGFloat offsetX = scrollView.contentOffset.x;
    NSInteger page = (NSInteger)(fabs(offsetX / width));
    if (page >= 0 && page < [_pages count])
    {
        if (_currentPage == page) {
            return;
        }
        _currentPage = page;
        [self loadPagesForCurrentPage:_currentPage];
    }
    
    if (_pageViewDelegate && [_pageViewDelegate respondsToSelector:@selector(pageViewDidScroll:)])
    {
        [_pageViewDelegate pageViewDidScroll:self];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self raisePageIndexChangedDelegate];
}

#pragma mark - 辅助方法
- (void)raisePageIndexChangedDelegate
{
    if (_pageViewDelegate && [_pageViewDelegate respondsToSelector:@selector(pageViewScrollEnd:currentIndex:totolPages:)])
    {
        [_pageViewDelegate pageViewScrollEnd:self
                                currentIndex:_currentPage
                                  totolPages:[_pages count]];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    _scrollView.delegate = nil;
    _currentPageForRotation = _currentPage;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration
{
    CGSize size = self.bounds.size;
    _scrollView.contentSize = CGSizeMake(size.width * [_pages count], size.height);
    for (NSUInteger i = 0; i < [_pages count]; i++)
    {
        id obj = [_pages objectAtIndex:i];
        if ([obj isKindOfClass:[UIView class]])
        {
            [(UIView *)obj setFrame:CGRectMake(size.width * i, 0, size.width, size.height)];
            
            /*
             //这里有点ugly,先这样吧...
             if ([obj respondsToSelector:@selector(reset)])
             {
             [obj performSelector:@selector(reset)];
             }*/
        }
    }
    _scrollView.contentOffset = CGPointMake(_currentPageForRotation * self.bounds.size.width, 0);
    _scrollView.delegate = self;
    
}

@end
