//
//  NIMMediaItem.m
//  NIMKit
//
//  Created by amao on 8/11/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import "NIMMediaItem.h"

@implementation NIMMediaItem

+ (NIMMediaItem *)item:(NSInteger)tag
           normalImage:(UIImage *)normalImage
         selectedImage:(UIImage *)selectedImage
                 title:(NSString *)title
{
    NIMMediaItem *item  = [[NIMMediaItem alloc] init];
    item.tag            = tag;
    item.normalImage    = normalImage;
    item.selectedImage  = selectedImage;
    item.title          = title;
    return item;
}

@end
