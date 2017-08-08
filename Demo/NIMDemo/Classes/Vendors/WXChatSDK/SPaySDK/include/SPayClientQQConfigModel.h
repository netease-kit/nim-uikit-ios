//
//  SPayClientQQConfigModel.h
//  SPaySDK
//
//  Created by wongfish on 16/2/18.
//  Copyright © 2016年 wongfish. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPayClientQQConfigModel : NSObject



/**
 *  app Scheme（手Q Wap支付需要传入此参数，用于手Q支付完成后的APP回调）
 */
@property (nonatomic,copy) NSString *appScheme;

@end
