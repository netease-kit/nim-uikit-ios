
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

public let account = "<#account#>"
public let token = "<#token#>"

public struct AppKey {
    #if DEBUG
    public static let appKey = "<#请输入云信 AppKey#>"
    public static let apnsCername = "<#请输入云信 Apns 推送证书名#>"
    public static let pkCerName = "<#请输入云信 PushKit 推送证书名#>"
    public static let gaodeMapAppkey = "<#输入高德地图key#>"
    public static let gaodeMapServerAppkey = "<#输入高德地图key#>"
    #else
    public static let appKey = "<#请输入云信 AppKey#>"
    public static let apnsCername = "<#请输入云信 Apns 推送证书名#>"
    public static let pkCerName = "<#请输入云信 PushKit 推送证书名#>"
    public static let gaodeMapAppkey = "<#输入高德地图key#>"
    public static let gaodeMapServerAppkey = "<#输入高德地图key#>"
    #endif
}
