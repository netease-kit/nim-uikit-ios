//
//  NTESLoginManager.m
//  NIM
//
//  Created by amao on 5/26/15.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import "NTESLoginManager.h"
#import "NTESFileLocationHelper.h"


#define NIMAccount      @"account"
#define NIMToken        @"token"

@interface LoginData ()<NSCoding>

@end

@implementation LoginData

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _account = [aDecoder decodeObjectForKey:NIMAccount];
        _token = [aDecoder decodeObjectForKey:NIMToken];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    if ([_account length]) {
        [encoder encodeObject:_account forKey:NIMAccount];
    }
    if ([_token length]) {
        [encoder encodeObject:_token forKey:NIMToken];
    }
}
@end

@interface NTESLoginManager ()
@property (nonatomic,copy)  NSString    *filepath;
@end

@implementation NTESLoginManager

+ (instancetype)sharedManager
{
    static NTESLoginManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *filepath = [[NTESFileLocationHelper getAppDocumentPath] stringByAppendingPathComponent:@"nim_sdk_login_data"];
        instance = [[NTESLoginManager alloc] initWithPath:filepath];
    });
    return instance;
}


- (instancetype)initWithPath:(NSString *)filepath
{
    if (self = [super init])
    {
        _filepath = filepath;
        [self readData];
    }
    return self;
}


- (void)setCurrentLoginData:(LoginData *)currentLoginData
{
    _currentLoginData = currentLoginData;
    [self saveData];
}

//从文件中读取和保存用户名密码,建议上层开发对这个地方做加密,DEMO只为了做示范,所以没加密
- (void)readData
{
    NSString *filepath = [self filepath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filepath])
    {
        id object = [NSKeyedUnarchiver unarchiveObjectWithFile:filepath];
        _currentLoginData = [object isKindOfClass:[LoginData class]] ? object : nil;
    }
}

- (void)saveData
{
    NSData *data = [NSData data];
    if (_currentLoginData)
    {
        data = [NSKeyedArchiver archivedDataWithRootObject:_currentLoginData];
    }
    [data writeToFile:[self filepath] atomically:YES];
}


@end
