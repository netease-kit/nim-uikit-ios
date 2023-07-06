// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

#if __has_include(<YXModel/YXModel.h>)
FOUNDATION_EXPORT double YXModelVersionNumber;
FOUNDATION_EXPORT const unsigned char YXModelVersionString[];
#import <YXModel/NSObject+YXModel.h>
#import <YXModel/YXClassInfo.h>
#else
#import "NSObject+YXModel.h"
#import "YXClassInfo.h"
#endif
