// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import GCDWebServer

class LocalServerManager {
  static let instance = LocalServerManager()
  let webServer = GCDWebServer()
  let deviceTokenKey = "deviceToken"
  open func startServer() {
    webServer.addGETHandler(forBasePath: "/", directoryPath: NSHomeDirectory(), indexFilename: nil, cacheAge: 3600, allowRangeRequests: true)
    webServer.start(withPort: 8080, bonjourName: "GCD Web Server")
  }
}
