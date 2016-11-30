//
//  NIMMessageCellMaker.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMMessageCell.h"
#import "NIMSessionTimestampCell.h"
#import "NIMCellConfig.h"
#import "NIMMessageCellProtocol.h"

@interface NIMMessageCellFactory : NSObject

+ (NIMMessageCell *)cellInTable:(UITableView*)tableView
                 forMessageMode:(NIMMessageModel *)model;

+ (NIMSessionTimestampCell *)cellInTable:(UITableView *)tableView
                            forTimeModel:(NIMTimestampModel *)model;

@end
