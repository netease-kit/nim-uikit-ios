//
//  UIImage+MultiFormat.h
//  NIMWebImage
//
//  Created by Olivier Poitrey on 07/06/13.
//  Copyright (c) 2013 Dailymotion. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (NIMMultiFormat)

+ (UIImage *)nim_imageWithData:(NSData *)data;

@end
