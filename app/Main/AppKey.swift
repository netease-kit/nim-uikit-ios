
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

public struct AppKey {
    #if DEBUG
    public static let pushCerName = "<#请输入推送证书#>"
    public static let appKey = "<#请输入appkey#>"
    public static let gaodeMapAppkey = "<#输入高德地图key#>"
    public static let gaodeMapServerAppkey = "<#输入高德地图key#>"
    #else
    public static let pushCerName = "<#请输入推送证书#>"
    public static let appKey = "<#请输入appkey#>"
    public static let gaodeMapAppkey = "<#输入高德地图key#>"
    public static let gaodeMapServerAppkey = "<#输入高德地图key#>"
    #endif
}
