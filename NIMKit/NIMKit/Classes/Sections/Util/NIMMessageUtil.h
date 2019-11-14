//
//  NIMMessageUtil.h
//  NIMKit
//
//  Created by Netease on 2019/10/17.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NIMMessage;

NS_ASSUME_NONNULL_BEGIN

@interface NIMMessageUtil : NSObject

+ (NSString *)messageContent:(NIMMessage*)message;

@end

NS_ASSUME_NONNULL_END
