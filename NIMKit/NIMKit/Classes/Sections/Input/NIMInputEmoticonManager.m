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
#import "UIImage+NIMKit.h"
#import "NSBundle+NIMKit.h"

@implementation NIMInputEmoticon

- (NIMEmoticonType)type {
    if (_unicode.length) {
        return NIMEmoticonTypeUnicode;
    } else {
        return NIMEmoticonTypeFile;
    }
}

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
        [self preloadEmoticonResource];
    }
    return self;
}

- (void)start {};

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
    NSString *filepath = [NSBundle nim_EmojiPlistFile];
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
    catalog.catalogID = info[@"id"];
    catalog.title     = info[@"title"];
    catalog.icon      = info[@"normal"];
    catalog.iconPressed = info[@"pressed"];
    NSMutableDictionary *tag2Emoticons = [NSMutableDictionary dictionary];
    NSMutableDictionary *id2Emoticons = [NSMutableDictionary dictionary];
    NSMutableArray *emoticons = [NSMutableArray array];
    
    for (NSDictionary *emoticonDict in emoticonsArray) {
        NIMInputEmoticon *emoticon  = [[NIMInputEmoticon alloc] init];
        emoticon.emoticonID     = emoticonDict[@"id"];
        emoticon.tag            = emoticonDict[@"tag"];
        emoticon.unicode        = emoticonDict[@"unicode"];
        emoticon.filename       = emoticonDict[@"file"];
        
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

- (void)preloadEmoticonResource {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (NIMInputEmoticonCatalog *catalog in _catalogs) {
            [catalog.emoticons enumerateObjectsUsingBlock:^(NIMInputEmoticon  *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.filename) {
                   __unused UIImage *image = [UIImage nim_emoticonInKit:obj.filename];
                }
            }];
        }
    });
}

@end
