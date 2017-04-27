//
//  NTESInputMoreContainerView.m
//  NIMDemo
//
//  Created by chris.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMInputMoreContainerView.h"
#import "NIMPageView.h"
#import "NIMMediaItem.h"
#import "NIMKitUIConfig.h"
#import "UIView+NIM.h"

NSInteger NIMMaxItemCountInPage = 8;
NSInteger NIMButtonItemWidth = 75;
NSInteger NIMButtonItemHeight = 85;
NSInteger NIMPageRowCount     = 2;
NSInteger NIMPageColumnCount  = 4;
NSInteger NIMButtonBegintLeftX = 11;




@interface NIMInputMoreContainerView() <NIMPageViewDataSource,NIMPageViewDelegate>
{
    NSArray                 *_mediaButtons;
    NSArray                 *_mediaItems;
}

@property (nonatomic, strong) NIMPageView *pageView;

@end

@implementation NIMInputMoreContainerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _pageView = [[NIMPageView alloc] initWithFrame:self.bounds];
        _pageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _pageView.dataSource = self;
        [self addSubview:_pageView];
    }
    return self;
}

- (void)setConfig:(id<NIMSessionConfig>)config
{
    _config = config;
    [self genMediaButtons];
    [self.pageView reloadData];
}


- (void)genMediaButtons
{
    NSMutableArray *mediaButtons = [NSMutableArray array];
    NSMutableArray *mediaItems = [NSMutableArray array];
    NSArray *items;
    if (!self.config) {
        items = [NIMKitUIConfig sharedConfig].defaultMediaItems;
    }else if([self.config respondsToSelector:@selector(mediaItems)]){
        items = [self.config mediaItems];
    }
    [items enumerateObjectsUsingBlock:^(NIMMediaItem *item, NSUInteger idx, BOOL *stop) {
        [mediaItems addObject:item];
        
        UIButton *btn = [[UIButton alloc] init];
        btn.tag = idx;
        [btn setImage:item.normalImage forState:UIControlStateNormal];
        [btn setImage:item.selectedImage forState:UIControlStateHighlighted];
        [btn setTitle:item.title forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn setTitleEdgeInsets:UIEdgeInsetsMake(76, -75, 0, 0)];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:14.0]];
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [mediaButtons addObject:btn];

    }];
    _mediaButtons = mediaButtons;
    _mediaItems = mediaItems;
}

- (void)setFrame:(CGRect)frame{
    CGFloat originalWidth = self.frame.size.width;
    [super setFrame:frame];
    if (originalWidth != frame.size.width) {
        [self.pageView reloadData];
    }
}

- (void)dealloc
{
    _pageView.dataSource = nil;
}


#pragma mark PageViewDataSource
- (NSInteger)numberOfPages: (NIMPageView *)pageView
{
    NSInteger count = [_mediaButtons count] / NIMMaxItemCountInPage;
    count = ([_mediaButtons count] % NIMMaxItemCountInPage == 0) ? count: count + 1;
    return MAX(count, 1);
}

- (UIView*)mediaPageView:(NIMPageView*)pageView beginItem:(NSInteger)begin endItem:(NSInteger)end
{
    UIView *subView = [[UIView alloc] init];
    NSInteger span = (self.nim_width - NIMPageColumnCount * NIMButtonItemWidth) / (NIMPageColumnCount +1);
    CGFloat startY          = NIMButtonBegintLeftX;
    NSInteger coloumnIndex = 0;
    NSInteger rowIndex = 0;
    NSInteger indexInPage = 0;
    for (NSInteger index = begin; index < end; index ++)
    {
        UIButton *button = [_mediaButtons objectAtIndex:index];
        [button addTarget:self action:@selector(onTouchButton:) forControlEvents:UIControlEventTouchUpInside];
        //计算位置
        rowIndex    = indexInPage / NIMPageColumnCount;
        coloumnIndex= indexInPage % NIMPageColumnCount;
        CGFloat x = span + (NIMButtonItemWidth + span) * coloumnIndex;
        CGFloat y = 0.0;
        if (rowIndex > 0)
        {
            y = rowIndex * NIMButtonItemHeight + startY + 15;
        }
        else
        {
            y = rowIndex * NIMButtonItemHeight + startY;
        }
        [button setFrame:CGRectMake(x, y, NIMButtonItemWidth, NIMButtonItemHeight)];
        [subView addSubview:button];
        indexInPage ++;
    }
    return subView;
}

- (UIView*)oneLineMediaInPageView:(NIMPageView *)pageView
                       viewInPage: (NSInteger)index
                            count:(NSInteger)count
{
    UIView *subView = [[UIView alloc] init];
    NSInteger span = (self.nim_width - count * NIMButtonItemWidth) / (count +1);
    
    for (NSInteger btnIndex = 0; btnIndex < count; btnIndex ++)
    {
        UIButton *button = [_mediaButtons objectAtIndex:btnIndex];
        [button addTarget:self action:@selector(onTouchButton:) forControlEvents:UIControlEventTouchUpInside];
        CGRect iconRect = CGRectMake(span + (NIMButtonItemWidth + span) * btnIndex, 58, NIMButtonItemWidth, NIMButtonItemHeight);
        [button setFrame:iconRect];
        [subView addSubview:button];
    }
    return subView;
}

- (UIView *)pageView: (NIMPageView *)pageView viewInPage: (NSInteger)index
{
    if ([_mediaButtons count] == 2 || [_mediaButtons count] == 3) //一行显示2个或者3个
    {
        return [self oneLineMediaInPageView:pageView viewInPage:index count:[_mediaButtons count]];
    }
    
    if (index < 0)
    {
        assert(0);
        index = 0;
    }
    NSInteger begin = index * NIMMaxItemCountInPage;
    NSInteger end = (index + 1) * NIMMaxItemCountInPage;
    if (end > [_mediaButtons count])
    {
        end = [_mediaButtons count];
    }
    return [self mediaPageView:pageView beginItem:begin endItem:end];
}

#pragma mark - button actions
- (void)onTouchButton:(id)sender
{
    NSInteger index = [sender tag];
    NIMMediaItem *item = _mediaItems[index];
    if (_actionDelegate && [_actionDelegate respondsToSelector:@selector(onTapMediaItem:)]) {
        BOOL handled = [_actionDelegate onTapMediaItem:item];
        if (!handled) {
            NSAssert(0, @"invalid item selector!");
        }
    }
    
}

@end
