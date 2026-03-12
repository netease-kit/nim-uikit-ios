// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

/// The base to all Link parsing elements.
public protocol NEMarkdownLinkElement: NEMarkdownElement, NEMarkdownStyle {
  func formatText(_ attributedString: NSMutableAttributedString, range: NSRange, link: String)
  func addAttributes(_ attributedString: NSMutableAttributedString, range: NSRange, link: String)
}
