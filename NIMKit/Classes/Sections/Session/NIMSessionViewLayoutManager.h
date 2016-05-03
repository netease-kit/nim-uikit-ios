//
//  NIMSessionViewLayoutManager.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMInputView.h"

@class NIMMessageModel;

@interface NIMSessionViewLayoutManager : NSObject

@property (nonatomic, assign) CGRect viewRect;

@property (nonatomic, weak) id<NIMInputDelegate> delegate;

- (instancetype)initWithInputView:(NIMInputView*)inputView tableView:(UITableView*)tableview;

- (void)insertTableViewCellAtRows:(NSArray*)addIndexs animated:(BOOL)animated;

- (void)updateCellAtIndex:(NSInteger)index model:(NIMMessageModel *)model;

-(void)deleteCellAtIndexs:(NSArray*)delIndexs;

-(void)reloadData;

@end
