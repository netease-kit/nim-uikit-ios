//
//  NSDictionary+NIMKit.h
//  NIMKit
//
//  Created by chris on 2017/6/27.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (NIMKit)

- (NSString *)nimkit_jsonString: (NSString *)key;

- (NSDictionary *)nimkit_jsonDict: (NSString *)key;
- (NSArray *)nimkit_jsonArray: (NSString *)key;
- (NSArray *)nimkit_jsonStringArray: (NSString *)key;


- (BOOL)nimkit_jsonBool: (NSString *)key;
- (NSInteger)nimkit_jsonInteger: (NSString *)key;
- (long long)nimkit_jsonLongLong: (NSString *)key;
- (unsigned long long)nimkit_jsonUnsignedLongLong:(NSString *)key;

- (double)nimkit_jsonDouble: (NSString *)key;

@end
