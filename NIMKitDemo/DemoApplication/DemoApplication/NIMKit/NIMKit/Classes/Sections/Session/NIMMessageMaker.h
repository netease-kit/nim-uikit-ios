//
//  NIMMessageMaker.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NIMMessageMaker : NSObject

+ (NIMMessage*)msgWithText:(NSString*)text;

+ (NIMMessage*)msgWithAudio:(NSString*)filePath;

@end
