// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

extern const NSString * YXToastPositionTop;
extern const NSString * YXToastPositionCenter;
extern const NSString * YXToastPositionBottom;

@class YXToastStyle;


@interface UIView (YXToast)

- (void)ne_makeToast:(NSString *)message;

- (void)ne_makeToast:(NSString *)message
         duration:(NSTimeInterval)duration
         position:(id)position;

- (void)ne_makeToast:(NSString *)message
         duration:(NSTimeInterval)duration
         position:(id)position
            style:(YXToastStyle *)style;


- (void)ne_makeToast:(NSString *)message
         duration:(NSTimeInterval)duration
         position:(id)position
            title:(NSString *)title
            image:(UIImage *)image
            style:(YXToastStyle *)style
       completion:(void(^)(BOOL didTap))completion;

- (UIView *)toastViewForMessage:(NSString *)message
                          title:(NSString *)title
                          image:(UIImage *)image
                          style:(YXToastStyle *)style;

- (void)ne_hideToast;

- (void)ne_hideToast:(UIView *)toast;

- (void)ne_hideAllToasts;

- (void)ne_hideAllToasts:(BOOL)includeActivity clearQueue:(BOOL)clearQueue;

- (void)clearToastQueue;

- (void)makeToastActivity:(id)position;

- (void)ne_hideToastActivity;

- (void)ne_showToast:(UIView *)toast;

- (void)ne_showToast:(UIView *)toast
         duration:(NSTimeInterval)duration
         position:(id)position
       completion:(void(^)(BOOL didTap))completion;

@end

@interface YXToastStyle : NSObject

/**
 The background color. Default is `[UIColor blackColor]` at 80% opacity.
 */
@property (strong, nonatomic) UIColor *backgroundColor;

/**
 The title color. Default is `[UIColor whiteColor]`.
 */
@property (strong, nonatomic) UIColor *titleColor;

/**
 The message color. Default is `[UIColor whiteColor]`.
 */
@property (strong, nonatomic) UIColor *messageColor;

/**
 A percentage value from 0.0 to 1.0, representing the maximum width of the toast
 view relative to it's superview. Default is 0.8 (80% of the superview's width).
 */
@property (assign, nonatomic) CGFloat maxWidthPercentage;

/**
 A percentage value from 0.0 to 1.0, representing the maximum height of the toast
 view relative to it's superview. Default is 0.8 (80% of the superview's height).
 */
@property (assign, nonatomic) CGFloat maxHeightPercentage;

/**
 The spacing from the horizontal edge of the toast view to the content. When an image
 is present, this is also used as the padding between the image and the text.
 Default is 10.0.
 */
@property (assign, nonatomic) CGFloat horizontalPadding;

/**
 The spacing from the vertical edge of the toast view to the content. When a title
 is present, this is also used as the padding between the title and the message.
 Default is 10.0.
 */
@property (assign, nonatomic) CGFloat verticalPadding;

/**
 The corner radius. Default is 10.0.
 */
@property (assign, nonatomic) CGFloat cornerRadius;

/**
 The title font. Default is `[UIFont boldSystemFontOfSize:16.0]`.
 */
@property (strong, nonatomic) UIFont *titleFont;

/**
 The message font. Default is `[UIFont systemFontOfSize:16.0]`.
 */
@property (strong, nonatomic) UIFont *messageFont;

/**
 The title text alignment. Default is `NSTextAlignmentLeft`.
 */
@property (assign, nonatomic) NSTextAlignment titleAlignment;

/**
 The message text alignment. Default is `NSTextAlignmentLeft`.
 */
@property (assign, nonatomic) NSTextAlignment messageAlignment;

/**
 The maximum number of lines for the title. The default is 0 (no limit).
 */
@property (assign, nonatomic) NSInteger titleNumberOfLines;

/**
 The maximum number of lines for the message. The default is 0 (no limit).
 */
@property (assign, nonatomic) NSInteger messageNumberOfLines;

/**
 Enable or disable a shadow on the toast view. Default is `NO`.
 */
@property (assign, nonatomic) BOOL displayShadow;

/**
 The shadow color. Default is `[UIColor blackColor]`.
 */
@property (strong, nonatomic) UIColor *shadowColor;

/**
 A value from 0.0 to 1.0, representing the opacity of the shadow.
 Default is 0.8 (80% opacity).
 */
@property (assign, nonatomic) CGFloat shadowOpacity;

/**
 The shadow radius. Default is 6.0.
 */
@property (assign, nonatomic) CGFloat shadowRadius;

/**
 The shadow offset. The default is `CGSizeMake(4.0, 4.0)`.
 */
@property (assign, nonatomic) CGSize shadowOffset;

/**
 The image size. The default is `CGSizeMake(80.0, 80.0)`.
 */
@property (assign, nonatomic) CGSize imageSize;

/**
 The size of the toast activity view when `makeToastActivity:` is called.
 Default is `CGSizeMake(100.0, 100.0)`.
 */
@property (assign, nonatomic) CGSize activitySize;

/**
 The fade in/out animation duration. Default is 0.2.
 */
@property (assign, nonatomic) NSTimeInterval fadeDuration;

- (instancetype)initWithDefaultStyle NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

@interface YXToastManager : NSObject

+ (void)setSharedStyle:(YXToastStyle *)sharedStyle;

+ (YXToastStyle *)sharedStyle;

+ (void)setTapToDismissEnabled:(BOOL)tapToDismissEnabled;

+ (BOOL)isTapToDismissEnabled;

+ (void)setQueueEnabled:(BOOL)queueEnabled;

+ (BOOL)isQueueEnabled;

+ (void)setDefaultDuration:(NSTimeInterval)duration;

+ (NSTimeInterval)defaultDuration;

+ (void)setDefaultPosition:(id)position;

+ (id)defaultPosition;

@end
