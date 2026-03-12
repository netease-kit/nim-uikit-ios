//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NELocaitonModel : NSObject

@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) NSString *address;
@property(nonatomic, strong) NSString *city;
@property(nonatomic, assign) CGFloat lat;
@property(nonatomic, assign) CGFloat lng;
@property(nonatomic, assign) NSInteger distance;
@property(nonatomic, strong) NSMutableAttributedString *attribute;

@end

NS_ASSUME_NONNULL_END
