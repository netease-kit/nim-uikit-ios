//
//  NIMPinyinConverter.m
//  NIM
//
//  Created by amao on 10/15/13.
//  Copyright (c) 2013 Netease. All rights reserved.
//

#import "NIMPinyinConverter.h"

#define kHanziMin       0x4E00
#define kHanziMax       0x9FA5

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

- (id)init
{
    _codeIndex = NULL;
    _pinyin = NULL;
    
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"pinyin"
                                                         ofType:@"bin"];
    if (filepath)
    {
        while (true)
        {
            FILE *fp = fopen([filepath UTF8String], "rb");
            if (fp)
            {
                int hanZiNumber = 0,pinyinSize = 0;
                size_t size = fread(&hanZiNumber, 4, 1, fp);
                if (size != 1)
                {
                    assert(0);
                    break;
                }
                size = fread(&pinyinSize, 4, 1, fp);
                if (size != 1)
                {
                    assert(0);
                    break;
                }
                
                if (hanZiNumber != kHanziMax - kHanziMin + 1)
                {
                    assert(0);
                }
                
                _codeIndex = (int*)calloc(hanZiNumber, sizeof(int));
                _pinyin = (char*)calloc(pinyinSize, sizeof(char));
                
                size = fread(_codeIndex, 4, hanZiNumber, fp);
                if (size != hanZiNumber)
                {
                    break;
                }
                size = fread(_pinyin, 1, pinyinSize, fp);
                if (size != pinyinSize)
                {
                    break;
                }
                fclose(fp);
                _inited = YES;
            }
            else
            {
                assert(0);
            }
            break;
        }

    }
    return self;
}


- (NSString *)pinyin: (unichar)p
{
    if (p >= kHanziMin && p <= kHanziMax)
    {
        return [NSString stringWithUTF8String:_pinyin + _codeIndex[p - kHanziMin]] ;
    }
    else
    {
        return [[NSString alloc]initWithCharacters:&p length:1];
    }
}


- (NSString *)toPinyin: (NSString *)source
{
    if ([source length] == 0 || !_inited)
    {
        return @"";
    }
    NSMutableString *pinyin = [[NSMutableString alloc] init];
    for (NSInteger i = 0; i < [source length]; i++)
    {
        unichar p =  [source characterAtIndex:i];
        [pinyin appendString:[self pinyin:p]];
    }
    return pinyin;
}



@end
