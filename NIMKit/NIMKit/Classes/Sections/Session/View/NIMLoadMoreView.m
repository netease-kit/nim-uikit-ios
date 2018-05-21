//
//  NIMLoadMoreView.m
//  NIMKit
//
//  Created by emily on 04/02/2018.
//  Copyright © 2018 NetEase. All rights reserved.
//

#import "NIMLoadMoreView.h"

@implementation NIMLoadMoreView

- (instancetype)initWithFrame:(CGRect)frame
{
    
    self = [super initWithFrame:frame];
    if (self) {
        _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityView.center = CGPointMake(frame.size.width/2, frame.size.height/2);
        [self addSubview:_activityView];
    }
    return self;
}


- (void)startAnimation
{
    _activityView.hidden = NO;
    [_activityView startAnimating];
}

- (void)stopAnimation
{
    if (_activityView.isAnimating == NO)
    {
        return;
    }
    _activityView.hidden = YES;
    [_activityView stopAnimating];
}

- (BOOL)isAnimating
{
    return _activityView.isAnimating;
}

@end
