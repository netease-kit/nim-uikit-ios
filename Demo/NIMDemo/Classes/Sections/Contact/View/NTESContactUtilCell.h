//
//  NTESContactUtilCell.h
//  NIM
//
//  Created by chris on 15/2/26.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTESContactDefines.h"

@protocol NTESContactUtilCellDelegate <NSObject>

- (void)onPressUtilImage:(NSString *)content;

@end

@interface NTESContactUtilCell : UITableViewCell

@property (nonatomic,weak) id<NTESContactUtilCellDelegate> delegate;

- (void)refreshWithContactItem:(id<NTESContactItem>)item;

@end
