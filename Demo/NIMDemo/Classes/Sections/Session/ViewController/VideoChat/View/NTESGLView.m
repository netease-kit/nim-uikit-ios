//
//  NTESGLView.m
//  NIM
//
//  Created by fenric on 16/8/30.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESGLView.h"

@interface NTESGLView()
{
    SDL_VoutOverlay _overlay;
    Uint16 _pitches[3];
    Uint8 *_pixels[3];
}

@end

@implementation NTESGLView

- (id) initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _overlay.format = SDL_FCC_I420;
        _overlay.planes = 3;
        _overlay.pitches = _pitches;
        _overlay.pixels = _pixels;
        _overlay.is_private = 0;
        _overlay.sar_num = 0;
        _overlay.sar_den = 0;
        
    }
    return self;
}
- (void) render: (NSData *)yuvData
          width:(NSUInteger)width
         height:(NSUInteger)height
{
    if (yuvData) {
        _overlay.w = (int)width;
        _overlay.h = (int)height;
        
        _pitches[0] = width;
        _pitches[1] = _pitches[2] = _pitches[0] / 2;
        
        _pixels[0] = (UInt8 *)[yuvData bytes];
        _pixels[1] = _pixels[0] + width * height;
        _pixels[2] = _pixels[0] + width * height * 5 / 4;
        
        [self display:&_overlay clear:NO];
    }
    else {
        [self display:NULL clear:YES];
    }

}

@end
