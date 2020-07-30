//
//  NIMListAdapter.h
//  NIMKit
//
//  Created by He on 2020/4/13.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NIMListAdapter;
@class NIMListSectionController;

NS_ASSUME_NONNULL_BEGIN

@protocol NIMListDataSourceProtocol <NSObject>

@optional

- (NSArray *)objectsForAdapter:(NIMListAdapter *)adapter;

- (NIMListSectionController *)listSectionForAdapter:(NIMListAdapter *)adapter object:(id)object;

@end

@interface NIMListAdapter : NSObject <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>

@property (nonatomic,weak) id<NIMListDataSourceProtocol> dataSource;

@end

NS_ASSUME_NONNULL_END
