//
//  NTESFileLocationHelper.m
//  NIM
//
//  Created by chris on 15/4/12.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESFileLocationHelper.h"
#import <sys/stat.h>
#import "NTESDemoConfig.h"

#define RDVideo    (@"video")
#define RDImage    (@"image")

@interface NTESFileLocationHelper ()
+ (NSString *)filepathForDir: (NSString *)dirname filename: (NSString *)filename;
@end


@implementation NTESFileLocationHelper
+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue:@(YES)
                                  forKey:NSURLIsExcludedFromBackupKey
                                   error:&error];
    if(!success)
    {
        DDLogError(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    return success;
    
}
+ (NSString *)getAppDocumentPath
{
    static NSString *appDocumentPath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *appKey = [[NTESDemoConfig sharedConfig] appKey];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        appDocumentPath= [[NSString alloc]initWithFormat:@"%@/%@/",[paths objectAtIndex:0],appKey];
        if (![[NSFileManager defaultManager] fileExistsAtPath:appDocumentPath])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:appDocumentPath
                                      withIntermediateDirectories:NO
                                                       attributes:nil
                                                            error:nil];
        }
        [NTESFileLocationHelper addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:appDocumentPath]];
    });
    return appDocumentPath;
    
}

+ (NSString *)getAppTempPath
{
    return NSTemporaryDirectory();
}

+ (NSString *)userDirectory
{
    NSString *documentPath = [NTESFileLocationHelper getAppDocumentPath];
    NSString *userID = [NIMSDK sharedSDK].loginManager.currentAccount;
    if ([userID length] == 0)
    {
        DDLogError(@"Error: Get User Directory While UserID Is Empty");
    }
    NSString* userDirectory= [NSString stringWithFormat:@"%@%@/",documentPath,userID];
    if (![[NSFileManager defaultManager] fileExistsAtPath:userDirectory])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:userDirectory
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:nil];

    }
    return userDirectory;
}

+ (NSString *)resourceDir: (NSString *)resouceName
{
    NSString *dir = [[NTESFileLocationHelper userDirectory] stringByAppendingPathComponent:resouceName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:nil];
    }
    return dir;
}


+ (NSString *)filepathForVideo:(NSString *)filename
{
    return [NTESFileLocationHelper filepathForDir:RDVideo
                                     filename:filename];
}

+ (NSString *)filepathForImage:(NSString *)filename
{
    return [NTESFileLocationHelper filepathForDir:RDImage
                                     filename:filename];
}

+ (NSString *)genFilenameWithExt:(NSString *)ext
{
    CFUUIDRef uuid = CFUUIDCreate(nil);
    NSString *uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(nil, uuid);
    CFRelease(uuid);
    NSString *uuidStr = [[uuidString stringByReplacingOccurrencesOfString:@"-" withString:@""] lowercaseString];
    NSString *name = [NSString stringWithFormat:@"%@",uuidStr];
    return [ext length] ? [NSString stringWithFormat:@"%@.%@",name,ext]:name;
}


#pragma mark - 辅助方法
+ (NSString *)filepathForDir:(NSString *)dirname
                    filename:(NSString *)filename
{
    return [[NTESFileLocationHelper resourceDir:dirname] stringByAppendingPathComponent:filename];
}

@end
