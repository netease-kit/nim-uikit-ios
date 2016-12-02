//
//  UIView+NTES.m
//  NIMDemo
//
//  Created by ght on 15-1-31.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "UIView+NTES.h"
#import <objc/runtime.h>
@implementation UIView (NTES)

- (CGFloat)left {
    return self.frame.origin.x;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setLeft:(CGFloat)x {
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)top {
    return self.frame.origin.y;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setTop:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)right {
    return self.frame.origin.x + self.frame.size.width;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setRight:(CGFloat)right {
    CGRect frame = self.frame;
    frame.origin.x = right - frame.size.width;
    self.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)bottom {
    return self.frame.origin.y + self.frame.size.height;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setBottom:(CGFloat)bottom {
    CGRect frame = self.frame;
    frame.origin.y = bottom - frame.size.height;
    self.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)centerX {
    return self.center.x;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setCenterX:(CGFloat)centerX {
    self.center = CGPointMake(centerX, self.center.y);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)centerY {
    return self.center.y;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setCenterY:(CGFloat)centerY {
    self.center = CGPointMake(self.center.x, centerY);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)width {
    return self.frame.size.width;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setWidth:(CGFloat)width {
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)height {
    return self.frame.size.height;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setHeight:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}
///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGPoint)origin {
    return self.frame.origin;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setOrigin:(CGPoint)origin {
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGSize)size {
    return self.frame.size;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setSize:(CGSize)size {
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}


- (UIViewController *)viewController{
    for (UIView* next = self; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController*)nextResponder;
        }
    }
    return nil;
}

@end



@implementation UIView(NTESPresent)


static char PresentedViewAddress;   //被Present的View
static char PresentingViewAddress;  //正在Present其他视图的view
#define AnimateDuartion .25f
- (void)presentView:(UIView*)view animated:(BOOL)animated complete:(void(^)()) complete{
    if (!self.window) {
        return;
    }
    [self.window addSubview:view];
    objc_setAssociatedObject(self, &PresentedViewAddress, view, OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(view, &PresentingViewAddress, self, OBJC_ASSOCIATION_RETAIN);
    if (animated) {
        [self doAlertAnimate:view complete:complete];
    }else{
        view.center = self.window.center;
    }
}

- (UIView *)presentedView{
    UIView * view =  objc_getAssociatedObject(self, &PresentedViewAddress);
    return view;
}

- (void)dismissPresentedView:(BOOL)animated complete:(void(^)()) complete{
    UIView * view =  objc_getAssociatedObject(self, &PresentedViewAddress);
    if (animated) {
        [self doHideAnimate:view complete:complete];
    }else{
        [view removeFromSuperview];
        [self cleanAssocaiteObject];
    }
}

- (void)hideSelf:(BOOL)animated complete:(void(^)()) complete{
    UIView * baseView =  objc_getAssociatedObject(self, &PresentingViewAddress);
    if (!baseView) {
        return;
    }
    [baseView dismissPresentedView:animated complete:complete];
    [self cleanAssocaiteObject];
}


- (void)onPressBkg:(id)sender{
    [self dismissPresentedView:YES complete:nil];
}

#pragma mark - Animation
- (void)doAlertAnimate:(UIView*)view complete:(void(^)()) complete{
    CGRect bounds = view.bounds;
    // 放大
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
    scaleAnimation.duration  = AnimateDuartion;
    scaleAnimation.fromValue = [NSValue valueWithCGRect:CGRectMake(0, 0, 1, 1)];
    scaleAnimation.toValue   = [NSValue valueWithCGRect:bounds];
    
    // 移动
    CABasicAnimation *moveAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    moveAnimation.duration   = AnimateDuartion;
    moveAnimation.fromValue  = [NSValue valueWithCGPoint:[self.superview convertPoint:self.center toView:nil]];
    moveAnimation.toValue    = [NSValue valueWithCGPoint:self.window.center];
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.beginTime				= CACurrentMediaTime();
    group.duration				= AnimateDuartion;
    group.animations			= [NSArray arrayWithObjects:scaleAnimation,moveAnimation,nil];
    group.timingFunction		= [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    group.fillMode				= kCAFillModeForwards;
    group.removedOnCompletion	= NO;
    group.autoreverses			= NO;
    
    [self hideAllSubView:view];
    
    [view.layer addAnimation:group forKey:@"groupAnimationAlert"];
    
    __weak UIView * wself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(AnimateDuartion * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        view.layer.bounds    = bounds;
        view.layer.position  = wself.superview.center;
        [wself showAllSubView:view];
        if (complete) {
            complete();
        }
    });
    
}

- (void)doHideAnimate:(UIView*)alertView complete:(void(^)()) complete{
    if (!alertView) {
        return;
    }
    // 缩小
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
    scaleAnimation.duration = AnimateDuartion;
    scaleAnimation.toValue  = [NSValue valueWithCGRect:CGRectMake(0, 0, 1, 1)];
    
    CGPoint position   = self.center;
    // 移动
    CABasicAnimation *moveAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    moveAnimation.duration = AnimateDuartion;
    moveAnimation.toValue  = [NSValue valueWithCGPoint:[self.superview convertPoint:self.center toView:nil]];
    
    CAAnimationGroup *group   = [CAAnimationGroup animation];
    group.beginTime           = CACurrentMediaTime();
    group.duration            = AnimateDuartion;
    group.animations          = [NSArray arrayWithObjects:scaleAnimation,moveAnimation,nil];
    group.timingFunction      = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    group.fillMode            = kCAFillModeForwards;
    group.removedOnCompletion = NO;
    group.autoreverses        = NO;
    
    
    alertView.layer.bounds    = self.bounds;
    alertView.layer.position  = position;
    alertView.layer.needsDisplayOnBoundsChange = YES;
    
    [self hideAllSubView:alertView];
    alertView.backgroundColor = [UIColor clearColor];
    
    [alertView.layer addAnimation:group forKey:@"groupAnimationHide"];
    
    __weak UIView * wself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(AnimateDuartion * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [alertView removeFromSuperview];
        [wself cleanAssocaiteObject];
        [wself showAllSubView:alertView];
        if (complete) {
            complete();
        }
    });
}


static char *HideViewsAddress = "hideViewsAddress";
- (void)hideAllSubView:(UIView*)view{
    for (UIView * subView in view.subviews) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        if (subView.hidden) {
            [array addObject:subView];
        }
        objc_setAssociatedObject(self, &HideViewsAddress, array, OBJC_ASSOCIATION_RETAIN);
        subView.hidden = YES;
    }
}

- (void)showAllSubView:(UIView*)view{
    NSMutableArray *array = objc_getAssociatedObject(self,&HideViewsAddress);
    for (UIView * subView in view.subviews) {
        subView.hidden = [array containsObject:subView];
    }
}

- (void)cleanAssocaiteObject{
    objc_setAssociatedObject(self,&PresentedViewAddress,nil,OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(self,&PresentingViewAddress,nil,OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(self,&HideViewsAddress,nil, OBJC_ASSOCIATION_RETAIN);
}

@end
