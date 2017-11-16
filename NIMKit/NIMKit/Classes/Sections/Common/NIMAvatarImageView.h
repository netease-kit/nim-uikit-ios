//
//  NIMAvatarImageView.h
//  NIMKit
//
//  Created by chris on 15/2/10.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <NIMSDK/NIMSDK.h>
#import "NIMKitDependency.h"

@interface NIMAvatarImageView : UIControl
@property (nonatomic,strong)    UIImage *image;
@property (nonatomic,assign)    CGFloat cornerRadius;

- (void)setAvatarBySession:(NIMSession *)session;
- (void)setAvatarByMessage:(NIMMessage *)message;
@end


@interface NIMAvatarImageView (SDWebImageCache)
- (NSURL *)nim_imageURL;

- (void)nim_setImageWithURL:(NSURL *)url;
- (void)nim_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder;
- (void)nim_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options;
- (void)nim_setImageWithURL:(NSURL *)url completed:(SDExternalCompletionBlock)completedBlock;
- (void)nim_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDExternalCompletionBlock)completedBlock;
- (void)nim_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options completed:(SDExternalCompletionBlock)completedBlock;
- (void)nim_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDExternalCompletionBlock)completedBlock;
- (void)nim_setImageWithPreviousCachedImageWithURL:(NSURL *)url andPlaceholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDExternalCompletionBlock)completedBlock;
- (void)nim_cancelCurrentImageLoad;
- (void)nim_cancelCurrentAnimationImagesLoad;
@end
