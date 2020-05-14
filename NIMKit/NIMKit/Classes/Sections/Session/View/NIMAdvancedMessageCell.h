//
//  NIMAdvancedMessageCell.h
//  NIMKit
//
//  Created by He on 2020/4/10.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMMessageCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface NIMAdvancedMessageCell : NIMMessageCell

@property (nonatomic,strong) UIButton *replyButton;
@property (nonatomic,strong) UIButton *pinView;

@property (nonatomic,nullable,strong) UICollectionView *emoticonsContainerView;

@end

NS_ASSUME_NONNULL_END
