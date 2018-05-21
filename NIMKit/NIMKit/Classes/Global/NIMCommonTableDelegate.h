//
//  NIMCommonTableDelegate.h
//  NIM
//
//  Created by chris on 15/6/29.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NIMCommonTableDelegate : NSObject<UITableViewDataSource,UITableViewDelegate>

- (instancetype) initWithTableData:(NSArray *(^)(void))data;

@property (nonatomic,assign) CGFloat defaultSeparatorLeftEdge;

@end
