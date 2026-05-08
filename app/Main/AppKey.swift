
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public enum AppKey {
  #if DEBUG
    public static let apnsCername = "dev_im"
    public static let pkCerName = "dev_im_voip"
    public static let appKey = "3e215d27b6a6a9e27dad7ef36dd5b65c"
    public static let overseasAppkey = "accb0a77b32cfcec25a3e03570eff618"
    public static let gaodeMapAppkey = "46a3a36bb9d26934a26c6ce2b04aab6f"
    public static let gaodeMapServerAppkey = "78c0eb6bff7db9ed52e07ca7051a97a3"
  #else
    public static let apnsCername = "dis_im"
    public static let pkCerName = "dis_im_voip"
    public static let appKey = "3e215d27b6a6a9e27dad7ef36dd5b65c"
    public static let overseasAppkey = "accb0a77b32cfcec25a3e03570eff618"
    public static let gaodeMapAppkey = "46a3a36bb9d26934a26c6ce2b04aab6f"
    public static let gaodeMapServerAppkey = "78c0eb6bff7db9ed52e07ca7051a97a3"
  #endif
}
