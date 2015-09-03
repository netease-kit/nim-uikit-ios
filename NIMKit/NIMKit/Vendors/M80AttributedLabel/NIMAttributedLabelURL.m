//
//  NIMAttributedLabelURL.m
//  NIMAttributedLabel
//
//  Created by amao on 13-8-31.
//  Copyright (c) 2013年 www.xiangwangfeng.com. All rights reserved.
//

#import "NIMAttributedLabelURL.h"

static NSString *urlExpression = @"((([A-Za-z]{3,9}:(?:\\/\\/)?)(?:[\\-;:&=\\+\\$,\\w]+@)?[A-Za-z0-9\\.\\-]+|(?:www\\.|[\\-;:&=\\+\\$,\\w]+@)[A-Za-z0-9\\.\\-]+)((:[0-9]+)?)((?:\\/[\\+~%\\/\\.\\w\\-]*)?\\??(?:[\\-\\+=&;%@\\.\\w]*)#?(?:[\\.\\!\\/\\\\\\w]*))?)";

static NIMCustomDetectLinkBlock customDetectBlock = nil;

@implementation NIMAttributedLabelURL

+ (NIMAttributedLabelURL *)urlWithLinkData: (id)linkData
                                     range: (NSRange)range
                                     color: (UIColor *)color
{
    NIMAttributedLabelURL *url  = [[NIMAttributedLabelURL alloc]init];
    url.linkData                = linkData;
    url.range                   = range;
    url.color                   = color;
    return url;
    
}


+ (NSArray *)detectLinks: (NSString *)plainText
{
    //提供一个自定义的解析接口给
    if (customDetectBlock)
    {
        return customDetectBlock(plainText);
    }
    else
    {
        NSMutableArray *links = nil;
        if ([plainText length])
        {
            links = [NSMutableArray array];
            NSRegularExpression *urlRegex = [NSRegularExpression regularExpressionWithPattern:urlExpression
                                                                                      options:NSRegularExpressionCaseInsensitive
                                                                                        error:nil];
            [urlRegex enumerateMatchesInString:plainText
                                       options:0
                                         range:NSMakeRange(0, [plainText length])
                                    usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                        NSRange range = result.range;
                                        NSString *text = [plainText substringWithRange:range];
                                        NIMAttributedLabelURL *link = [NIMAttributedLabelURL urlWithLinkData:text
                                                                                                       range:range
                                                                                                       color:nil];
                                        [links addObject:link];
                                    }];
        }
        return links;
    }
}

+ (void)setCustomDetectMethod:(NIMCustomDetectLinkBlock)block
{
    customDetectBlock = [block copy];
}

@end
