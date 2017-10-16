//
//  NTESAttachmentDecoder.m
//  DemoApplication
//
//  Created by chris on 15/11/1.
//  Copyright © 2015年 chris. All rights reserved.
//

#import "NTESAttachmentDecoder.h"
#import "NTESAttachment.h"
@implementation NTESAttachmentDecoder

- (id<NIMCustomAttachment>)decodeAttachment:(NSString *)content{
    //所有的自定义消息都会走这个解码方法，如有多种自定义消息请自行做好类型判断和版本兼容。这里仅演示最简单的情况。
    id<NIMCustomAttachment> attachment;
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    if (data) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([dict isKindOfClass:[NSDictionary class]]) {
            NSString *title = dict[@"title"];
            NSString *subTitle = dict[@"subTitle"];
            NTESAttachment *myAttachment = [[NTESAttachment alloc] init];
            myAttachment.title = title;
            myAttachment.subTitle = subTitle;
            attachment = myAttachment;
        }
    }
    return attachment;
}

@end
