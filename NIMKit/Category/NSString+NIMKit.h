//
//  NSString+NIM.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSString (NIMKit)

- (CGSize)nim_stringSizeWithFont:(UIFont *)font;

- (NSString *)nim_MD5String;

- (NSUInteger)nim_getBytesLength;

- (NSString *)nim_stringByDeletingPictureResolution;

- (UIColor *)nim_hexToColor;

@end
