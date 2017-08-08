//
//  SPayClientReverseScanPayDetailModel.h
//  SPaySDK
//
//  Created by wongfish on 15/9/24.
//  Copyright © 2015年 wongfish. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  配置反扫详情页面
 */
@interface SPayClientReverseScanPayDetailModel : NSObject

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

@end
