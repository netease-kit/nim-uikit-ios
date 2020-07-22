//
//  NIMKitCommentUtil.h
//  NIMKit
//
//  Created by He on 2020/4/14.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NIMQuickComment;
@class M80AttributedLabel;
NS_ASSUME_NONNULL_BEGIN

extern const CGFloat NIMKitCommentUtilCellPadding;

extern const CGFloat NIMKitCommentUtilCellContentPadding;

extern NSString * const NIMKitQuickCommentFormat;


@interface NIMKitQuickCommentUtil : NSObject

+ (UIFont *)commentFont;

+ (NSString *)commentContent:(NIMQuickComment *)comment;

+ (NSString *)commentsContent:(NSArray<NIMQuickComment *> *)comments;

+ (CGSize)itemSizeWithComment:(NIMQuickComment *)comment;

+ (CGSize)itemSizeWithComments:(NSArray<NIMQuickComment *> *)comments;

+ (CGSize)containerSizeWithComments:(NSMapTable *)comments;

+ (NIMQuickComment * _Nullable)myCommentFromComments:(NSInteger )keyIndex
                                      keys:(NSArray *)keys
                                  comments:(NSMapTable *)map;

+ (M80AttributedLabel *)newCommentLabel;

+ (NSArray *)sortedKeys:(NSMapTable<NSNumber *, NIMQuickComment *> *)map;
@end

NS_ASSUME_NONNULL_END
