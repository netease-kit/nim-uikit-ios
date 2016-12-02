//
//  NIMService.h
//  NIM
//
//  Created by amao on 11/13/13.
//  Copyright (c) 2013 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NTESService <NSObject>
@optional
- (void)onCleanData;
- (void)onReceiveMemoryWarning;
- (void)onEnterBackground;
- (void)onEnterForeground;
- (void)onAppWillTerminate;
@end

@interface NTESService : NSObject<NTESService>
+ (instancetype)sharedInstance;

//空方法，只是输出log而已
//大部分的NIMService懒加载即可，但是有些因为业务需要在登录后就需要立马生成
- (void)start;
@end

@interface NTESServiceManager: NSObject

+ (instancetype)sharedManager;

- (void)start;
- (void)destory;

@end