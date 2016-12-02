//
//  NTESDemoServiceTask.h
//  NIM
//
//  Created by amao on 1/20/16.
//  Copyright © 2016 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NTESDemoServiceTask <NSObject>
- (NSURLRequest *)taskRequest;
- (void)onGetResponse:(id)jsonObject
                error:(NSError *)error;
@end
