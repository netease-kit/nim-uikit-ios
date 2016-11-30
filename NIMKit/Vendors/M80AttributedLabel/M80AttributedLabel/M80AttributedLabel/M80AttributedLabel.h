//
//  M80AttributedLabel.h
//  M80AttributedLabel
//
//  Created by amao on 13-9-1.
//  Copyright (c) 2013年 www.xiangwangfeng.com. All rights reserved.
//

#import "M80AttributedLabelDefines.h"
#import "NSMutableAttributedString+M80.h"

NS_ASSUME_NONNULL_BEGIN

@class M80AttributedLabelURL;

@interface M80AttributedLabel : UIView
@property (nonatomic,weak,nullable)     id<M80AttributedLabelDelegate> delegate;
@property (nonatomic,strong,nullable)    UIFont *font;                          //字体
@property (nonatomic,strong,nullable)    UIColor *textColor;                    //文字颜色
@property (nonatomic,strong,nullable)    UIColor *highlightColor;               //链接点击时背景高亮色
@property (nonatomic,strong,nullable)    UIColor *linkColor;                    //链接色
@property (nonatomic,strong,nullable)    UIColor *shadowColor;                  //阴影颜色
@property (nonatomic,assign)            CGSize  shadowOffset;                   //阴影offset
@property (nonatomic,assign)            CGFloat shadowBlur;                     //阴影半径
@property (nonatomic,assign)            BOOL    underLineForLink;               //链接是否带下划线
@property (nonatomic,assign)            BOOL    autoDetectLinks;                //自动检测
@property (nonatomic,assign)            NSInteger   numberOfLines;              //行数
@property (nonatomic,assign)            CTTextAlignment textAlignment;          //文字排版样式
@property (nonatomic,assign)            CTLineBreakMode lineBreakMode;          //LineBreakMode
@property (nonatomic,assign)            CGFloat lineSpacing;                    //行间距
@property (nonatomic,assign)            CGFloat paragraphSpacing;               //段间距
@property (nonatomic,copy,nullable)     NSString *text;                         //普通文本
@property (nonatomic,copy,nullable)     NSAttributedString *attributedText;     //属性文本



//添加文本
- (void)appendText:(NSString *)text;
- (void)appendAttributedText:(NSAttributedString *)attributedText;

//图片
- (void)appendImage:(UIImage *)image;
- (void)appendImage:(UIImage *)image
            maxSize:(CGSize)maxSize;
- (void)appendImage:(UIImage *)image
            maxSize:(CGSize)maxSize
             margin:(UIEdgeInsets)margin;
- (void)appendImage:(UIImage *)image
            maxSize:(CGSize)maxSize
             margin:(UIEdgeInsets)margin
          alignment:(M80ImageAlignment)alignment;

//UI控件
- (void)appendView:(UIView *)view;
- (void)appendView:(UIView *)view
            margin:(UIEdgeInsets)margin;
- (void)appendView:(UIView *)view
            margin:(UIEdgeInsets)margin
         alignment:(M80ImageAlignment)alignment;


//添加自定义链接
- (void)addCustomLink:(id)linkData
             forRange:(NSRange)range;

- (void)addCustomLink:(id)linkData
             forRange:(NSRange)range
            linkColor:(UIColor *)color;


//大小
- (CGSize)sizeThatFits:(CGSize)size;

//设置全局的自定义Link检测Block(详见M80AttributedLabelURL)
+ (void)setCustomDetectMethod:(nullable M80CustomDetectLinkBlock)block;

@end

NS_ASSUME_NONNULL_END
