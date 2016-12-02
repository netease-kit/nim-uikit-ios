//
//  SwizzlingDefine.h
//  NIM
//
//  Created by chris on 15/6/23.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#ifndef NIM_SwizzlingDefine_h
#define NIM_SwizzlingDefine_h
#import <objc/runtime.h>
static inline void swizzling_exchangeMethod(Class clazz ,SEL originalSelector, SEL swizzledSelector){
    Method originalMethod = class_getInstanceMethod(clazz, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(clazz, swizzledSelector);
    
    BOOL success = class_addMethod(clazz, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (success) {
        class_replaceMethod(clazz, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

#endif
