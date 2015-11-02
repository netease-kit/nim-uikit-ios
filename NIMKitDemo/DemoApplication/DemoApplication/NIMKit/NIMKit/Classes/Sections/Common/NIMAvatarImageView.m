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
#import "UIView+NIMWebCacheOperation.h"
#import "NIMKit.h"


static char imageURLKey;


@interface NIMAvatarImageView()
@end

@implementation NIMAvatarImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.layer.geometryFlipped = YES;
        self.clipPath = YES;
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
    if (_image != image)
    {
        _image = image;
        [self setNeedsDisplay];
    }
}


- (CGPathRef)path
{
    return [[UIBezierPath bezierPathWithRoundedRect:self.bounds
                                       cornerRadius:CGRectGetWidth(self.bounds) / 2] CGPath];
}


#pragma mark Draw
- (void)drawRect:(CGRect)rect
{
    if (!self.nim_width || !self.nim_height) {
        return;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    if (_clipPath)
    {
        CGContextAddPath(context, [self path]);
        CGContextClip(context);
    }
    UIImage *image = _image;
    if (image && image.size.height && image.size.width)
    {
        //ScaleAspectFill模式
        CGPoint center   = CGPointMake(self.nim_width * .5f, self.nim_height * .5f);
        //哪个小按哪个缩
        CGFloat scaleW   = image.size.width  / self.nim_width;
        CGFloat scaleH   = image.size.height / self.nim_height;
        CGFloat scale    = scaleW < scaleH ? scaleW : scaleH;
        CGSize  size     = CGSizeMake(image.size.width / scale, image.size.height / scale);
        CGRect  drawRect = NIMKit_CGRectWithCenterAndSize(center, size);
        CGContextDrawImage(context, drawRect, image.CGImage);
        
    }
    CGContextRestoreGState(context);
}

CGRect NIMKit_CGRectWithCenterAndSize(CGPoint center, CGSize size){
    return CGRectMake(center.x - (size.width/2), center.y - (size.height/2), size.width, size.height);
}

- (void)setAvatarBySession:(NIMSession *)session
{
    NIMKitInfo *info;
    if (session.sessionType == NIMSessionTypeTeam) {
        info = [[NIMKit sharedKit] infoByTeam:session.sessionId];
    }else{
        info = [[NIMKit sharedKit] infoByUser:session.sessionId];
    }
    NSURL *url = info.avatarUrlString ? [NSURL URLWithString:info.avatarUrlString] : nil;
    [self nim_setImageWithURL:url placeholderImage:info.avatarImage];
}

@end


@implementation NIMAvatarImageView (SDWebImageCache)

- (void)nim_setImageWithURL:(NSURL *)url {
    [self nim_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)nim_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder {
    [self nim_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)nim_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(NIMWebImageOptions)options {
    [self nim_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)nim_setImageWithURL:(NSURL *)url completed:(NIMWebImageCompletionBlock)completedBlock {
    [self nim_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)nim_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(NIMWebImageCompletionBlock)completedBlock {
    [self nim_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

- (void)nim_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(NIMWebImageOptions)options completed:(NIMWebImageCompletionBlock)completedBlock {
    [self nim_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)nim_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(NIMWebImageOptions)options progress:(NIMWebImageDownloaderProgressBlock)progressBlock completed:(NIMWebImageCompletionBlock)completedBlock {
    [self nim_cancelCurrentImageLoad];
    objc_setAssociatedObject(self, &imageURLKey, url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (!(options & NIMWebImageDelayPlaceholder)) {
        dispatch_main_async_safe(^{
            self.image = placeholder;
        });
    }
    
    if (url) {
        __weak __typeof(self)wself = self;
        id <NIMWebImageOperation> operation = [NIMWebImageManager.sharedManager downloadImageWithURL:url options:options progress:progressBlock completed:^(UIImage *image, NSError *error, NIMImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (!wself) return;
            dispatch_main_sync_safe(^{
                if (!wself) return;
                if (image && (options & NIMWebImageAvoidAutoSetImage) && completedBlock)
                {
                    completedBlock(image, error, cacheType, url);
                    return;
                }
                else if (image) {
                    wself.image = image;
                    [wself setNeedsLayout];
                } else {
                    if ((options & NIMWebImageDelayPlaceholder)) {
                        wself.image = placeholder;
                        [wself setNeedsLayout];
                    }
                }
                if (completedBlock && finished) {
                    completedBlock(image, error, cacheType, url);
                }
            });
        }];
        [self nim_setImageLoadOperation:operation forKey:@"UIImageViewImageLoad"];
    } else {
        dispatch_main_async_safe(^{
            NSError *error = [NSError errorWithDomain:NIMWebImageErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Trying to load a nil url"}];
            if (completedBlock) {
                completedBlock(nil, error, NIMImageCacheTypeNone, url);
            }
        });
    }
}

- (void)nim_setImageWithPreviousCachedImageWithURL:(NSURL *)url andPlaceholderImage:(UIImage *)placeholder options:(NIMWebImageOptions)options progress:(NIMWebImageDownloaderProgressBlock)progressBlock completed:(NIMWebImageCompletionBlock)completedBlock {
    NSString *key = [[NIMWebImageManager sharedManager] cacheKeyForURL:url];
    UIImage *lastPreviousCachedImage = [[NIMImageCache sharedImageCache] imageFromDiskCacheForKey:key];
    
    [self nim_setImageWithURL:url placeholderImage:lastPreviousCachedImage ?: placeholder options:options progress:progressBlock completed:completedBlock];
}

- (NSURL *)nim_imageURL {
    return objc_getAssociatedObject(self, &imageURLKey);
}


- (void)nim_cancelCurrentImageLoad {
    [self nim_cancelImageLoadOperationWithKey:@"UIImageViewImageLoad"];
}

- (void)nim_cancelCurrentAnimationImagesLoad {
    [self nim_cancelImageLoadOperationWithKey:@"UIImageViewAnimationImages"];
}


@end
