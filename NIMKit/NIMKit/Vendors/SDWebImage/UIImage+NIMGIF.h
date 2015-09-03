//
//  UIImage+GIF.h
//  LBGIFImage
//
//  Created by Laurin Brandner on 06.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (NIMGIF)

+ (UIImage *)nim_animatedGIFNamed:(NSString *)name;

+ (UIImage *)nim_animatedGIFWithData:(NSData *)data;

- (UIImage *)nim_animatedImageByScalingAndCroppingToSize:(CGSize)size;

@end
