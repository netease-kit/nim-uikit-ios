//
//  NIMKitUrlManager.h
//  NIMKit
//
//  Created by Netease on 2019/7/15.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^NIMKitUrlCompletion)(NSString * _Nullable originalUrl, NSError * _Nullable error);

NS_ASSUME_NONNULL_BEGIN

@interface NIMKitUrlManager : NSObject

+ (instancetype)shareManager;

- (void)queryQriginalUrlWithShortUrl:(NSString *)shortUrl
                          completion:(NIMKitUrlCompletion)completion;


@end

NS_ASSUME_NONNULL_END
