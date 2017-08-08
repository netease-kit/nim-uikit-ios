//
//  NTESCustomAttachmentDecoder.m
//  NIM
//
//  Created by amao on 7/2/15.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import "NTESCustomAttachmentDecoder.h"
#import "NTESCustomAttachmentDefines.h"
#import "NTESJanKenPonAttachment.h"
#import "NTESSnapchatAttachment.h"
#import "NTESChartletAttachment.h"
#import "NTESWhiteboardAttachment.h"
#import "NTESRedPacketAttachment.h"
#import "NTESRedPacketTipAttachment.h"
#import "NSDictionary+NTESJson.h"
#import "NTESSessionUtil.h"

@implementation NTESCustomAttachmentDecoder
- (id<NIMCustomAttachment>)decodeAttachment:(NSString *)content
{
    id<NIMCustomAttachment> attachment = nil;

    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    if (data) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
                                                             options:0
                                                               error:nil];
        if ([dict isKindOfClass:[NSDictionary class]])
        {
            NSInteger type     = [dict jsonInteger:CMType];
            NSDictionary *data = [dict jsonDict:CMData];
            switch (type) {
                case CustomMessageTypeJanKenPon:
                {
                    attachment = [[NTESJanKenPonAttachment alloc] init];
                    ((NTESJanKenPonAttachment *)attachment).value = [data jsonInteger:CMValue];
                }
                    break;
                case CustomMessageTypeSnapchat:
                {
                    attachment = [[NTESSnapchatAttachment alloc] init];
                    ((NTESSnapchatAttachment *)attachment).md5 = [data jsonString:CMMD5];
                    ((NTESSnapchatAttachment *)attachment).url = [data jsonString:CMURL];
                    ((NTESSnapchatAttachment *)attachment).isFired = [data jsonBool:CMFIRE];
                }
                    break;
                case CustomMessageTypeChartlet:
                {
                    attachment = [[NTESChartletAttachment alloc] init];
                    ((NTESChartletAttachment *)attachment).chartletCatalog = [data jsonString:CMCatalog];
                    ((NTESChartletAttachment *)attachment).chartletId      = [data jsonString:CMChartlet];
                }
                    break;
                case CustomMessageTypeWhiteboard:
                {
                    attachment = [[NTESWhiteboardAttachment alloc] init];
                    ((NTESWhiteboardAttachment *)attachment).flag = [data jsonInteger:CMFlag];
                }
                    break;
                case CustomMessageTypeRedPacket:
                {
                    attachment = [[NTESRedPacketAttachment alloc] init];
                    ((NTESRedPacketAttachment *)attachment).title = [data jsonString:CMRedPacketTitle];
                    ((NTESRedPacketAttachment *)attachment).content = [data jsonString:CMRedPacketContent];
                    ((NTESRedPacketAttachment *)attachment).redPacketId = [data jsonString:CMRedPacketId];
                }
                    break;
                case CustomMessageTypeRedPacketTip:
                {
                    attachment = [[NTESRedPacketTipAttachment alloc] init];
                    ((NTESRedPacketTipAttachment *)attachment).sendPacketId = [data jsonString:CMRedPacketSendId];
                    ((NTESRedPacketTipAttachment *)attachment).packetId  = [data jsonString:CMRedPacketId];
                    ((NTESRedPacketTipAttachment *)attachment).isGetDone = [data jsonString:CMRedPacketDone];
                    ((NTESRedPacketTipAttachment *)attachment).openPacketId = [data jsonString:CMRedPacketOpenId];
                }
                    break;
                default:
                    break;
            }
            attachment = [self checkAttachment:attachment] ? attachment : nil;
        }
    }
    return attachment;
}


- (BOOL)checkAttachment:(id<NIMCustomAttachment>)attachment{
    BOOL check = NO;
    if ([attachment isKindOfClass:[NTESJanKenPonAttachment class]])
    {
        NSInteger value = [((NTESJanKenPonAttachment *)attachment) value];
        check = (value>=CustomJanKenPonValueKen && value<=CustomJanKenPonValuePon) ? YES : NO;
    }
    else if ([attachment isKindOfClass:[NTESSnapchatAttachment class]])
    {
        check = YES;
    }
    else if ([attachment isKindOfClass:[NTESChartletAttachment class]])
    {
        NSString *chartletCatalog = ((NTESChartletAttachment *)attachment).chartletCatalog;
        NSString *chartletId      =((NTESChartletAttachment *)attachment).chartletId;
        check = chartletCatalog.length&&chartletId.length ? YES : NO;
    }
    else if ([attachment isKindOfClass:[NTESWhiteboardAttachment class]])
    {
        NSInteger flag = [((NTESWhiteboardAttachment *)attachment) flag];
        check = ((flag >= CustomWhiteboardFlagInvite) && (flag <= CustomWhiteboardFlagClose)) ? YES : NO;
    }
    else if([attachment isKindOfClass:[NTESRedPacketAttachment class]] || [attachment isKindOfClass:[NTESRedPacketTipAttachment class]])
    {
        check = YES;
    }
    return check;
}
@end
