//
// UIScrollView+NTESPullToRefresh.m
//
//  Created by chris on 15/2/12.
//  Copyright (c) 2015年 Netease. All rights reserved.
//
//

#import <QuartzCore/QuartzCore.h>
#import "UIScrollView+NTESPullToRefresh.h"

#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)
#define fequalzero(a) (fabs(a) < FLT_EPSILON)

static CGFloat const NTESPullToRefreshViewHeight = 60;

@interface NTESPullToRefreshArrow : UIView

@property (nonatomic, strong) UIColor *arrowColor;

@end


@interface NTESPullToRefreshView ()

@property (nonatomic, copy) void (^pullToRefreshActionHandler)(void);

@property (nonatomic, strong) NTESPullToRefreshArrow *arrow;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UILabel *subtitleLabel;
@property (nonatomic, readwrite) NTESPullToRefreshState state;
@property (nonatomic, readwrite) NTESPullToRefreshPosition position;

@property (nonatomic, strong) NSMutableArray *titles;
@property (nonatomic, strong) NSMutableArray *subtitles;
@property (nonatomic, strong) NSMutableArray *viewForState;

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalTopInset;
@property (nonatomic, readwrite) CGFloat originalBottomInset;

@property (nonatomic, assign) BOOL wasTriggeredByUser;
@property (nonatomic, assign) BOOL showsPullToRefresh;
@property (nonatomic, assign) BOOL showsDateLabel;
@property(nonatomic, assign) BOOL isObserving;

- (void)resetScrollViewContentInset;
- (void)setScrollViewContentInsetForLoading;
- (void)setScrollViewContentInset:(UIEdgeInsets)insets;
- (void)rotateArrow:(float)degrees hide:(BOOL)hide;

@end



#pragma mark - UIScrollView (NTESPullToRefresh)
#import <objc/runtime.h>

static char UIScrollViewPullToRefreshView;

@implementation UIScrollView (NTESPullToRefresh)

@dynamic pullToRefreshView, showsPullToRefresh;

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler position:(NTESPullToRefreshPosition)position {
    
    if(!self.pullToRefreshView) {
        CGFloat yOrigin;
        switch (position) {
            case NTESPullToRefreshPositionTop:
                yOrigin = -NTESPullToRefreshViewHeight;
                break;
            case NTESPullToRefreshPositionBottom:
                yOrigin = self.contentSize.height;
                break;
            default:
                return;
        }
        NTESPullToRefreshView *view = [[NTESPullToRefreshView alloc] initWithFrame:CGRectMake(0, yOrigin, self.bounds.size.width, NTESPullToRefreshViewHeight)];
        view.pullToRefreshActionHandler = actionHandler;
        view.scrollView = self;
        [self addSubview:view];
        
        view.originalTopInset = self.contentInset.top;
        view.originalBottomInset = self.contentInset.bottom;
        view.position = position;
        self.pullToRefreshView = view;
        self.showsPullToRefresh = YES;
    }
    
}

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler {
    [self addPullToRefreshWithActionHandler:actionHandler position:NTESPullToRefreshPositionTop];
}

- (void)triggerPullToRefresh {
    self.pullToRefreshView.state = NTESPullToRefreshStateTriggered;
    [self.pullToRefreshView startAnimating];
}

- (void)setPullToRefreshView:(NTESPullToRefreshView *)pullToRefreshView {
    [self willChangeValueForKey:@"SVPullToRefreshView"];
    objc_setAssociatedObject(self, &UIScrollViewPullToRefreshView,
                             pullToRefreshView,
                             OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"SVPullToRefreshView"];
}

- (NTESPullToRefreshView *)pullToRefreshView {
    return objc_getAssociatedObject(self, &UIScrollViewPullToRefreshView);
}

- (void)setShowsPullToRefresh:(BOOL)showsPullToRefresh {
    self.pullToRefreshView.hidden = !showsPullToRefresh;
    
    if(!showsPullToRefresh) {
        if (self.pullToRefreshView.isObserving) {
            [self removeObserver:self.pullToRefreshView forKeyPath:@"contentOffset"];
            [self removeObserver:self.pullToRefreshView forKeyPath:@"contentSize"];
            [self removeObserver:self.pullToRefreshView forKeyPath:@"frame"];
            [self.pullToRefreshView resetScrollViewContentInset];
            self.pullToRefreshView.isObserving = NO;
        }
    }
    else {
        if (!self.pullToRefreshView.isObserving) {
            [self addObserver:self.pullToRefreshView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.pullToRefreshView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.pullToRefreshView forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
            self.pullToRefreshView.isObserving = YES;
            
            CGFloat yOrigin = 0;
            switch (self.pullToRefreshView.position) {
                case NTESPullToRefreshPositionTop:
                    yOrigin = -NTESPullToRefreshViewHeight;
                    break;
                case NTESPullToRefreshPositionBottom:
                    yOrigin = self.contentSize.height;
                    break;
            }
            
            self.pullToRefreshView.frame = CGRectMake(0, yOrigin, self.bounds.size.width, NTESPullToRefreshViewHeight);
        }
    }
}

- (BOOL)showsPullToRefresh {
    return !self.pullToRefreshView.hidden;
}

@end

#pragma mark - NTESPullToRefresh
@implementation NTESPullToRefreshView

// public properties
@synthesize pullToRefreshActionHandler, arrowColor, textColor, activityIndicatorViewColor, activityIndicatorViewStyle;

@synthesize state = _state;
@synthesize scrollView = _scrollView;
@synthesize showsPullToRefresh = _showsPullToRefresh;
@synthesize arrow = _arrow;
@synthesize activityIndicatorView = _activityIndicatorView;

@synthesize titleLabel = _titleLabel;


- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        
        // default styling values
        self.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        self.textColor = [UIColor darkGrayColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.state = NTESPullToRefreshStateStopped;
        self.showsDateLabel = NO;
        
        self.titles = [NSMutableArray arrayWithObjects:NSLocalizedString(@"下拉加载...",),
                       NSLocalizedString(@"松开刷新...",),
                       NSLocalizedString(@"加载中...",),
                       nil];
        
        self.subtitles = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", nil];
        self.viewForState = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", nil];
        self.wasTriggeredByUser = YES;
    }
    
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (self.superview && newSuperview == nil) {
        //use self.superview, not self.scrollView. Why self.scrollView == nil here?
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        if (scrollView.showsPullToRefresh) {
            if (self.isObserving) {
                //If enter this branch, it is the moment just before "SVPullToRefreshView's dealloc", so remove observer here
                [scrollView removeObserver:self forKeyPath:@"contentOffset"];
                [scrollView removeObserver:self forKeyPath:@"contentSize"];
                [scrollView removeObserver:self forKeyPath:@"frame"];
                self.isObserving = NO;
            }
        }
    }
}

- (void)layoutSubviews {
    
    for(id otherView in self.viewForState) {
        if([otherView isKindOfClass:[UIView class]])
            [otherView removeFromSuperview];
    }
    
    id customView = [self.viewForState objectAtIndex:self.state];
    BOOL hasCustomView = [customView isKindOfClass:[UIView class]];
    
    self.titleLabel.hidden = hasCustomView;
    self.subtitleLabel.hidden = hasCustomView;
    self.arrow.hidden = hasCustomView;
    
    if(hasCustomView) {
        [self addSubview:customView];
        CGRect viewBounds = [customView bounds];
        CGPoint origin = CGPointMake(roundf((self.bounds.size.width-viewBounds.size.width)/2), roundf((self.bounds.size.height-viewBounds.size.height)/2));
        [customView setFrame:CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height)];
    }
    else {
        switch (self.state) {
            case NTESPullToRefreshStateAll:
            case NTESPullToRefreshStateStopped:
                self.arrow.alpha = 1;
                [self.activityIndicatorView stopAnimating];
                switch (self.position) {
                    case NTESPullToRefreshPositionTop:
                        [self rotateArrow:0 hide:NO];
                        break;
                    case NTESPullToRefreshPositionBottom:
                        [self rotateArrow:(float)M_PI hide:NO];
                        break;
                }
                break;
                
            case NTESPullToRefreshStateTriggered:
                switch (self.position) {
                    case NTESPullToRefreshPositionTop:
                        [self rotateArrow:(float)M_PI hide:NO];
                        break;
                    case NTESPullToRefreshPositionBottom:
                        [self rotateArrow:0 hide:NO];
                        break;
                }
                break;
                
            case NTESPullToRefreshStateLoading:
                [self.activityIndicatorView startAnimating];
                switch (self.position) {
                    case NTESPullToRefreshPositionTop:
                        [self rotateArrow:0 hide:YES];
                        break;
                    case NTESPullToRefreshPositionBottom:
                        [self rotateArrow:(float)M_PI hide:YES];
                        break;
                }
                break;
        }
        
        CGFloat leftViewWidth = MAX(self.arrow.bounds.size.width,self.activityIndicatorView.bounds.size.width);
        
        CGFloat margin = 10;
        CGFloat marginY = 2;
        CGFloat labelMaxWidth = self.bounds.size.width - margin - leftViewWidth;
        
        self.titleLabel.text = [self.titles objectAtIndex:self.state];
        
        NSString *subtitle = [self.subtitles objectAtIndex:self.state];
        self.subtitleLabel.text = subtitle.length > 0 ? subtitle : nil;
        
        
        CGSize titleSize = [self.titleLabel.text boundingRectWithSize:CGSizeMake(labelMaxWidth,self.titleLabel.font.lineHeight)
                                          options:(NSStringDrawingUsesFontLeading|NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin)
                                       attributes:@{NSFontAttributeName: self.titleLabel.font}
                                          context:NULL].size;
        
        CGSize subtitleSize = [self.subtitleLabel.text boundingRectWithSize:CGSizeMake(labelMaxWidth,self.subtitleLabel.font.lineHeight)
                                                              options:(NSStringDrawingUsesFontLeading|NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin)
                                                           attributes:@{NSFontAttributeName: self.subtitleLabel.font}
                                                              context:NULL].size;
        
        CGFloat maxLabelWidth = MAX(titleSize.width,subtitleSize.width);
        
        CGFloat totalMaxWidth;
        if (maxLabelWidth) {
            totalMaxWidth = leftViewWidth + margin + maxLabelWidth;
        } else {
            totalMaxWidth = leftViewWidth + maxLabelWidth;
        }
        
        CGFloat labelX = (self.bounds.size.width / 2) - (totalMaxWidth / 2) + leftViewWidth + margin;
        
        if(subtitleSize.height > 0){
            CGFloat totalHeight = titleSize.height + subtitleSize.height + marginY;
            CGFloat minY = (self.bounds.size.height / 2)  - (totalHeight / 2);
            
            CGFloat titleY = minY;
            self.titleLabel.frame = CGRectIntegral(CGRectMake(labelX, titleY, titleSize.width, titleSize.height));
            self.subtitleLabel.frame = CGRectIntegral(CGRectMake(labelX, titleY + titleSize.height + marginY, subtitleSize.width, subtitleSize.height));
        }else{
            CGFloat totalHeight = titleSize.height;
            CGFloat minY = (self.bounds.size.height / 2)  - (totalHeight / 2);
            
            CGFloat titleY = minY;
            self.titleLabel.frame = CGRectIntegral(CGRectMake(labelX, titleY, titleSize.width, titleSize.height));
            self.subtitleLabel.frame = CGRectIntegral(CGRectMake(labelX, titleY + titleSize.height + marginY, subtitleSize.width, subtitleSize.height));
        }
        
        CGFloat arrowX = (self.bounds.size.width / 2) - (totalMaxWidth / 2) + (leftViewWidth - self.arrow.bounds.size.width) / 2;
        self.arrow.frame = CGRectMake(arrowX,
                                      (self.bounds.size.height / 2) - (self.arrow.bounds.size.height / 2),
                                      self.arrow.bounds.size.width,
                                      self.arrow.bounds.size.height);
        self.activityIndicatorView.center = self.arrow.center;
    }
}

#pragma mark - Scroll View

- (void)resetScrollViewContentInset {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    switch (self.position) {
        case NTESPullToRefreshPositionTop:
            currentInsets.top = self.originalTopInset;
            break;
        case NTESPullToRefreshPositionBottom:
            currentInsets.bottom = self.originalBottomInset;
            currentInsets.top = self.originalTopInset;
            break;
    }
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInsetForLoading {
    CGFloat offset = MAX(self.scrollView.contentOffset.y * -1, 0);
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    switch (self.position) {
        case NTESPullToRefreshPositionTop:
            currentInsets.top = MIN(offset, self.originalTopInset + self.bounds.size.height);
            break;
        case NTESPullToRefreshPositionBottom:
            currentInsets.bottom = MIN(offset, self.originalBottomInset + self.bounds.size.height);
            break;
    }
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset {
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.scrollView.contentInset = contentInset;
                     }
                     completion:NULL];
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"contentOffset"])
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    else if([keyPath isEqualToString:@"contentSize"]) {
        [self layoutSubviews];
        
        CGFloat yOrigin;
        switch (self.position) {
            case NTESPullToRefreshPositionTop:
                yOrigin = -NTESPullToRefreshViewHeight;
                break;
            case NTESPullToRefreshPositionBottom:
                yOrigin = MAX(self.scrollView.contentSize.height, self.scrollView.bounds.size.height);
                break;
        }
        self.frame = CGRectMake(0, yOrigin, self.bounds.size.width, NTESPullToRefreshViewHeight);
    }
    else if([keyPath isEqualToString:@"frame"])
        [self layoutSubviews];
    
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    if(self.state != NTESPullToRefreshStateLoading) {
        CGFloat scrollOffsetThreshold = 0;
        switch (self.position) {
            case NTESPullToRefreshPositionTop:
                scrollOffsetThreshold = self.frame.origin.y - self.originalTopInset;
                break;
            case NTESPullToRefreshPositionBottom:
                scrollOffsetThreshold = MAX(self.scrollView.contentSize.height - self.scrollView.bounds.size.height, 0.0f) + self.bounds.size.height + self.originalBottomInset;
                break;
        }
        
        if(!self.scrollView.isDragging && self.state == NTESPullToRefreshStateTriggered)
            self.state = NTESPullToRefreshStateLoading;
        else if(contentOffset.y < scrollOffsetThreshold && self.scrollView.isDragging && self.state == NTESPullToRefreshStateStopped && self.position == NTESPullToRefreshPositionTop)
            self.state = NTESPullToRefreshStateTriggered;
        else if(contentOffset.y >= scrollOffsetThreshold && self.state != NTESPullToRefreshStateStopped && self.position == NTESPullToRefreshPositionTop)
            self.state = NTESPullToRefreshStateStopped;
        else if(contentOffset.y > scrollOffsetThreshold && self.scrollView.isDragging && self.state == NTESPullToRefreshStateStopped && self.position == NTESPullToRefreshPositionBottom)
            self.state = NTESPullToRefreshStateTriggered;
        else if(contentOffset.y <= scrollOffsetThreshold && self.state != NTESPullToRefreshStateStopped && self.position == NTESPullToRefreshPositionBottom)
            self.state = NTESPullToRefreshStateStopped;
    } else {
        CGFloat offset;
        UIEdgeInsets contentInset;
        switch (self.position) {
            case NTESPullToRefreshPositionTop:
                offset = MAX(self.scrollView.contentOffset.y * -1, 0.0f);
                offset = MIN(offset, self.originalTopInset + self.bounds.size.height);
                contentInset = self.scrollView.contentInset;
                self.scrollView.contentInset = UIEdgeInsetsMake(offset, contentInset.left, contentInset.bottom, contentInset.right);
                break;
            case NTESPullToRefreshPositionBottom:
                if (self.scrollView.contentSize.height >= self.scrollView.bounds.size.height) {
                    offset = MAX(self.scrollView.contentSize.height - self.scrollView.bounds.size.height + self.bounds.size.height, 0.0f);
                    offset = MIN(offset, self.originalBottomInset + self.bounds.size.height);
                    contentInset = self.scrollView.contentInset;
                    self.scrollView.contentInset = UIEdgeInsetsMake(contentInset.top, contentInset.left, offset, contentInset.right);
                } else if (self.wasTriggeredByUser) {
                    offset = MIN(self.bounds.size.height, self.originalBottomInset + self.bounds.size.height);
                    contentInset = self.scrollView.contentInset;
                    self.scrollView.contentInset = UIEdgeInsetsMake(-offset, contentInset.left, contentInset.bottom, contentInset.right);
                }
                break;
        }
    }
}

#pragma mark - Getters

- (NTESPullToRefreshArrow *)arrow {
    if(!_arrow) {
        _arrow = [[NTESPullToRefreshArrow alloc]initWithFrame:CGRectMake(0, self.bounds.size.height-54, 22, 48)];
        _arrow.backgroundColor = [UIColor clearColor];
        [self addSubview:_arrow];
    }
    return _arrow;
}

- (UIActivityIndicatorView *)activityIndicatorView {
    if(!_activityIndicatorView) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityIndicatorView.hidesWhenStopped = YES;
        [self addSubview:_activityIndicatorView];
    }
    return _activityIndicatorView;
}

- (UILabel *)titleLabel {
    if(!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 210, 20)];
        _titleLabel.text = NSLocalizedString(@"Pull to refresh...",);
        _titleLabel.font = [UIFont boldSystemFontOfSize:14];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = textColor;
        [self addSubview:_titleLabel];
    }
    return _titleLabel;
}

- (UILabel *)subtitleLabel {
    if(!_subtitleLabel) {
        _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 210, 20)];
        _subtitleLabel.font = [UIFont systemFontOfSize:12];
        _subtitleLabel.backgroundColor = [UIColor clearColor];
        _subtitleLabel.textColor = textColor;
        [self addSubview:_subtitleLabel];
    }
    return _subtitleLabel;
}

- (UILabel *)dateLabel {
    return self.showsDateLabel ? self.subtitleLabel : nil;
}

- (UIColor *)arrowColor {
    return self.arrow.arrowColor; // pass through
}

- (UIColor *)textColor {
    return self.titleLabel.textColor;
}

- (UIColor *)activityIndicatorViewColor {
    return self.activityIndicatorView.color;
}

- (UIActivityIndicatorViewStyle)activityIndicatorViewStyle {
    return self.activityIndicatorView.activityIndicatorViewStyle;
}

#pragma mark - Setters

- (void)setArrowColor:(UIColor *)newArrowColor {
    self.arrow.arrowColor = newArrowColor; // pass through
    [self.arrow setNeedsDisplay];
}

- (void)setTitle:(NSString *)title forState:(NTESPullToRefreshState)state {
    if(!title)
        title = @"";
    
    if(state == NTESPullToRefreshStateAll)
        [self.titles replaceObjectsInRange:NSMakeRange(0, 3) withObjectsFromArray:@[title, title, title]];
    else
        [self.titles replaceObjectAtIndex:state withObject:title];
    
    [self setNeedsLayout];
}

- (void)setSubtitle:(NSString *)subtitle forState:(NTESPullToRefreshState)state {
    if(!subtitle)
        subtitle = @"";
    
    if(state == NTESPullToRefreshStateAll)
        [self.subtitles replaceObjectsInRange:NSMakeRange(0, 3) withObjectsFromArray:@[subtitle, subtitle, subtitle]];
    else
        [self.subtitles replaceObjectAtIndex:state withObject:subtitle];
    
    [self setNeedsLayout];
}

- (void)setCustomView:(UIView *)view forState:(NTESPullToRefreshState)state {
    id viewPlaceholder = view;
    
    if(!viewPlaceholder)
        viewPlaceholder = @"";
    
    if(state == NTESPullToRefreshStateAll)
        [self.viewForState replaceObjectsInRange:NSMakeRange(0, 3) withObjectsFromArray:@[viewPlaceholder, viewPlaceholder, viewPlaceholder]];
    else
        [self.viewForState replaceObjectAtIndex:state withObject:viewPlaceholder];
    
    [self setNeedsLayout];
}

- (void)setTextColor:(UIColor *)newTextColor {
    textColor = newTextColor;
    self.titleLabel.textColor = newTextColor;
    self.subtitleLabel.textColor = newTextColor;
}

- (void)setActivityIndicatorViewColor:(UIColor *)color {
    self.activityIndicatorView.color = color;
}

- (void)setActivityIndicatorViewStyle:(UIActivityIndicatorViewStyle)viewStyle {
    self.activityIndicatorView.activityIndicatorViewStyle = viewStyle;
}



#pragma mark -

- (void)startAnimating{
    switch (self.position) {
        case NTESPullToRefreshPositionTop:
            
            if(fequalzero(self.scrollView.contentOffset.y)) {
                [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -self.frame.size.height) animated:YES];
                self.wasTriggeredByUser = NO;
            }
            else
                self.wasTriggeredByUser = YES;
            
            break;
        case NTESPullToRefreshPositionBottom:
            
            if((fequalzero(self.scrollView.contentOffset.y) && self.scrollView.contentSize.height < self.scrollView.bounds.size.height)
               || fequal(self.scrollView.contentOffset.y, self.scrollView.contentSize.height - self.scrollView.bounds.size.height)) {
                [self.scrollView setContentOffset:(CGPoint){.y = MAX(self.scrollView.contentSize.height - self.scrollView.bounds.size.height, 0.0f) + self.frame.size.height} animated:YES];
                self.wasTriggeredByUser = NO;
            }
            else
                self.wasTriggeredByUser = YES;
            
            break;
    }
    
    self.state = NTESPullToRefreshStateLoading;
}

- (void)stopAnimating {
    self.state = NTESPullToRefreshStateStopped;
    
    switch (self.position) {
        case NTESPullToRefreshPositionTop:
            if(!self.wasTriggeredByUser)
                [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -self.originalTopInset) animated:YES];
            break;
        case NTESPullToRefreshPositionBottom:
            if(!self.wasTriggeredByUser)
                [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, self.scrollView.contentSize.height - self.scrollView.bounds.size.height + self.originalBottomInset) animated:YES];
            break;
    }
}

- (void)setState:(NTESPullToRefreshState)newState {
    
    if(_state == newState)
        return;
    
    NTESPullToRefreshState previousState = _state;
    _state = newState;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    switch (newState) {
        case NTESPullToRefreshStateAll:
        case NTESPullToRefreshStateStopped:
            [self resetScrollViewContentInset];
            break;
            
        case NTESPullToRefreshStateTriggered:
            break;
            
        case NTESPullToRefreshStateLoading:
            [self setScrollViewContentInsetForLoading];
            
            if(previousState == NTESPullToRefreshStateTriggered && pullToRefreshActionHandler)
                pullToRefreshActionHandler();
            
            break;
    }
}

- (void)rotateArrow:(float)degrees hide:(BOOL)hide {
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.arrow.layer.transform = CATransform3DMakeRotation(degrees, 0, 0, 1);
        self.arrow.layer.opacity = !hide;
        //[self.arrow setNeedsDisplay];//ios 4
    } completion:NULL];
}

@end


#pragma mark - NTESPullToRefreshArrow

@implementation NTESPullToRefreshArrow
@synthesize arrowColor;

- (UIColor *)arrowColor {
    if (arrowColor) return arrowColor;
    return [UIColor grayColor]; // default Color
}

- (void)drawRect:(CGRect)rect {
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    // the rects above the arrow
    CGContextAddRect(c, CGRectMake(5, 0, 12, 4)); // to-do: use dynamic points
    CGContextAddRect(c, CGRectMake(5, 6, 12, 4)); // currently fixed size: 22 x 48pt
    CGContextAddRect(c, CGRectMake(5, 12, 12, 4));
    CGContextAddRect(c, CGRectMake(5, 18, 12, 4));
    CGContextAddRect(c, CGRectMake(5, 24, 12, 4));
    CGContextAddRect(c, CGRectMake(5, 30, 12, 4));
    
    // the arrow
    CGContextMoveToPoint(c, 0, 34);
    CGContextAddLineToPoint(c, 11, 48);
    CGContextAddLineToPoint(c, 22, 34);
    CGContextAddLineToPoint(c, 0, 34);
    CGContextClosePath(c);
    
    CGContextSaveGState(c);
    CGContextClip(c);
    
    // Gradient Declaration
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat alphaGradientLocations[] = {0, 0.8f};
    
    CGGradientRef alphaGradient = nil;
    if([[[UIDevice currentDevice] systemVersion]floatValue] >= 5){
        NSArray* alphaGradientColors = [NSArray arrayWithObjects:
                                        (id)[self.arrowColor colorWithAlphaComponent:0].CGColor,
                                        (id)[self.arrowColor colorWithAlphaComponent:1].CGColor,
                                        nil];
        alphaGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)alphaGradientColors, alphaGradientLocations);
    }else{
        const CGFloat * components = CGColorGetComponents([self.arrowColor CGColor]);
        size_t numComponents = CGColorGetNumberOfComponents([self.arrowColor CGColor]);
        CGFloat colors[8];
        switch(numComponents){
            case 2:{
                colors[0] = colors[4] = components[0];
                colors[1] = colors[5] = components[0];
                colors[2] = colors[6] = components[0];
                break;
            }
            case 4:{
                colors[0] = colors[4] = components[0];
                colors[1] = colors[5] = components[1];
                colors[2] = colors[6] = components[2];
                break;
            }
        }
        colors[3] = 0;
        colors[7] = 1;
        alphaGradient = CGGradientCreateWithColorComponents(colorSpace,colors,alphaGradientLocations,2);
    }
    
    
    CGContextDrawLinearGradient(c, alphaGradient, CGPointZero, CGPointMake(0, rect.size.height), 0);
    
    CGContextRestoreGState(c);
    
    CGGradientRelease(alphaGradient);
    CGColorSpaceRelease(colorSpace);
}
@end