//
//  NIMAvatarImageView.m
//  NIMKit
//
//  Created by chris on 15/2/10.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMAvatarImageView.h"
#import "UIView+NIM.h"
#import "objc/runtime.h"
#import "NIMKitDependency.h"
#import "NIMKit.h"
#import "NIMKitInfoFetchOption.h"
#import "NIMKitUrlManager.h"

@interface NIMAvatarImageView()

@property (nonatomic,strong) UIImageView *imageView;

@end

@implementation NIMAvatarImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setup];
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self setup];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self setupRadius];
    
    if (!CGSizeEqualToSize(self.imageView.nim_size, self.nim_size))
    {
        self.imageView.nim_size = self.nim_size;
        self.imageView.image = [self imageAddCorner:_image
                                             radius:_cornerRadius
                                            andSize:self.bounds.size];
    }
    
}

- (void)setup
{
    _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:_imageView];
    
    self.backgroundColor = [UIColor clearColor];
    [self setupRadius];
}


- (void)setupRadius
{
    switch ([NIMKit sharedKit].config.avatarType)
    {
        case NIMKitAvatarTypeNone:
            _cornerRadius = 0;
            break;
        case NIMKitAvatarTypeRounded:
            _cornerRadius = self.nim_width *.5f;
            break;
        case NIMKitAvatarTypeRadiusCorner:
            _cornerRadius = 6.f;
            break;
        default:
            break;
    }
}


- (void)setImage:(UIImage *)image
{
    if (_image != image)
    {
        _image = image;
        UIImage *fixedImage  = [self imageAddCorner:_image
                                             radius:_cornerRadius
                                            andSize:self.bounds.size];
        self.imageView.image = fixedImage;
    }
}

- (UIImage*)imageAddCorner:(UIImage *)image radius:(CGFloat)radius andSize:(CGSize)size
{
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGPathRef path = self.path;
    CGContextAddPath(ctx,path);
    CGContextClip(ctx);
    [image drawInRect:rect];
    CGContextDrawPath(ctx, kCGPathFillStroke);
    UIImage * newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (CGPathRef)path
{
    return [[UIBezierPath bezierPathWithRoundedRect:self.bounds
                                       cornerRadius:self.cornerRadius] CGPath];
}

- (void)setAvatarBySession:(NIMSession *)session
{
    NIMKitInfo *info = nil;
    if (session.sessionType == NIMSessionTypeTeam) {
        info = [[NIMKit sharedKit] infoByTeam:session.sessionId option:nil];
    } else if (session.sessionType == NIMSessionTypeSuperTeam) {
        info = [[NIMKit sharedKit] infoBySuperTeam:session.sessionId option:nil];
    } else {
        NIMKitInfoFetchOption *option = [[NIMKitInfoFetchOption alloc] init];
        option.session = session;
        info = [[NIMKit sharedKit] infoByUser:session.sessionId option:option];
    }
    [self setImageWithUrlString:info.avatarUrlString placeholderImage:info.avatarImage options:0];
}

- (void)setAvatarByMessage:(NIMMessage *)message
{
    NIMKitInfoFetchOption *option = [[NIMKitInfoFetchOption alloc] init];
    option.message = message;
    NSString *from = message.from;
    NIMKitInfo *info = [[NIMKit sharedKit] infoByUser:from option:option];
    [self setImageWithUrlString:info.avatarUrlString placeholderImage:info.avatarImage options:0];
}

- (void)nim_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder {
    [self setImageWithUrlString:url.absoluteString placeholderImage:placeholder options:0];
}

- (void)nim_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options {
    [self setImageWithUrlString:url.absoluteString placeholderImage:placeholder options:options];
}

- (void)setImageWithUrlString:(NSString *)urlString placeholderImage:(UIImage *)placeholderImage options:(SDWebImageOptions)options {
    if (placeholderImage && self.image != placeholderImage) {
        self.image = placeholderImage;
    }
    if (urlString.length == 0) {
        return;
    }

    //查询
    __block NSURL *targetUrl = nil;
    __weak typeof(self) weakSelf = self;
    [[NIMKitUrlManager shareManager] queryQriginalUrlWithShortUrl:urlString completion:^(NSString *originalUrl, NSError *error) {
        if (urlString && !error) {
            targetUrl = [NSURL URLWithString:originalUrl];
        } else {
            targetUrl = [NSURL URLWithString:urlString];
        }
        [weakSelf didSetImageUrl:targetUrl placeholderImage:placeholderImage options:options];
    }];
}

- (void)didSetImageUrl:(NSURL *)url placeholderImage:(UIImage *)placeholderImage options:(SDWebImageOptions)options {
    if (!url) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    UIImage *fixedPlaceholderImage  = [self imageAddCorner:placeholderImage
                                                    radius:_cornerRadius
                                                   andSize:self.bounds.size];
    [_imageView sd_setImageWithURL:url
                  placeholderImage:fixedPlaceholderImage
                           options:SDWebImageAvoidAutoSetImage|SDWebImageDelayPlaceholder
                         completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                             if (image) {
                                 weakSelf.image = image;
                             }
                             
    }];
}
@end
