
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public class CoreLoader<T: AnyObject> {
  public let bundle = Bundle(for: T.self)

  public init() {}
  public func localizable(_ key: String) -> String {
    let value = bundle.localizedString(forKey: key, value: nil, table: "Localizable")
    return value
  }

  public func loadImage(_ name: String) -> UIImage? {
    let image = UIImage(named: name, in: bundle, compatibleWith: nil)
    return image
  }

  public func loadString(source: String?, type: String?) -> String? {
    bundle.path(forResource: source, ofType: type)
  }
}
