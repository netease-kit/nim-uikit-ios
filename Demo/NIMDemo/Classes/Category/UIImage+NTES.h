//
//  UIImage+NTES.h
//  NIM
//
//  Created by chris on 15/7/13.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (NTES)

+ (UIImage *)fetchImage:(NSString *)imageNameOrPath;

+ (UIImage *)fetchChartlet:(NSString *)imageName chartletId:(NSString *)chartletId;

- (UIImage *)imageForAvatarUpload;

@end
