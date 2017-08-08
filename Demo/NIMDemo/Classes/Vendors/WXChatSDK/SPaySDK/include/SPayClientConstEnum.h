//
//  SPayClientConstEnum.h
//  SPaySDK
//
//  Created by wongfish on 15/6/11.
//  Copyright (c) 2015年 wongfish. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum {
    
    //二维码生成失败
    SPayClientConstEnumPayQRMakeErro = 1000,
    
    //生成二维码生成，等待扫描中
    SPayClientConstEnumPayQRWaitScan = 1001,
    
    //传入的支付类型无效
    SPayClientConstEnumPayPositiveScansTypeInvalid = 1002,
    
    //二维码等待扫码超时
    SPayClientConstEnumPayQRWaitScanTimerOut = 1003,
    
    //二维码在等待扫描的时候，用户退出了支付
    SPayClientConstEnumPayUserOut = 1004,
    
    //用户在选择支付类型的时候，选择了取消选择支付
    SPayClientConstEnumCancelSelect = 1005,
    
    //传入的参数错误
    SPayClientConstEnumParameterError = 1100,

    //TokenID失效
     SPayClientConstEnumPayTokenIDInvalid = 400,
    
    //TokenID未知
    SPayClientConstEnumPayTokenIDUnknown = 401,
    
    //二维码未支付
    SPayClientConstEnumPayQRUnUse = 204,
    
    //二维码被扫码，但是支付失败
    SPayClientConstEnumPayQRPayErro = 202,
    
    //app支付，支付失败
    SPayClientConstEnumAppPayErro = 601,
    
    
    //wap支付，支付失败
    SPayClientConstEnumWapPayErro = 701,
    
    //wap支付，用户取消了支付
    SPayClientConstEnumWapPayOut = 702,
    
    //wap支付，用户未支付
    SPayClientConstEnumWapPayUnpay = 703,
    
    //支付成功
    SPayClientConstEnumPaySuccess = 201,
    
    //反扫冲正成功
    SPayClientConstEnumReverseScanPayReverseSuccess = 2001,
    
    //反扫冲正失败
    SPayClientConstEnumReverseScanPayReverseErro = 2002,
    
    //反扫支付失败
    SPayClientConstEnumReverseScanPayErro = 2003,
    
    //用户在扫码界面直接退出的交易，交易失败
    SPayClientConstEnumReverseScanCancelSelect = 2004,
    
    //设备设备没有摄像头
    SPayClientConstEnumNotCamera = 3001,
    
    //设备摄像头权限访问受限
    SPayClientConstEnumCameraNotOpen= 3002,
    
    //手Q没有安装
    SPayClientConstEnumQQNotOpen= 3003,
    
    //微信没有安装（微信Wap支付时候用到）
    SPayClientConstEnumWechatNotOpen= 3004,
    
    //支付宝没有安装（支付宝Wap支付时候用到）
    SPayClientConstEnumAlipayNotOpen = 3005

    
    
} SPayClientConstEnumPayState;
//SPay支付状态值



typedef enum {
    
    //普通商户模式（默认）
    SPayClientConstEnumMacChannelNormal = 0,
    
    //代理商户模式
    SPayClientConstEnumMacChannelAgent = 1,
    
    
} SPayClientConstEnumMacChannel;
//商户渠道模式



