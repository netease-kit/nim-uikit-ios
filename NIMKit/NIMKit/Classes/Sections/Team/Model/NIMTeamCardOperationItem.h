//
//  TeamCardOperationItem.h
//  NIM
//
//  Created by chris on 15/3/5.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMCardDataSourceProtocol.h"

@interface NIMTeamCardOperationItem : NSObject<NIMKitCardHeaderData>

- (instancetype)initWithOperation:(NIMKitCardHeaderOpeator)opera;

@end
