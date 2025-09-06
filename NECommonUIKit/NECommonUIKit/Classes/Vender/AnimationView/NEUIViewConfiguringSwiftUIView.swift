// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#if canImport(SwiftUI)
  import SwiftUI

  // MARK: - NEUIViewConfiguringSwiftUIView

  /// A protocol describing a SwiftUI `View` that can configure its `UIView` content via an array of
  /// `configuration` closures.
  @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
  protocol NEUIViewConfiguringSwiftUIView: View {
    /// The context available to this configuration, which provides the `UIView` instance at a minimum
    /// but can include additional context as needed.
    associatedtype ConfigurationContext: NEViewProviding

    /// A closure that is invoked to configure the represented content view.
    typealias Configuration = (ConfigurationContext) -> Void

    /// A mutable array of configuration closures that should each be invoked with the
    /// `ConfigurationContext` whenever `updateUIView` is called in a `UIViewRepresentable`.
    var configurations: [Configuration] { get set }
  }

  // MARK: Extensions

  @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
  extension NEUIViewConfiguringSwiftUIView {
    /// Returns a copy of this view updated to have the given closure applied to its represented view
    /// whenever it is updated via the `updateUIView(…)` method.
    func configure(_ configure: @escaping Configuration) -> Self {
      var copy = self
      copy.configurations.append(configure)
      return copy
    }

    /// Returns a copy of this view updated to have the given closures applied to its represented view
    /// whenever it is updated via the `updateUIView(…)` method.
    func configurations(_ configurations: [Configuration]) -> Self {
      var copy = self
      copy.configurations.append(contentsOf: configurations)
      return copy
    }
  }
#endif
