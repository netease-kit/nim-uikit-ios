//
//  SPayClientPayStateModel.h
//  SPaySDK
//
//  Created by wongfish on 15/6/11.
//  Copyright (c) 2015年 wongfish. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPayClientConstEnum.h"

@interface SPayClientPayStateModel : NSObject

@property (nonatomic,assign) SPayClientConstEnumPayState payState;

/**
 *  提示消息
 */
@property (nonatomic,copy) NSString *messageString;


@end
