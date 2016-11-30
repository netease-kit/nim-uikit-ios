//
//  NIMInputProtocol.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NIMMediaItem;


@protocol NIMInputActionDelegate <NSObject>

@optional
- (BOOL)onTapMediaItem:(NIMMediaItem *)item;

- (void)onTextChanged:(id)sender;

- (void)onSendText:(NSString *)text;

- (void)onSelectChartlet:(NSString *)chartletId
                 catalog:(NSString *)catalogId;


- (void)onCancelRecording;

- (void)onStopRecording;

- (void)onStartRecording;

@end

