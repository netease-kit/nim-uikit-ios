//
//  NTESGLView.h
//  NIM
//
//  Created by fenric on 15/9/1.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTESGLView : UIView

- (void) render: (NSData *)yuvData
          width:(NSUInteger)width
         height:(NSUInteger)height;

@end
