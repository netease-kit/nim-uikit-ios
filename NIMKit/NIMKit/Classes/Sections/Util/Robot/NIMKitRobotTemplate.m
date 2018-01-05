//
//  NIMKitRobotTemplate.m
//  NIMKit
//
//  Created by chris on 2017/6/25.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import "NIMKitRobotTemplate.h"

@implementation NIMKitRobotTemplate

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _items = [[NSMutableArray alloc] init];
    }
    return self;
}


-(void)setValue:(id)value forUndefinedKey:(nonnull NSString *)key{
    if ([key isEqualToString:@"id"]) {
        self.templateId = value;
    }
}


- (nullable id)valueForUndefinedKey:(NSString *)key{
    return nil;
}

@end
