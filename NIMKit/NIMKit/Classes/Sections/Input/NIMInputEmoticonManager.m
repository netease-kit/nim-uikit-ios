//
//  NTESEmoticonManager.h
//  NIM
//
//  Created by amao on 7/2/14.
//  Copyright (c) 2014 Netease. All rights reserved.
//

#import "NIMInputEmoticonManager.h"
#import "NIMInputEmoticonDefine.h"
#import "NSString+NIMKit.h"
#import "NIMKit.h"

@implementation NIMInputEmoticon
@end

@implementation NIMInputEmoticonCatalog
@end

@implementation NIMInputEmoticonLayout

- (id)initEmojiLayout:(CGFloat)width
{
    self = [super init];
    if (self)
    {
        _rows            = NIMKit_EmojRows;
        _columes         = ((width - NIMKit_EmojiLeftMargin - NIMKit_EmojiRightMargin) / NIMKit_EmojImageWidth);
        _itemCountInPage = _rows * _columes -1;
        _cellWidth       = (width - NIMKit_EmojiLeftMargin - NIMKit_EmojiRightMargin) / _columes;
        _cellHeight      = NIMKit_EmojCellHeight;
        _imageWidth      = NIMKit_EmojImageWidth;
        _imageHeight     = NIMKit_EmojImageHeight;
        _emoji           = YES;
    }
    return self;
}

- (id)initCharletLayout:(CGFloat)width{
    self = [super init];
    if (self)
    {
        _rows            = NIMKit_PicRows;
        _columes         = ((width - NIMKit_EmojiLeftMargin - NIMKit_EmojiRightMargin) / NIMKit_PicImageWidth);
        _itemCountInPage = _rows * _columes;
        _cellWidth       = (width - NIMKit_EmojiLeftMargin - NIMKit_EmojiRightMargin) / _columes;
        _cellHeight      = NIMKit_PicCellHeight;
        _imageWidth      = NIMKit_PicImageWidth;
        _imageHeight     = NIMKit_PicImageHeight;
        _emoji           = NO;
    }
    return self;
}

@end

@interface NIMInputEmoticonManager ()
@property (nonatomic,strong)    NSArray *catalogs;
@end

@implementation NIMInputEmoticonManager
+ (instancetype)sharedManager
{
    static NIMInputEmoticonManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NIMInputEmoticonManager alloc]init];
    });
    return instance;
}

- (id)init
{
    if (self = [super init])
    {
        [self parsePlist];
    }
    return self;
}

- (NIMInputEmoticonCatalog *)emoticonCatalog:(NSString *)catalogID
{
    for (NIMInputEmoticonCatalog *catalog in _catalogs)
    {
        if ([catalog.catalogID isEqualToString:catalogID])
        {
            return catalog;
        }
    }
    return nil;
}


- (NIMInputEmoticon *)emoticonByTag:(NSString *)tag
{
    NIMInputEmoticon *emoticon = nil;
    if ([tag length])
    {
        for (NIMInputEmoticonCatalog *catalog in _catalogs)
        {
            emoticon = [catalog.tag2Emoticons objectForKey:tag];
            if (emoticon)
            {
                break;
            }
        }
    }
    return emoticon;
}


- (NIMInputEmoticon *)emoticonByID:(NSString *)emoticonID
{
    NIMInputEmoticon *emoticon = nil;
    if ([emoticonID length])
    {
        for (NIMInputEmoticonCatalog *catalog in _catalogs)
        {
            emoticon = [catalog.id2Emoticons objectForKey:emoticonID];
            if (emoticon)
            {
                break;
            }
        }
    }
    return emoticon;
}

- (NIMInputEmoticon *)emoticonByCatalogID:(NSString *)catalogID
                           emoticonID:(NSString *)emoticonID
{
    NIMInputEmoticon *emoticon = nil;
    if ([emoticonID length] && [catalogID length])
    {
        for (NIMInputEmoticonCatalog *catalog in _catalogs)
        {
            if ([catalog.catalogID isEqualToString:catalogID])
            {
                emoticon = [catalog.id2Emoticons objectForKey:emoticonID];
                break;
            }
        }
    }
    return emoticon;
}

- (void)parsePlist
{
    NSMutableArray *catalogs = [NSMutableArray array];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:[[NIMKit sharedKit] emoticonBundleName]
                                         withExtension:nil];
    NSBundle *bundle = [NSBundle bundleWithURL:url];
    
    NSString *filepath = [bundle pathForResource:@"emoji" ofType:@"plist" inDirectory:NIMKit_EmojiPath];
    if (filepath) {
        NSArray *array = [NSArray arrayWithContentsOfFile:filepath];
        for (NSDictionary *dict in array)
        {
            NSDictionary *info = dict[@"info"];
            NSArray *emoticons = dict[@"data"];
            
            NIMInputEmoticonCatalog *catalog = [self catalogByInfo:info
                                                     emoticons:emoticons];
            [catalogs addObject:catalog];
        }
    }
    _catalogs = catalogs;
}

- (NIMInputEmoticonCatalog *)catalogByInfo:(NSDictionary *)info
                             emoticons:(NSArray *)emoticonsArray
{
    NIMInputEmoticonCatalog *catalog = [[NIMInputEmoticonCatalog alloc]init];
    catalog.catalogID   = info[@"id"];
    catalog.title       = info[@"title"];
    NSString *iconNamePrefix = NIMKit_EmojiPath;
    NSString *icon      = info[@"normal"];
    catalog.icon = [iconNamePrefix stringByAppendingPathComponent:icon];
    NSString *iconPressed = info[@"pressed"];
    catalog.iconPressed = [iconNamePrefix stringByAppendingPathComponent:iconPressed];

    
    NSMutableDictionary *tag2Emoticons = [NSMutableDictionary dictionary];
    NSMutableDictionary *id2Emoticons = [NSMutableDictionary dictionary];
    NSMutableArray *emoticons = [NSMutableArray array];
    
    for (NSDictionary *emoticonDict in emoticonsArray) {
        NIMInputEmoticon *emoticon  = [[NIMInputEmoticon alloc] init];
        emoticon.emoticonID     = emoticonDict[@"id"];
        emoticon.tag            = emoticonDict[@"tag"];
        NSString *fileName      = emoticonDict[@"file"];
        NSString *imageNamePrefix = NIMKit_EmojiPath;
        
        emoticon.filename = [imageNamePrefix stringByAppendingPathComponent:fileName];
        if (emoticon.emoticonID) {
            [emoticons addObject:emoticon];
            id2Emoticons[emoticon.emoticonID] = emoticon;
        }
        if (emoticon.tag) {
            tag2Emoticons[emoticon.tag] = emoticon;
        }
    }
    
    catalog.emoticons       = emoticons;
    catalog.id2Emoticons    = id2Emoticons;
    catalog.tag2Emoticons   = tag2Emoticons;
    return catalog;
}


@end
