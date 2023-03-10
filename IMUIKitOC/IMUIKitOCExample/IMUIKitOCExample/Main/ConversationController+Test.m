// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <objc/runtime.h>
#import "ConversationController+Test.h"

@implementation ConversationController (Test)

+ (void)initialize {
  Method originalMethod = class_getInstanceMethod(self, @selector(viewDidLoad));
  Method swizzledMethod = class_getInstanceMethod(self, @selector(test_viewDidLoad));
  method_exchangeImplementations(originalMethod, swizzledMethod);
}

- (void)test_viewDidLoad {
  [self test_viewDidLoad];
}

@end
