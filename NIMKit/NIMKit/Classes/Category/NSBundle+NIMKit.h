//
//  NSBundle+NIMKit.h
//  NIMKit
//
//  Created by Genning-Work on 2019/11/14.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (NIMKit)

+ (NSBundle *)nim_defaultResourceBundle;

+ (NSString *)nim_ResourceImage:(NSString *)imageName;

+ (NSBundle *)nim_defaultEmojiBundle;

+ (nullable NSBundle *)nim_defaultLanguageBundle;

+ (NSString *)nim_EmojiPlistFile;

+ (NSString *)nim_EmojiImage:(NSString *)imageName;

@end

NS_ASSUME_NONNULL_END
