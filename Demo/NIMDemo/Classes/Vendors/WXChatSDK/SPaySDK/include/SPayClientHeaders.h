//
//  SPayClientHeaders.h
//  SPaySDK
//
//  Created by wongfish on 15/6/11.
//  Copyright (c) 2015年 wongfish. All rights reserved.
//

#ifndef SPaySDK_SPayClientHeaders_h
#define SPaySDK_SPayClientHeaders_h

//资源路径
#define kSPaySDKBundle  ([NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"SPaySDKResource" ofType:@"bundle"]])

//图片路径
#define kSPaySDKBundleSrcName(file) [@"SPaySDKResource.bundle" stringByAppendingPathComponent:file]





#import "SPayClientPayStateModel.h"
#import "NSDictionary+SPayUtilsExtras.h"
#import "NSString+SPayUtilsExtras.h"
#import "SPayClientXMLWriter.h"
#import "SPayClientPaySuccessDetailModel.h"
#import "SPayClientPayDetailModel.h"
#import "SPayClientPaySuccessModel.h"
#import "SPayClientPayHelpModel.h"


/**
 *  支付回调
 *
 *  @param payStateModel         支付状态说明
 *  @param paySuccessDetailModel 支付内容详情，只有支付成功才会有值
 */
typedef void(^SPayPayFinishBlock) (SPayClientPayStateModel *payStateModel,
                                   SPayClientPaySuccessDetailModel *paySuccessDetailModel);




/**
 *  支付失败回调
 *
 *  @param ^ <#^ description#>
 */
typedef void(^SPayPayFailureBlock) (NSString *message);


#endif
