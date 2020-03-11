//
//  NIMTimestampModel.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMCellConfig.h"

@interface NIMTimestampModel : NSObject

/**
 *  时间戳
 */
@property (nonatomic, assign) NSTimeInterval messageTime;

/**
*  Cell 高度
*/
@property (nonatomic, assign) CGFloat height;

@end
