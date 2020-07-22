//
//  NIMKitCommentUtil.m
//  NIMKit
//
//  Created by He on 2020/4/14.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import "NIMKitQuickCommentUtil.h"
#import "M80AttributedLabel+NIMKit.h"
#import "NIMKitUtil.h"
#import "UIView+NIM.h"
#import "NIMInputEmoticonManager.h"
#import "NIMKit.h"
#import "NIMKitInfoFetchOption.h"

static const CGFloat kHeightPerRow = 25.0;
static NSInteger kMaxWidthPerRow = 0;
const CGFloat NIMKitCommentUtilCellPadding = 2.f;
const CGFloat NIMKitCommentUtilCellContentPadding = 5.f;
NSString  * const NIMKitQuickCommentFormat = @"emoticon_emoji_%02ld";


@implementation NIMKitQuickCommentUtil

+ (void)initialize
{
    kMaxWidthPerRow = [UIScreen mainScreen].bounds.size.width * 3.5 / 5;
}

+ (UIFont *)commentFont
{
    static dispatch_once_t onceToken;
    static UIFont *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [UIFont systemFontOfSize:13];
    });
    return instance;
}

+ (M80AttributedLabel *)newCommentLabel
{
    M80AttributedLabel *textLabel = [[M80AttributedLabel alloc] init];
    textLabel.backgroundColor = [UIColor clearColor];
    textLabel.numberOfLines = 1;
    textLabel.textAlignment = kCTTextAlignmentLeft;
    textLabel.font = [self commentFont];
    textLabel.lineBreakMode = kCTLineBreakByTruncatingTail;
    return textLabel;
}

+ (NSString *)commentContent:(NIMQuickComment *)comment
{
    NSString *ID = [NSString stringWithFormat:NIMKitQuickCommentFormat, (long)comment.replyType];
    NIMInputEmoticon *emoticon = [[NIMInputEmoticonManager sharedManager] emoticonByID:ID];
    NSString *content = nil;
    if (emoticon)
    {
        if (emoticon.type == NIMEmoticonTypeUnicode) {
            content = emoticon.unicode;
        } else {
            content = emoticon.tag;
        }
    }
    content = [NSString stringWithFormat:@"%@", content.length ? content : @"[?]".nim_localized];
    return content;
}

+ (NSString *)commentsContent:(NSArray<NIMQuickComment *> *)comments
{
    NSString *currentAccount = [[NIMSDK sharedSDK].loginManager currentAccount];
    NIMQuickComment *firstComment = comments.firstObject;
    for (NIMQuickComment *comment in comments)
    {
        if ([currentAccount isEqualToString:comment.from])
        {
            firstComment = comment;
            break;
        }
    }
    
    NSMutableString *string = [NSMutableString string];
    NSString *fristShowName = [self showNameWithCommentFrom:firstComment];
    [string appendFormat:@"%@  %@", [self commentContent:firstComment], fristShowName];
    if (comments.count > 1)
    {
        [string appendFormat:@" 等%zd人", comments.count];
    }
    return [string copy];
}

+ (CGSize)itemSizeWithComment:(NIMQuickComment *)comment
{
    static M80AttributedLabel *label = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        label = [self newCommentLabel];
    });
    
    [label nim_setText:[self commentContent:comment]];
    CGSize size = [label sizeThatFits:CGSizeMake(kMaxWidthPerRow, kHeightPerRow)];
    return CGSizeMake(size.width + NIMKitCommentUtilCellContentPadding * 2, kHeightPerRow);
}

+ (CGSize)itemSizeWithComments:(NSArray<NIMQuickComment *> *)comments
{
    if (comments.count == 0)
    {
        return CGSizeZero;
    }
    
    static M80AttributedLabel *label = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        label = [self newCommentLabel];
    });
    
    [label nim_setText:[self commentsContent:comments]];
    CGSize size = [label sizeThatFits:CGSizeMake(kMaxWidthPerRow, kHeightPerRow)];
    return CGSizeMake(size.width + NIMKitCommentUtilCellContentPadding * 2, kHeightPerRow);
}

+ (CGSize)containerSizeWithComments:(NSMapTable *)table
{
    NSArray *keys = [self sortedKeys:table];
    
    CGFloat sumWidth = 0;
    CGFloat maxWidth = sumWidth;
    NSInteger row = 1;
    for (NSNumber *key in keys)
    {
        NSArray<NIMQuickComment *> *comments = [table objectForKey:key];
        if (!comments)
        {
            continue;
        }
        
        CGSize size = [self itemSizeWithComments:comments];
        if (sumWidth + size.width + NIMKitCommentUtilCellPadding * 2 >= kMaxWidthPerRow)
        {
            row ++;
            sumWidth = NIMKitCommentUtilCellPadding + size.width;
        }
        else
        {
            sumWidth += NIMKitCommentUtilCellPadding + size.width;
        }
        
        if (maxWidth < sumWidth)
        {
            maxWidth = sumWidth;
        }
    }
    
    maxWidth += NIMKitCommentUtilCellPadding;
    
    return CGSizeMake(maxWidth, row * kHeightPerRow + (row + 1) * NIMKitCommentUtilCellPadding);
}

+ (NIMQuickComment *)myCommentFromComments:(NSInteger )indexPath
                                      keys:(NSArray *)keys
                                  comments:(NSMapTable *)map
{
    NSNumber *number = [keys objectAtIndex:indexPath];
    NSArray *comments = [map objectForKey:number];
    NSString *currentAcount = [[NIMSDK sharedSDK].loginManager currentAccount];
    NIMQuickComment * mine = nil;
    for (NIMQuickComment *comment in comments)
    {
        if ([comment.from isEqualToString:currentAcount])
        {
            mine = comment;
            break;
        }
    }
    return mine;
}

+ (NSString *)showNameWithCommentFrom:(NIMQuickComment *)comment
{
    NIMKitInfo *info = nil;
    NIMChatExtendBasicInfo *basicInfo = comment.basicInfo;
    NIMSession *session = basicInfo.session;
    NIMKitInfoFetchOption *option = [[NIMKitInfoFetchOption alloc] init];
    option.session = session;
    info = [[NIMKit sharedKit] infoByUser:comment.from option:option];

    return info.showName;
}

+ (NSArray *)sortedKeys:(NSMapTable<NSNumber *, NIMQuickComment *> *)map
{
    NSArray *keys = [map.keyEnumerator.allObjects sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
               NSArray *array1 = (NSArray *)[map objectForKey:obj1];
               NIMQuickComment *comment1 = [array1 lastObject];
               
               NSArray *array2 = (NSArray *)[map objectForKey:obj2];
               NIMQuickComment *comment2 = [array2 lastObject];
               
               if (comment1.timestamp > comment2.timestamp)
               {
                   return NSOrderedDescending;
               }
               else if (comment1.timestamp == comment2.timestamp)
               {
                   return NSOrderedSame;
               }
               else
               {
                   return NSOrderedAscending;
               }
           }];
    return keys;
}

@end
