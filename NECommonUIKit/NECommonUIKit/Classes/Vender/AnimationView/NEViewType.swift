// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#if canImport(SwiftUI)
  import SwiftUI
  #if canImport(UIKit)
    import UIKit

    /// The platform's main view type.
    /// Either `UIView` on iOS/tvOS or `NSView` on macOS.
    typealias NEViewType = UIView

    /// The platform's SwiftUI view representable type.
    /// Either `UIViewRepresentable` on iOS/tvOS or `NSViewRepresentable` on macOS.
    @available(iOS 13.0, tvOS 13.0, *)
    typealias NEViewRepresentableType = UIViewRepresentable

    /// The platform's layout constraint priority type.
    /// Either `UILayoutPriority` on iOS/tvOS or `NSLayoutConstraint.Priority` on macOS.
    typealias NELayoutPriorityType = UILayoutPriority

    @available(iOS 13.0, tvOS 13.0, *)
    extension NEViewRepresentableType {
      /// The platform's view type for `NEViewRepresentableType`.
      /// Either `UIViewType` on iOS/tvOS or `NSViewType` on macOS.
      typealias RepresentableViewType = UIViewType
    }

  #elseif canImport(AppKit)
    import AppKit

    /// The platform's main view type.
    /// Either `UIView` on iOS/tvOS, or `NSView` on macOS.
    typealias NEViewType = NSView

    /// The platform's SwiftUI view representable type.
    /// Either `UIViewRepresentable` on iOS/tvOS, or `NSViewRepresentable` on macOS.
    @available(macOS 10.15, *)
    typealias NEViewRepresentableType = NSViewRepresentable

    /// The platform's layout constraint priority type.
    /// Either `UILayoutPriority` on iOS/tvOS, or `NSLayoutConstraint.Priority` on macOS.
    typealias NELayoutPriorityType = NSLayoutConstraint.Priority

    @available(macOS 10.15, *)
    extension NEViewRepresentableType {
      /// The platform's view type for `NEViewRepresentableType`.
      /// Either `UIViewType` on iOS/tvOS or `NSViewType` on macOS.
      typealias RepresentableViewType = NSViewType
    }
  #endif
#endif
