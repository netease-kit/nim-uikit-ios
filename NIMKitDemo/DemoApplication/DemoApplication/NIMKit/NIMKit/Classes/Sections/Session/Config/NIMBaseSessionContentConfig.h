//
//  NIMBaseSessionContentConfig.h
//  NIMKit
//
//  Created by amao on 9/15/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NIMSessionContentConfig <NSObject>
- (CGSize)contentSize:(CGFloat)cellWidth;

- (NSString *)cellContent;

- (UIEdgeInsets)contentViewInsets;

@end

@interface NIMBaseSessionContentConfig : NSObject
@property (nonatomic,strong)    NIMMessage  *message;
@end


@interface NIMSessionContentConfigFactory : NSObject
+ (instancetype)sharedFacotry;
- (id<NIMSessionContentConfig>)configBy:(NIMMessage *)message;
@end