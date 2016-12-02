//
//  NTESLogUploader.h
//  NIM
//
//  Created by amao on 3/25/16.
//  Copyright © 2016 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

//仅用于方便开发者在测试demo时发现问题后获取log

typedef void(^NTESUploadLogBlock)(NSString *urlString,NSError *error);

@interface NTESLogUploader : NSObject
- (void)upload:(NTESUploadLogBlock)completion;
@end
