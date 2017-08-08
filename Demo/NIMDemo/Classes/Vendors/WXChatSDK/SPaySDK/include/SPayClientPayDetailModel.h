//
//  SPayClientPayDetailModel.h
//  SPaySDK
//
//  Created by wongfish on 15/7/3.
//  Copyright (c) 2015年 wongfish. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


/**
 *  支付详情界面UI配置
 */
@interface SPayClientPayDetailModel : NSObject



#pragma mark - 退出按钮
/**
 *  退出按钮-字体大小
 */
@property (nonatomic,copy) UIFont *backFont;

/**
 *  退出按钮-字体颜色
 */
@property (nonatomic,copy) UIColor *backFontColor;

/**
 *  退出按钮-标题
 */
@property (nonatomic,copy) NSString *backTitleString;

/**
 *  退出按钮-默认图片
 */
@property (nonatomic,strong) UIImage *backDefaultImage;


#pragma mark - 金额

/**
 *  金额-字体
 */
@property (nonatomic,copy) UIFont *moneyFont;

/**
 *  金额-字体颜色
 */
@property (nonatomic,copy) UIColor *moneyFontColor;



#pragma mark - 标题

/**
 *  标题-字体
 */
@property (nonatomic,copy) UIFont *titleFont;

/**
 *  标题-字体颜色
 */
@property (nonatomic,copy) UIColor *titleFontColor;

/**
 *  标题背景色
 */
@property (nonatomic,copy) UIColor *titleViewBackgroundColor;

#pragma mark - 支付帮助
/**
 *  支付帮助-默认图片
 */
@property (nonatomic,strong) UIImage *payHelpDefaultImage;


#pragma mark - 扫码提示
/**
 *  扫码提示-字体颜色
 */
@property (nonatomic,copy) UIColor *qrPromptFontColor;

/**
 *  扫码提示-字体
 */
@property (nonatomic,copy) UIFont *qrPromptFont;

/**
 *  扫码提示-背景框颜色
 */
@property (nonatomic,copy) UIColor *qrPromptBackgroundColor;


#pragma mark - picc

/**
 *  picc-字体颜色 目前只有微信反扫才有picc保险显示
 */
@property (nonatomic,copy) UIColor *piccFontColor;

/**
 *  picc-字体 目前只有微信反扫才有picc保险显示
 */
@property (nonatomic,copy) UIFont *piccFont;




#pragma mark - 客服电话

/**
 *   客服电话
 */
@property (nonatomic,copy) NSString *phoneString;

/**
 *  客服电话颜色
 */
@property (nonatomic,copy) UIColor *phoneFontColor;

/**
 *  客服电话标题颜色
 */
@property (nonatomic,copy) UIColor *phoneTitleFontColor;


#pragma mark - 公司

/**
 *  公司名称
 */
@property (nonatomic,copy) NSString *companyNameString;


/**
 *  公司名称字体颜色
 */
@property (nonatomic,copy) UIColor *companyNameFontColor;




@end
