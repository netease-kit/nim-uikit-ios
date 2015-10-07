//
//  NIMLoginClient.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  登录的设备枚举
 */
typedef NS_ENUM(NSInteger, NIMLoginClientType){
    /**
     *  Android
     */
    NIMLoginClientTypeAOS         = 1,
    /**
     *  iOS
     */
    NIMLoginClientTypeIOS         = 2,
    /**
     *  PC
     */
    NIMLoginClientTypePC          = 4,
    /**
     *  WEB
     */
    NIMLoginClientTypeWeb         = 16,
    /**
     *  REST API
     */
    NIMLoginClientTypeRest        = 32,
};


/**
 *  登录客户端描述
 */
@interface NIMLoginClient : NSObject
/**
 *  类型
 */
@property (nonatomic,assign,readonly)   NIMLoginClientType      type;
/**
 *  操作系统
 */
@property (nonatomic,copy,readonly)     NSString                *os;
/**
 *  登录时间
 */
@property (nonatomic,assign,readonly)   NSTimeInterval          timestamp;
@end
