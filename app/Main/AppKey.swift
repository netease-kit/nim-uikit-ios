// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

/// account 优先从本地存储读取
public var account: String {
  UserDefaults.standard.string(forKey: "nim_config_account") ?? "<#account#>"
}

/// token 优先从本地存储读取
public var token: String {
  UserDefaults.standard.string(forKey: "nim_config_token") ?? "<#token#>"
}

public struct AppKey {
    #if DEBUG
    /// appKey 优先从本地存储读取
    public static var appKey: String {
      UserDefaults.standard.string(forKey: "nim_config_appKey") ?? "<#请输入云信 AppKey#>"
    }
    public static let apnsCername = "<#请输入云信 Apns 推送证书名#>"
    public static let pkCerName = "<#请输入云信 PushKit 推送证书名#>"
    public static let gaodeMapAppkey = "<#输入高德地图key#>"
    public static let gaodeMapServerAppkey = "<#输入高德地图key#>"
    #else
    /// appKey 优先从本地存储读取
    public static var appKey: String {
      UserDefaults.standard.string(forKey: "nim_config_appKey") ?? "<#请输入云信 AppKey#>"
    }
    public static let apnsCername = "<#请输入云信 Apns 推送证书名#>"
    public static let pkCerName = "<#请输入云信 PushKit 推送证书名#>"
    public static let gaodeMapAppkey = "<#输入高德地图key#>"
    public static let gaodeMapServerAppkey = "<#输入高德地图key#>"
    #endif
}
