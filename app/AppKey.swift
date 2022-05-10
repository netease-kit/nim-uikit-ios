
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import Foundation
public struct AppKey {
    #if DEBUG
    public static let pushCerName = "<#请输入推送证书#>"
    public static let appKey = "<#请输入appkey#>"

    #else
    public static let pushCerName = "<#请输入推送证书#>"
    public static let appKey = "<#请输入appkey#>"
    #endif
}
