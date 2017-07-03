//
//  NTESGLView.h
//  NIM
//
//  Created by fenric on 16/8/30.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "IJKSDLGLView.h"

@interface NTESGLView : NTESIJKSDLGLView

- (void) render: (NSData *)yuvData
          width:(NSUInteger)width
         height:(NSUInteger)height;

@end
