//
//  JYangTools.h
//  JYangToolKit
//
//  Created by 金阳 on 16/3/18.
//  Copyright © 2016年 JYang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface JYangTools : NSObject

/**
 *  获取规定文字在规定范围的Size
 *
 *  @param text 默认文本
 *  @param size 规定范围
 *  @param font 字体大小
 *
 *  @return 文本Size值
 */
+ (CGSize)getSize:(nullable NSString *)text sizeBy:(CGSize)size font:(nullable UIFont *)font;


/**
 *  获取字符串末4位数
 *
 *  @param sourceString 源字符串
 *
 *  @return 末4位字符串
 */
+ (nullable NSString *)getLastForthStringFromString:(nullable NSString *)sourceString;


/**
 *  网络地址的汉字转换操作
 *
 *  @param dataString 待格式化网址
 *
 *  @return 标准网络地址
 */
+ (nullable NSString *)getFormatURLFromString:(nullable NSString *)dataString;

/**
 *  身份证号校验
 *
 *  @param value 输入的字符串
 *
 *  @return YES 正确  NO 错误
 */
+ (BOOL)validateIDCardNumber:(nullable NSString *)value;

/**
 *  银行卡号校验
 *
 *  @param _text 输入的银行卡号
 *
 *  @return YES 正确  NO 错误
 */
+ (BOOL)CheckCardNumberInput:(nullable NSString *)_text;


/**
 *  alert信息弹框
 *
 *  @param msg     展示信息
 *  @param presentVC iOS9 之后的present视图
 */
+ (void)showAlertViewWithMsg:(nullable NSString*)msg presentVC:(nullable UIViewController *)presentVC;

/**
 *  alert信息弹框
 *
 *  @param msg          展示信息
 *  @param delegate     代理
 *  @param btntxt       按钮文字
 *  @param handler      按钮回调
 *  @param tag          Tag值
 */
+ (void)showAlertViewWithMsg:(nullable NSString*)msg alertViewDelegate:(nullable UIViewController *)delegate btnTxt:(nullable NSString *)btntxt handler:(void (^_Nullable)())handler tag:(NSInteger)tag;

/**
 *  alert信息弹框
 *
 *  @param viewController 展示视图
 *  @param msg            信息
 *  @param lTxt           左按钮文字
 *  @param leftHandler    左按钮回调
 *  @param rTxt           右按钮文字
 *  @param rightHandler   右按钮回调
 *  @param tag            Tag值
 */
+ (void)showAlertView:(nullable UIViewController *)viewController message:(nullable NSString *)msg leftTxt:(nullable NSString *)lTxt leftHandler:(void (^ _Nullable )())leftHandler rightTxt:(nullable NSString *)rTxt rightHandler:(void (^_Nullable)())rightHandler tag:(NSInteger)tag;


/**
 *  校验手机号是否合法
 *
 *  @param _text    手机号
 *
 *  @return         YES 正确  NO 错误
 */
+(BOOL)CheckPhoneInput:(nullable NSString *)_text;

/**
 *  判空
 *
 *  @param string   输入的字符串
 *
 *  @return         是否为空
 */
+ (BOOL)CheckEmptyWithString:(nullable NSString *)string;

/**
 *  格式化身份证号码
 *
 *  @param sourceString 原字符串
 *
 *  @return 格式化后的身份证号码
 */
+ (nullable NSString *)getIDCardNumberHideFromString:(nullable NSString *)sourceString;

/**
 *  获取时间戳
 *
 *  @return 时间戳
 */
+ (nullable NSString*)getCurTimeLong;

/**
 时间戳转日期

 @param stemp 时间戳

 @return 日期
 */
+ (nullable NSString *)getCurTimeDateWithTimeStemp:(nullable NSString *)stemp;

/**
 *  时间戳间隔是否为1Min
 *
 *  @param string   比较时间戳
 *
 *  @return         YES:超过1Min; NO:没超过1Min
 */
+ (NSInteger)isTimeStempForOneMinutes:(nullable NSString *)string;

/**
 *  从bundle中读取图片
 *
 *  @param name 图片名称
 *
 *  @return image
 */

+ (nullable UIImage*)imagesNamedFromCustomBundle:(nullable NSString *)name;

/**
 *  从bundle中读取图片

 @param bundle bundle名称
 @param name 图片名称
 @return image
 */
+ (nullable UIImage*)imagesNamedFromCustomBundle:(nullable NSString *)bundle imgName:(nullable NSString *)name;

/**
 *  格式化电话号码（131****761）
 *
 *  @param sourceString 源字符串
 *
 *  @return             格式化后字符串
 */
+ (nullable NSString *)getPhoneNumberHideFromString:(nullable NSString *)sourceString;

/**
 *  16进制制色
 *
 *  @param color        16进制字符串 支持@“#123456”、 @“0X123456”、 @“123456”三种格式
 *  @param alpha        透明度
 *  @param defaultColor 默认颜色
 *
 *  @return UIColor类型
 */
+ (nullable UIColor *)colorWithHexString:(nullable NSString *)color alpha:(CGFloat)alpha defaultColor:(nullable UIColor *)defaultColor;

/**
 *  base64编码
 *
 *  @param string 源字符串
 *
 *  @return 编码后字符串
 */
+ (nullable NSString *)stringByBase64Encode:(nullable NSString *)string;

/**
 *  base64解码
 *
 *  @param string base64字符串
 *
 *  @return 解码字符串
 */
+ (nullable NSString *)stringByBase64Decode:(nullable NSString *)string;

/**
 *  银行卡简单格式校验
 *
 *  @param cardNo 待校验银行卡号
 *
 *  @return 格式是否正确
 */
+ (BOOL)checkBankCardNo:(nullable NSString*)cardNo;

/**
 颜色生成图片

 @param color 颜色值
 @return 图片
 */
+ (nullable UIImage *)createImageWithColor:(nullable UIColor *) color;

/**
 去除字符串首尾空格
 
 @param string 源字符串
 @return 格式化后字符串
 */
+ (nullable NSString *)TrimmingSpaceCharacterWithString:(nullable NSString *)string;


@end
