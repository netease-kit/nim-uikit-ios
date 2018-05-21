//
//  NSDictionary+NIMKit.m
//  NIMKit
//
//  Created by chris on 2017/6/27.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import "NSDictionary+NIMKit.h"

@implementation NSDictionary (NIMKit)

- (NSString *)nimkit_jsonString: (NSString *)key
{
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSString class]])
    {
        return object;
    }
    else if([object isKindOfClass:[NSNumber class]])
    {
        return [object stringValue];
    }
    return nil;
}

- (NSDictionary *)nimkit_jsonDict: (NSString *)key
{
    id object = [self objectForKey:key];
    return [object isKindOfClass:[NSDictionary class]] ? object : nil;
}


- (NSArray *)nimkit_jsonArray: (NSString *)key
{
    id object = [self objectForKey:key];
    return [object isKindOfClass:[NSArray class]] ? object : nil;
    
}

- (NSArray *)nimkit_jsonStringArray: (NSString *)key
{
    NSArray *array = [self nimkit_jsonArray:key];
    BOOL invalid = NO;
    for (id item in array)
    {
        if (![item isKindOfClass:[NSString class]])
        {
            invalid = YES;
        }
    }
    return invalid ? nil : array;
}

- (BOOL)nimkit_jsonBool: (NSString *)key
{
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSString class]] ||
        [object isKindOfClass:[NSNumber class]])
    {
        return [object boolValue];
    }
    return NO;
}

- (NSInteger)nimkit_jsonInteger: (NSString *)key
{
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSString class]] ||
        [object isKindOfClass:[NSNumber class]])
    {
        return [object integerValue];
    }
    return 0;
}

- (long long)nimkit_jsonLongLong: (NSString *)key
{
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSString class]] ||
        [object isKindOfClass:[NSNumber class]])
    {
        return [object longLongValue];
    }
    return 0;
}

- (unsigned long long)nimkit_jsonUnsignedLongLong:(NSString *)key
{
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSString class]] ||
        [object isKindOfClass:[NSNumber class]])
    {
        return [object unsignedLongLongValue];
    }
    return 0;
}


- (double)nimkit_jsonDouble: (NSString *)key{
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSString class]] ||
        [object isKindOfClass:[NSNumber class]])
    {
        return [object doubleValue];
    }
    return 0;
}


@end
