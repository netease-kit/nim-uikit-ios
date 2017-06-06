//
//  NTESAVNotifier.h
//  NIM
//
//  Created by amao on 2017/5/4.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NTESAVNotifier : NSObject
- (void)start:(NSString *)text;
- (void)stop;
@end
