//
//  NIMUnsupportContentConfig.h
//  NIMKit
//
//  Created by amao on 9/15/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMBaseSessionContentConfig.h"


@interface NIMUnsupportContentConfig : NIMBaseSessionContentConfig<NIMSessionContentConfig>
+ (instancetype)sharedConfig;
@end
