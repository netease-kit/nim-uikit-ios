//
//  NIMKitProgressHUD.m
//  NIMKit
//
//  Created by chris on 2017/7/28.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import "NIMKitProgressHUD.h"
#import "UIView+NIM.h"
#import "NIMKit.h"

@interface NIMKitProgressHUD()

@property (nonatomic, strong) CAShapeLayer *indefiniteAnimatedLayer;

@end

@implementation NIMKitProgressHUD

+ (instancetype)sharedView
{
    static NIMKitProgressHUD *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NIMKitProgressHUD alloc] initWithFrame:CGRectMake(0, 0, 84, 84)];
    });
    return instance;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurView.frame = self.bounds;
        [self.contentView addSubview:blurView];

        self.backgroundColor  = [UIColor whiteColor];
        self.layer.cornerRadius = 14.f;
        self.alpha = 0.8;
        self.clipsToBounds = YES;
    }
    return self;
}

+ (void)show
{
    [[NIMKitProgressHUD sharedView] showInView:[UIApplication sharedApplication].keyWindow];
}

+ (void)dismiss
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NIMKitProgressHUD sharedView] removeFromSuperview];
        [[NIMKitProgressHUD sharedView].indefiniteAnimatedLayer removeFromSuperlayer];
    });
}

- (void)showInView:(UIView *)view
{
    [view addSubview:self];
    self.center = view.center;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self.layer addSublayer:self.indefiniteAnimatedLayer];
    [CATransaction commit];
}


- (CAShapeLayer*)indefiniteAnimatedLayer {
    if(!_indefiniteAnimatedLayer) {
        CGFloat strokeThickness = 2.f;
        CGFloat radius = 18.f;
        
        CGPoint arcCenter = CGPointMake(radius+strokeThickness/2+5, radius+strokeThickness/2+5);
        UIBezierPath* smoothedPath = [UIBezierPath bezierPathWithArcCenter:arcCenter radius:radius startAngle:(CGFloat) (M_PI*3/2) endAngle:(CGFloat) (M_PI/2+M_PI*5) clockwise:YES];
        
        _indefiniteAnimatedLayer = [CAShapeLayer layer];
        _indefiniteAnimatedLayer.contentsScale = [[UIScreen mainScreen] scale];
        _indefiniteAnimatedLayer.frame = CGRectMake(0.0f, 0.0f, arcCenter.x*2, arcCenter.y*2);
        _indefiniteAnimatedLayer.fillColor = [UIColor clearColor].CGColor;
        _indefiniteAnimatedLayer.strokeColor = [UIColor blackColor].CGColor;
        _indefiniteAnimatedLayer.lineWidth = 2;
        _indefiniteAnimatedLayer.lineCap = kCALineCapRound;
        _indefiniteAnimatedLayer.lineJoin = kCALineJoinBevel;
        _indefiniteAnimatedLayer.path = smoothedPath.CGPath;
        
        CALayer *maskLayer = [CALayer layer];
        
        NSBundle *bundle = [NSBundle bundleForClass:[NIMKitProgressHUD class]];
        NSURL *url = [bundle URLForResource:[NIMKit sharedKit].resourceBundleName withExtension:nil];
        NSBundle *imageBundle = [NSBundle bundleWithURL:url];
        
        NSString *path = [imageBundle pathForResource:@"bk_angle_mask" ofType:@"png"];
        
        maskLayer.contents = (__bridge id)[[UIImage imageWithContentsOfFile:path] CGImage];
        maskLayer.frame = _indefiniteAnimatedLayer.bounds;
        _indefiniteAnimatedLayer.mask = maskLayer;
        
        NSTimeInterval animationDuration = 1;
        CAMediaTimingFunction *linearCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        animation.fromValue = (id) 0;
        animation.toValue = @(M_PI*2);
        animation.duration = animationDuration;
        animation.timingFunction = linearCurve;
        animation.removedOnCompletion = NO;
        animation.repeatCount = INFINITY;
        animation.fillMode = kCAFillModeForwards;
        animation.autoreverses = NO;
        [_indefiniteAnimatedLayer.mask addAnimation:animation forKey:@"rotate"];
        
        CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
        animationGroup.duration = animationDuration;
        animationGroup.repeatCount = INFINITY;
        animationGroup.removedOnCompletion = NO;
        animationGroup.timingFunction = linearCurve;
        
        CABasicAnimation *strokeStartAnimation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
        strokeStartAnimation.fromValue = @0.015;
        strokeStartAnimation.toValue = @0.515;
        
        CABasicAnimation *strokeEndAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        strokeEndAnimation.fromValue = @0.485;
        strokeEndAnimation.toValue = @0.985;
        
        animationGroup.animations = @[strokeStartAnimation, strokeEndAnimation];
        [_indefiniteAnimatedLayer addAnimation:animationGroup forKey:@"progress"];
        
    }
    return _indefiniteAnimatedLayer;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    self.indefiniteAnimatedLayer.position = CGPointMake(self.nim_width * 0.5f, self.nim_height * 0.5f);
}


@end
