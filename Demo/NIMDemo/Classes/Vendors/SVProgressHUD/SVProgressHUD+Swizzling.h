//
//  SVProgressHUD+Swizzling.h
//  NIM
//
//  Created by chris on 2017/7/26.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVProgressHUD.h"

/*
   SVProgressHUD 防止苹果 reject 方案，因为没有 release 出来， 所以无法直接升级依赖库，
   这里以 hack 插件的形式提供，上层开发者可按需使用
 */
@interface SVProgressHUD (Swizzling)

@end
