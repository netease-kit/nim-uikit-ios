
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
public class ServerAddresses: NSObject {
  private static let className = "ServerAddresses"
  /// 节点配置
  public static func configServer() {
    let isDomestic = SettingRepo.shared.getNodeValue()
    if !isDomestic {
      let serverAddresses = NIMServerSetting()
      serverAddresses.lbsAddress = "https://lbs.netease.im/lbs/conf.jsp"
      serverAddresses.nosUploadAddress = "http://wannos.127.net/lbs"
      serverAddresses.nosUploadAddress = "https://nosup-hz1.127.net"
      serverAddresses.nosDownloadAddress = "{bucket}-nosdn.netease.im/{object}"
      serverAddresses.nosUploadHost = "nosup-hz1.127.net"
      serverAddresses.httpsEnabled = true
      NIMSDK.shared().serverSetting = serverAddresses
      NEALog.infoLog(className, desc: #function + ", url:\(isDomestic)")
    }
  }

  /// 测试服配置
  public static func configTestServer() {
    let serverAddresses = NIMServerSetting()
    serverAddresses.lbsAddress = "https://imtest-jd.netease.im/lbs/conf.jsp?k=fe416640c8e8a72734219e1847ad2547&sv=100300&pv=0&tp=4&networkType=0&lv=1"
    serverAddresses.linkAddress = "59.111.241.213:8081"
    serverAddresses.env = .dev
    serverAddresses.module = "00e3afe7487e6ac9ba69654672672ceddc05d5b6d45850859f11004d30c63e3691afd55722bdd2c75232b2a3561776201f84def8e38c508870ca7692b4228b0478e104460d7800dee3b6c3d8f89746ed48ee94f268f42b9c911437083d3815624e50de3fec3c0ec8ab3e71d5bdce3f4291d20538893cacdc00da9d1390ee39440d"
    NIMSDK.shared().serverSetting = serverAddresses
  }

  /// POC 配置
  public static func configCustomServer(_ model: IMSDKConfigModel) {
    let serverAddresses = NIMServerSetting()

    if let custom = model.customJson, let data = custom.data(using: .utf8) {
      serverAddresses.update(fromConfigData: data)
    } else {
      if let customValue = model.configMap[#keyPath(NIMServerSetting.linkAddress)] as? String {
        serverAddresses.linkAddress = customValue
      }
      if let customValue = model.configMap[#keyPath(NIMServerSetting.lbsAddress)] as? String {
        serverAddresses.lbsAddress = customValue
      }
      if let customValue = model.configMap[#keyPath(NIMServerSetting.nosLbsAddress)] as? String {
        serverAddresses.nosLbsAddress = customValue
      }

      if let customValue = model.configMap[#keyPath(NIMServerSetting.nosUploadAddress)] as? String {
        serverAddresses.nosUploadAddress = customValue
      }

      if let customValue = model.configMap[#keyPath(NIMServerSetting.nosDownloadAddress)] as? String {
        serverAddresses.nosDownloadAddress = customValue
      }

      if let customValue = model.configMap[#keyPath(NIMServerSetting.nosUploadHost)] as? String {
        serverAddresses.nosUploadHost = customValue
      }

      if let modlue = model.configMap[#keyPath(NIMServerSetting.module)] as? String {
        serverAddresses.module = modlue
      }
    }
    NIMSDK.shared().serverSetting = serverAddresses
  }

  // appkey配置
  public static func getAppkey() -> String {
    let isDomestic = SettingRepo.shared.getNodeValue()
    if isDomestic {
      return AppKey.appKey
    } else {
      return AppKey.overseasAppkey
    }
  }
}
