//
//  M80AttributedLabelDefines.h
//  M80AttributedLabel
//
//  Created by amao on 13-8-31.
//  Copyright (c) 2013年 www.xiangwangfeng.com. All rights reserved.
//

#ifndef M80AttributedLabel_M80AttributedLabelDefines_h
#define M80AttributedLabel_M80AttributedLabelDefines_h

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, M80ImageAlignment) {
    M80ImageAlignmentTop,
    M80ImageAlignmentCenter,
    M80ImageAlignmentBottom
};

@class M80AttributedLabel;

@protocol M80AttributedLabelDelegate <NSObject>
- (void)m80AttributedLabel:(M80AttributedLabel *)label
             clickedOnLink:(id)linkData;

@end

typedef NSArray * _Nullable (^M80CustomDetectLinkBlock)(NSString * _Nullable text);

//如果文本长度小于这个值,直接在UI线程做Link检测,否则都dispatch到共享线程
#define M80MinAsyncDetectLinkLength 50

NS_ASSUME_NONNULL_END

#endif
