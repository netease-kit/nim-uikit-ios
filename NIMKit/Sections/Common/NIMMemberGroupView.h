//
//  NIMMemberGroupView.h
//  NIMKit
//
//  Created by chris on 15/10/15.
//  Copyright © 2015年 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMCardDataSourceProtocol.h"

@protocol NIMMemberGroupViewDelegate <NSObject>
@optional

- (void)didSelectMemberId:(NSString *)uid;

- (void)didSelectRemoveButtonWithMemberId:(NSString *)uid;

- (void)didSelectOperator:(NIMKitCardHeaderOpeator )opera;

@end

@interface NIMMemberGroupView : UIView

@property (nonatomic,strong) UICollectionView *collectionView;

@property (nonatomic,readonly) BOOL showAddOperator;

@property (nonatomic,readonly) BOOL showRemoveOperator;

@property (nonatomic,assign) BOOL enableRemove;

@property (nonatomic,weak) id<NIMMemberGroupViewDelegate> delegate;

- (void)refreshUids:(NSArray *)uids operators:(NIMKitCardHeaderOpeator)operators;

- (void)setTitle:(NSString *)title forOperator:(NIMKitCardHeaderOpeator)opera;

@end