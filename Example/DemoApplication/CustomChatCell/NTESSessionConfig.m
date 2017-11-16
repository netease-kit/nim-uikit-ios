//
//  NTESSessionConfig.m
//  DemoApplication
//
//  Created by chris on 15/11/1.
//  Copyright © 2015年 chris. All rights reserved.
//

#import "NTESSessionConfig.h"
#import "NIMMediaItem.h"
#import "NTESCellLayoutConfig.h"

@implementation NTESSessionConfig

- (NSArray *)mediaItems{
    NSArray *defaultMediaItems = [NIMKit sharedKit].config.defaultMediaItems;
    NIMMediaItem* custom =
             [NIMMediaItem item:@"sendCustomMessage"
                    normalImage:[UIImage imageNamed:@"icon_custom_normal"]
                  selectedImage:[UIImage imageNamed:@"icon_custom_pressed"]
                          title:@"自定义消息"];
    return [defaultMediaItems arrayByAddingObject:custom];
}

- (BOOL)disableCharlet
{
    return YES;
}


@end
