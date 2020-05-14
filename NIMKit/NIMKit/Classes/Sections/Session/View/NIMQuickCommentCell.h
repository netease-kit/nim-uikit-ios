//
//  NIMListCollectionCell.h
//  NIMKit
//
//  Created by He on 2020/4/13.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NIMQuickComment;
@class NIMMessageModel;
NS_ASSUME_NONNULL_BEGIN

@interface NIMQuickCommentCell : UICollectionViewCell

- (void)refreshWithData:(NSArray *)comment model:(NIMMessageModel *)data;

@end

NS_ASSUME_NONNULL_END
