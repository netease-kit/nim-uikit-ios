//
//  NIMMediaItem.h
//  NIMKit
//
//  Created by amao on 8/11/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NIMMediaItem : NSObject

@property (nonatomic,assign)    SEL selctor;

@property (nonatomic,strong)    UIImage *normalImage;

@property (nonatomic,strong)    UIImage *selectedImage;

@property (nonatomic,copy)      NSString *title;

+ (NIMMediaItem *)item:(NSString *)selector
           normalImage:(UIImage  *)normalImage
         selectedImage:(UIImage  *)selectedImage
                 title:(NSString *)title;
@end
