//
//  NSBundle+NIMKit.m
//  NIMKit
//
//  Created by Genning-Work on 2019/11/14.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "NSBundle+NIMKit.h"
#import "NIMKit.h"
#import "NIMInputEmoticonDefine.h"

@implementation NSBundle (NIMKit)

+ (NSBundle *)nim_defaultResourceBundle {
    NSBundle *bundle = [NSBundle bundleForClass:[NIMKit class]];
    NSURL *url = [bundle URLForResource:@"NIMKitResource" withExtension:@"bundle"];
    NSBundle *resourceBundle = [NSBundle bundleWithURL:url];
    return resourceBundle;
}

+ (NSString *)nim_ResourceImage:(NSString *)imageName {
    NSBundle *bundle = [NIMKit sharedKit].resourceBundle;
    NSString *ext = [imageName pathExtension];
    if (ext.length == 0) {
        ext = @"png";
    }
    NSString *name = [imageName stringByDeletingPathExtension];
    NSString *doubleImage  = [name stringByAppendingString:@"@2x"];
    NSString *tribleImage  = [name stringByAppendingString:@"@3x"];
    NSString *path = nil;
    if ([UIScreen mainScreen].scale == 3.0) {
        path = [bundle pathForResource:tribleImage ofType:ext];
    }
    path = path ? path : [bundle pathForResource:doubleImage ofType:ext]; //取二倍图
    path = path ? path : [bundle pathForResource:name ofType:ext]; //实在没了就去取一倍图
    return path;
}

+ (NSBundle *)nim_defaultEmojiBundle {
    NSBundle *bundle = [NSBundle bundleForClass:[NIMKit class]];
    NSURL *url = [bundle URLForResource:@"NIMKitEmoticon" withExtension:@"bundle"];
    NSBundle *emojiBundle = [NSBundle bundleWithURL:url];
    return emojiBundle;
}

+ (NSBundle *)nim_defaultLanguageBundle {
    NSBundle *bundle = [NSBundle bundleForClass:[NIMKit class]];
    NSURL *url = [bundle URLForResource:@"NIMLanguage"
                          withExtension:@"bundle"];
    
    NSBundle * languageBundle = nil;
    if (url)
    {
        languageBundle = [NSBundle bundleWithURL:url];
    }
    
    NSURL *projUrl = [languageBundle URLForResource:[self preferredLanguage]
                                      withExtension:@"lproj"];
    NSBundle * projBundle = nil;
    if (projUrl)
    {
        projBundle = [NSBundle bundleWithURL:projUrl];
    }
    return projBundle;
}

+ (NSString *)nim_EmojiPlistFile {
    NSBundle *bundle = [NIMKit sharedKit].emoticonBundle;
    NSString *filepath = [bundle pathForResource:@"emoji_ios" ofType:@"plist" inDirectory:NIMKit_EmojiPath];
    return filepath;
}

+ (NSString *)nim_EmojiImage:(NSString *)imageName {
    NSBundle *bundle = [NIMKit sharedKit].emoticonBundle;
    NSString *ext = [imageName pathExtension];
    if (ext.length == 0) {
        ext = @"png";
    }
    NSString *name = [imageName stringByDeletingPathExtension];
    NSString *doubleImage  = [name stringByAppendingString:@"@2x"];
    NSString *tribleImage  = [name stringByAppendingString:@"@3x"];
    NSString *path = nil;
    if ([UIScreen mainScreen].scale == 3.0) {
        path = [bundle pathForResource:tribleImage ofType:ext inDirectory:NIMKit_EmojiPath];
    }
    path = path ? path : [bundle pathForResource:doubleImage ofType:ext inDirectory:NIMKit_EmojiPath]; //取二倍图
    path = path ? path : [bundle pathForResource:name ofType:ext inDirectory:NIMKit_EmojiPath]; //实在没了就去取一倍图
    return path;
}

+ (NSString *)preferredLanguage
{
    NSString * preferredLanguage = [NSLocale preferredLanguages].firstObject;
    
    if ([preferredLanguage rangeOfString:@"zh-Hans"].location != NSNotFound) {
        preferredLanguage = @"zh";
    } else {
        preferredLanguage = @"en";
    }
    
    return preferredLanguage;
}


@end
