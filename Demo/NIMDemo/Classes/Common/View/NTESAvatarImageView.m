//
//  AvatarImageView.m
//  NIMDemo
//
//  Created by chris on 15/2/10.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESAvatarImageView.h"
#import "UIView+NTES.h"

@interface NTESAvatarImageView()
@property(nonatomic,strong) UIImage * defaultImage;
@end

@implementation NTESAvatarImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.layer.geometryFlipped = YES;
        self.clipPath = YES;
        self.defaultImage = [UIImage imageNamed:@"avatar_user"];
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.backgroundColor = [UIColor clearColor];
        self.layer.geometryFlipped = YES;
        self.clipPath = YES;
    }
    return self;
}


- (void)setImage:(UIImage *)image
{
    image = image ? image : self.defaultImage;
    if (_image != image)
    {
        _image = image;
        [self setNeedsDisplay];
    }
}

- (void)setHilghtedImage:(UIImage *)hilghtedImage{
    if (_hilghtedImage != hilghtedImage) {
        _hilghtedImage = hilghtedImage;
        [self setNeedsDisplay];
    }
}


- (CGPathRef)path
{
    return [[UIBezierPath bezierPathWithRoundedRect:self.bounds
                                       cornerRadius:CGRectGetWidth(self.bounds) / 2] CGPath];
}

- (void)setHighlighted:(BOOL)highlighted{
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
}

- (void)setSelected:(BOOL)selected{
    [super setSelected:selected];
    [self setNeedsDisplay];
}


- (UIImage*)showImage{
    UIImage *showImage = (self.state == UIControlStateHighlighted || self.state ==UIControlStateSelected) && self.hilghtedImage ? self.hilghtedImage : self.image;
    return showImage;
}

#pragma mark Draw
- (void)drawRect:(CGRect)rect
{
    if (!self.width || !self.height) {
        return;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    if (_clipPath)
    {
        CGContextAddPath(context, [self path]);
        CGContextClip(context);
    }
    
    UIImage * image  = self.showImage;
    if (image && image.size.height && image.size.width)
    {
        //ScaleAspectFill模式
        CGPoint center   = CGPointMake(self.width * .5f, self.height * .5f);
        //哪个小按哪个缩
        CGFloat scaleW   = image.size.width  / self.width;
        CGFloat scaleH   = image.size.height / self.height;
        CGFloat scale    = scaleW < scaleH ? scaleW : scaleH;
        CGSize  size     = CGSizeMake(image.size.width / scale, image.size.height / scale);
        CGRect  drawRect = CGRectWithCenterAndSize(center, size);
        CGContextDrawImage(context, drawRect, self.showImage.CGImage);
        
    }
    CGContextRestoreGState(context);
}

CGRect CGRectWithCenterAndSize(CGPoint center, CGSize size){
    return CGRectMake(center.x - (size.width/2), center.y - (size.height/2), size.width, size.height);
}


@end




@implementation NTESAvatarImageView (NIMDemo)

+ (instancetype)demoInstanceRecentSessionList{
    return [NTESAvatarImageView demoInstance40x40];
}

+ (instancetype)demoInstanceContactDataList{
    return [NTESAvatarImageView demoInstance30x30];
}

+ (instancetype)demoInstanceUserList{
    return [NTESAvatarImageView demoInstance40x40];
}

+ (instancetype)demoInstance40x40{
    NTESAvatarImageView *avatarImageView = [[NTESAvatarImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    avatarImageView.image = [UIImage imageNamed:@"avatar_user.png"];
    return avatarImageView;
}

+ (instancetype)demoInstance30x30{
    NTESAvatarImageView *avatarImageView = [[NTESAvatarImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    avatarImageView.image = [UIImage imageNamed:@"avatar_user.png"];
    return avatarImageView;
}

+ (instancetype)demoInstanceTeamCardHeader{
    NTESAvatarImageView *avatarImageView = [[NTESAvatarImageView alloc] initWithFrame:CGRectMake(0, 0, 55, 55)];
    return avatarImageView;
}

+ (instancetype)demoInstanceTeamMember{
    NTESAvatarImageView *avatarImageView = [[NTESAvatarImageView alloc] initWithFrame:CGRectMake(0, 0, 37, 37)];
    return avatarImageView;
}

@end
