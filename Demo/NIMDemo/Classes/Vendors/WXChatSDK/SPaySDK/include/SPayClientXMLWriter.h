//
//  SPayClientXMLWriter.h
//  SPaySDK
//
//  Created by wongfish on 15/6/14.
//  Copyright (c) 2015年 wongfish. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPayClientXMLWriter : NSObject

+(NSString *)XMLStringFromDictionary:(NSDictionary *)dictionary;
+(NSString *)XMLStringFromDictionary:(NSDictionary *)dictionary withHeader:(BOOL)header;
+(BOOL)XMLDataFromDictionary:(NSDictionary *)dictionary toStringPath:(NSString *) path  Error:(NSError **)error;

@end
