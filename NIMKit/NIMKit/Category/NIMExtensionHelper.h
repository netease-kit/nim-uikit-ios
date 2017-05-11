//
//  NIMExtensionHelper.h
//  NIMKit
//
//  Created by amao on 4/25/16.
//  Copyright © 2016 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (NIMKitExtension)
- (NSDictionary *)nimkit_jsonDict;
@end


@interface NSDictionary (NIMKitExtension)
- (NSString *)nimkit_jsonString;
@end
