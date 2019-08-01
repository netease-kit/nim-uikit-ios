//
//  NTESContactDataItem.h
//  NIM
//
//  Created by chris on 15/2/26.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMContactDefines.h"

@interface NIMContactDataItem : NSObject<NIMContactItemCollection>

@property (nonatomic,copy)   NSString *title;

@property (nonatomic,strong) NSArray  *members;

@end
