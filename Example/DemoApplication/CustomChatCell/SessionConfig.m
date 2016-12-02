//
//  SessionConfig.m
//  DemoApplication
//
//  Created by chris on 15/11/1.
//  Copyright © 2015年 chris. All rights reserved.
//

#import "SessionConfig.h"
#import "NIMMediaItem.h"
#import "CellLayoutConfig.h"

@implementation SessionConfig

- (NSArray *)mediaItems{
    NIMMediaItem* custom =
             [NIMMediaItem item:@"sendCustomMessage"
                    normalImage:[UIImage imageNamed:@"icon_custom_normal"]
                  selectedImage:[UIImage imageNamed:@"icon_custom_pressed"]
                          title:@"自定义消息"];
    return @[custom];
}

- (BOOL)disableCharlet
{
    return YES;
}


@end
