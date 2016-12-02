//
//  NTESDemoFetchChatroomTask.m
//  NIM
//
//  Created by amao on 1/20/16.
//  Copyright © 2016 Netease. All rights reserved.
//

#import "NTESDemoFetchChatroomTask.h"
#import "NTESDemoConfig.h"
#import "NSDictionary+NTESJson.h"
#import "NTESChatroomMaker.h"

@implementation NTESDemoFetchChatroomTask
- (NSURLRequest *)taskRequest
{
    NSString *urlString = [[[NTESDemoConfig sharedConfig] apiURL] stringByAppendingString:@"/chatroom/homeList"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
    [request setHTTPMethod:@"GET"];
    [request addValue:[NTESDemoConfig sharedConfig].appKey forHTTPHeaderField:@"appkey"];
    [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    return request;

}


- (void)onGetResponse:(id)jsonObject
                error:(NSError *)error
{
    NSMutableArray *chatrooms = nil;
    NSError *resultError = error;
    
    if (error == nil && [jsonObject isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *dict = (NSDictionary *)jsonObject;
        NSInteger code = [dict jsonInteger:@"res"];
        resultError = code == 200 ? nil : [NSError errorWithDomain:@"ntes domain"
                                                              code:code
                                                          userInfo:nil];
        if (resultError == nil)
        {
            chatrooms = [NSMutableArray array];
            NSDictionary *msg = [dict jsonDict:@"msg"];
            NSArray *list = [msg jsonArray:@"list"];
            for (NSDictionary *item in list) {
                NIMChatroom *chatroom = [NTESChatroomMaker makeChatroom:item];
                if (chatroom)
                {
                    [chatrooms addObject:chatroom];
                }
            }
        }
    }
    
    
    if (_handler) {
        _handler(resultError,chatrooms);
    }
    
    
    
    
}
@end
