//
//  NTESLiveActionView.h
//  NIM
//
//  Created by chris on 16/1/26.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESChatroomSegmentedControl.h"
#import "NTESPageView.h"

@protocol NTESLiveActionViewDataSource <NSObject>

@required
- (NSInteger)numberOfPages;

- (UIView *)viewInPage:(NSInteger)index;

- (CGFloat)liveViewHeight;

@end


@protocol NTESLiveActionViewDelegate <NSObject>

@optional

- (void)onSegmentControlChanged:(NTESChatroomSegmentedControl *)control;

- (void)onTouchActionBackground;

@end

@interface NTESLiveActionView : UIView

@property (nonatomic, strong) NTESPageView *pageView;

@property (nonatomic, strong) NTESChatroomSegmentedControl *segmentedControl;

@property (nonatomic,weak) id<NTESLiveActionViewDataSource> datasource;

@property (nonatomic,weak) id<NTESLiveActionViewDelegate> delegate;

- (instancetype)initWithDataSource:(id<NTESLiveActionViewDataSource>) datasource;

- (void)reloadData;

@end
