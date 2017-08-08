//
//  SPayClientWapPayDetailModel.h
//  SPaySDK
//
//  Created by wongfish on 16/2/23.
//  Copyright © 2016年 wongfish. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SPayClientWapPayDetailModel : NSObject


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

@end
