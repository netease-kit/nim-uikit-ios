//
//  NIMSessionViewLayoutManager.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NIMInputView;
@class NIMMessageModel;

@interface NIMSessionViewLayoutManager : NSObject

@property (nonatomic, assign) CGRect viewRect;

- (instancetype)initWithInputView:(NIMInputView*)inputView tableView:(UITableView*)tableview;

- (void)insertTableViewCellAtRows:(NSArray*)addIndexs;

- (void)updateCellAtIndex:(NSInteger)index model:(NIMMessageModel *)model;

-(void)deleteCellAtIndexs:(NSArray*)delIndexs;

-(void)reloadDataToIndex:(NSInteger)index withAnimation:(BOOL)animated;

@end
