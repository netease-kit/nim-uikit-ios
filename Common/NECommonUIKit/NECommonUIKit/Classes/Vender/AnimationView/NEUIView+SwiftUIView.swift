// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#if canImport(SwiftUI)
  import SwiftUI

  // MARK: - NEViewTypeProtocol + swiftUIView

  @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
  extension NEViewTypeProtocol {
    /// Returns a SwiftUI `View` representing this `UIView`, constructed with the given `makeView`
    /// closure and sized with the given sizing configuration.
    ///
    /// To perform additional configuration of the `UIView` instance, call `configure` on the
    /// returned SwiftUI `View`:
    /// ```
    /// MyUIView.swiftUIView(…)
    ///   .configure { context in
    ///     context.view.doSomething()
    ///   }
    /// ```
    ///
    /// To configure the sizing behavior of the `UIView` instance, call `sizing` on the returned
    /// SwiftUI `View`:
    /// ```
    /// MyView.swiftUIView(…).sizing(.intrinsicSize)
    /// ```
    /// The sizing defaults to `.automatic`.
    static func swiftUIView(makeView: @escaping () -> Self) -> NESwiftUIView<Self, Void> {
      NESwiftUIView(makeContent: makeView)
    }
  }

  // MARK: - NEViewTypeProtocol

  /// A protocol that all `UIView`s conform to, enabling extensions that have a `Self` reference.
  protocol NEViewTypeProtocol: NEViewType {}

  // MARK: - NEViewType + NEViewTypeProtocol

  extension NEViewType: NEViewTypeProtocol {}
#endif
