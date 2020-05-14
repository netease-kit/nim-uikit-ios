//
//  NSString+NIM.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NSString+NIMKit.h"
#import <CommonCrypto/CommonDigest.h>
#import "NIMKit.h"

@implementation NSString (NIMKit)

- (CGSize)nim_stringSizeWithFont:(UIFont *)font{
    return [self sizeWithAttributes:@{NSFontAttributeName:font}];
}

- (NSString *)nim_MD5String {
    const char *cstr = [self UTF8String];
    unsigned char result[16];
    CC_MD5(cstr, (CC_LONG)strlen(cstr), result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}


- (NSUInteger)nim_getBytesLength
{
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    return [self lengthOfBytesUsingEncoding:enc];
}


- (NSString *)nim_stringByDeletingPictureResolution{
    NSString *doubleResolution  = @"@2x";
    NSString *tribleResolution = @"@3x";
    NSString *fileName = self.stringByDeletingPathExtension;
    NSString *res = [self copy];
    if ([fileName hasSuffix:doubleResolution] || [fileName hasSuffix:tribleResolution]) {
        res = [fileName substringToIndex:fileName.length - 3];
        if (self.pathExtension.length) {
            res = [res stringByAppendingPathExtension:self.pathExtension];
        }
    }
    return res;
}


- (UIColor *)nim_hexToColor
{
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:self];
    //去掉#
    [scanner setScanLocation:1];
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

- (BOOL)nim_fileIsExist {
    NSFileManager *fm =[NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExist = (![fm fileExistsAtPath:self isDirectory:&isDir] || isDir);
    return isExist;
}

- (NSString *)nim_localized {
    NSString * result = [self nim_localizedWithTable:[NIMKit sharedKit].languageTable];
    return result;
}

- (NSString *)nim_localizedWithTable:(NSString *)table {
    NSBundle * languageBundle = [NIMKit sharedKit].languageBundle;
    return [self nim_localizedByBundle:languageBundle table:table];
}

- (NSString *)nim_localizedByBundle:(NSBundle *)bundle table:(NSString *)table {
    return NSLocalizedStringFromTableInBundle(self, nil, bundle, @"");
}

- (BOOL)nim_containsEmoji {
    __block BOOL returnValue =NO;
    [self enumerateSubstringsInRange:NSMakeRange(0, [self length]) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        const unichar hs = [substring characterAtIndex:0];
        // surrogate pair
        if (0xd800) {
            if (0xd800 <= hs && hs <= 0xdbff) {
                if (substring.length > 1) {
                    const unichar ls = [substring characterAtIndex:1];
                    const int uc = ((hs - 0xd800) * 0x400) + (ls - 0xdc00) + 0x10000;
                    if (0x1d000 <= uc && uc <= 0x1f77f) {
                        returnValue =YES;
                    }
                }
            }else if (substring.length > 1) {
                const unichar ls = [substring characterAtIndex:1];
                if (ls == 0x20e3) {
                    returnValue =YES;
                }
            }else {
                // non surrogate
                if (0x2100 <= hs && hs <= 0x27ff) {
                    returnValue =YES;
                }else if (0x2B05 <= hs && hs <= 0x2b07) {
                    returnValue =YES;
                }else if (0x2934 <= hs && hs <= 0x2935) {
                    returnValue =YES;
                }else if (0x3297 <= hs && hs <= 0x3299) {
                    returnValue =YES;
                }else if (hs == 0xa9 || hs == 0xae || hs == 0x303d || hs == 0x3030 || hs == 0x2b55 || hs == 0x2b1c || hs == 0x2b1b || hs == 0x2b50) {
                    returnValue =YES;
                }
            }
        }
    }];
    return returnValue;
}

- (NSRange)nim_rangeOfLastUnicode
{
    NSUInteger lastCharIndex = [self length] - 1;
    NSRange rangeOfLastChar = [self rangeOfComposedCharacterSequenceAtIndex:lastCharIndex];
    return rangeOfLastChar;
}

@end
