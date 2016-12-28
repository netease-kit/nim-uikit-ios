//
//  NIMPinyinConverter.m
//  NIM
//
//  Created by amao on 10/15/13.
//  Copyright (c) 2013 Netease. All rights reserved.
//

#import "NIMPinyinConverter.h"

@interface NIMPinyinConverter ()
{
    int     *_codeIndex;
    char    *_pinyin;
    BOOL    _inited;
}
@end

@implementation NIMPinyinConverter
+ (NIMPinyinConverter *)sharedInstance
{
    static NIMPinyinConverter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NIMPinyinConverter alloc] init];
    });
    return instance;
}

- (NSString *)toPinyin: (NSString *)source
{
    if ([source length] == 0)
    {
        return nil;
    }
    NSMutableString *mutableString = [NSMutableString stringWithString:source];
    CFStringTransform((CFMutableStringRef)mutableString, NULL, kCFStringTransformToLatin, false);
    mutableString = (NSMutableString *)[mutableString stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:[NSLocale currentLocale]];
    return [mutableString stringByReplacingOccurrencesOfString:@"'" withString:@""];
}




@end
