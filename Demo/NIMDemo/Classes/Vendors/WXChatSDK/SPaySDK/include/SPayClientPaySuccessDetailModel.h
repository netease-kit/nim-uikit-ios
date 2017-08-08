//
//  SPayClientPaySuccessDetailModel.h
//  SPaySDK
//
//  Created by wongfish on 15/6/16.
//  Copyright (c) 2015年 wongfish. All rights reserved.
//

#import "SPBaseModel.h"

@interface SPayClientPaySuccessDetailModel : SPBaseModel

/**
 *  商品描叙
 */
@property (nonatomic,copy) NSString *body;

/**
 *  返回状态码
 */
@property (nonatomic,assign) NSInteger status;

/**
 *  返回信息
 */
@property (nonatomic,copy) NSString *message;

/**
 *  支付金额
 */
@property (nonatomic,assign) NSInteger money;

/**
 *  商户订单号
 */
@property (nonatomic,copy) NSString *out_trade_no;

/**
 *  威富通订单号
 */
@property (nonatomic,copy) NSString *order_no;


/**
 *  第三方订单号
 */
@property (nonatomic,copy) NSString *transaction_id;

/**
 *  商户名
 */
@property (nonatomic,copy) NSString *mch_name;

/**
 *  支付时间
 */
@property (nonatomic,copy) NSString *trade_time;

/**
 *  统一反扫是否需要继续扫描标示（Y需要查询，N 不需要查询）
 */
@property (nonatomic,copy) NSString *need_query;

/**
 *  交易类型
 */
@property (nonatomic,copy) NSString *trade_type;

@end
