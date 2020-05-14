//
//  NIMListSectionController.h
//  NIMKit
//
//  Created by He on 2020/4/13.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NIMListSectionController : NSObject

- (NSInteger)numberOfItems;

- (CGSize)sizeForItemAtIndex:(NSInteger)index;

- (UICollectionViewCell *)cellForItemAtIndex:(NSInteger)index;

- (void)didSelectItemAtIndex:(NSInteger)index;

- (void)didDeselectItemAtIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
