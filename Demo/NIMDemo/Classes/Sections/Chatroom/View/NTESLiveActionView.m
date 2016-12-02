//
//  NTESLiveActionView.m
//  NIM
//
//  Created by chris on 16/1/26.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESLiveActionView.h"
#import "UIView+NTES.h"
#import "UIImage+NTESColor.h"


@interface NTESChatroomSegmentedItem : NSObject

@property (nonatomic, copy) NSString *showName;

@end

@interface NTESLiveActionView()<NTESPageViewDelegate,NTESPageViewDataSource>

@property (nonatomic, copy)   NSArray<NTESChatroomSegmentedItem *> *segmentedItems;

@end

@implementation NTESLiveActionView

- (instancetype)initWithDataSource:(id<NTESLiveActionViewDataSource>)datasource
{
    self = [super init];
    if (self) {
        _datasource = datasource;
        [self addSubview:self.segmentedControl];
        [self addSubview:self.pageView];
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
        [self addGestureRecognizer:gesture];
    }
    return self;
}

- (void)reloadData
{
    [self.pageView reloadData];
}


#pragma mark - Action Delegate

- (void)onSegmentControlChanged:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(onSegmentControlChanged:)]) {
        [self.delegate onSegmentControlChanged:sender];
    }
}

- (void)onTap:(UIGestureRecognizer *)gesture
{
    if ([self.delegate respondsToSelector:@selector(onTouchActionBackground)]) {
        [self.delegate onTouchActionBackground];
    }
}


- (NSInteger)numberOfPages:(NTESPageView *)pageView
{
    return [self.datasource numberOfPages];
}

- (UIView *)pageView:(NTESPageView *)pageView viewInPage: (NSInteger)index
{
    return [self.datasource viewInPage:index];
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    self.segmentedControl.height = self.segmentedControlHeight;
    CGFloat liveViewHeight       = [self.datasource liveViewHeight];
    self.segmentedControl.top    = liveViewHeight;
    CGFloat pageViewHeight       = self.height - liveViewHeight - self.segmentedControl.height;
    self.pageView.height         = pageViewHeight;
    self.pageView.bottom         = self.height;
}



#pragma mark - Get

#define SegmentDefaultHeight   40.f

- (CGFloat)segmentedControlHeight
{
    return SegmentDefaultHeight;
}

- (NTESPageView *)pageView{
    if (!_pageView) {
        _pageView = [[NTESPageView alloc] initWithFrame:CGRectMake(0, 0, self.width, 0)];
        _pageView.dataSource = self;
        _pageView.pageViewDelegate = self;
        _pageView.scrollView.scrollEnabled = NO;
        _pageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _pageView;
}

- (NTESChatroomSegmentedControl *)segmentedControl{
    if (!_segmentedControl) {
        _segmentedControl = [[NTESChatroomSegmentedControl alloc] initWithFrame:CGRectMake(0, 0, self.width,0)];
        _segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        UIImage *imageSelected = [[UIImage imageNamed:@"icon_chatroom_seg_bkg"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 1, 0, 1) resizingMode:UIImageResizingModeStretch];
        UIImage *imageNormal   = [[UIImage imageWithColor:[UIColor whiteColor]] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 1, 0, 1) resizingMode:UIImageResizingModeStretch];
        for (NSInteger index = 0; index < self.segmentedItems.count; index++) {
            NTESChatroomSegmentedItem *item = self.segmentedItems[index];
            [_segmentedControl insertSegmentWithTitle:item.showName];
            [_segmentedControl setBackgroundImage:imageNormal forState:UIControlStateNormal atIndex:index];
            [_segmentedControl setBackgroundImage:imageNormal forState:UIControlStateHighlighted atIndex:index];
            [_segmentedControl setBackgroundImage:imageSelected forState:UIControlStateSelected atIndex:index];
            [_segmentedControl setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal atIndex:index];
            [_segmentedControl setTitleColor:UIColorFromRGB(0x238efa) forState:UIControlStateSelected atIndex:index];
            [_segmentedControl setFont:[UIFont systemFontOfSize:17.f] atIndex:index];
        }
        [_segmentedControl addTarget:self action:@selector(onSegmentControlChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _segmentedControl;
}


- (NSArray<NTESChatroomSegmentedItem *> *)segmentedItems{
    if (!_segmentedItems) {
        NSMutableArray *items = [[NSMutableArray alloc] init];
        NSString *showNameKey = @"showName";
        NSArray *vcs = @[
                         @{
                             showNameKey : @"直播互动"
                             },
                         @{
                             showNameKey : @"主播"
                             },
                         @{
                             showNameKey : @"在线成员"
                             },
                         ];
        for (NSDictionary *dict in vcs) {
            NTESChatroomSegmentedItem *item = [[NTESChatroomSegmentedItem alloc] init];
            item.showName = dict[showNameKey];
            [items addObject:item];
        }
        _segmentedItems = [NSArray arrayWithArray:items];
    }
    return _segmentedItems;
}

@end


@implementation NTESChatroomSegmentedItem
@end

