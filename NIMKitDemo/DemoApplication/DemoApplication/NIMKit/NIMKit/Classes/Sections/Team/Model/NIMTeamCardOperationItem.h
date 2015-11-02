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

@property(nonatomic,copy)   NSString *title;

@property(nonatomic,strong) UIImage  *imageNormal;

@property(nonatomic,strong) UIImage  *imageHighLight;

- (instancetype)initWithOperation:(NIMKitCardHeaderOpeator)opera;

@end
