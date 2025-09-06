// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#if canImport(SwiftUI)
  import SwiftUI

  // MARK: - View

  @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
  extension View {
    /// Applies the layout margins from the parent `NEEpoxySwiftUIHostingView` to this `View`, if there
    /// are any.
    ///
    /// Can be used to have a background in SwiftUI underlap the safe area within a bar installer, for
    /// example.
    ///
    /// These margins are propagated via the `EnvironmentValues.epoxyLayoutMargins`.
    func epoxyLayoutMargins() -> some View {
      modifier(NEEpoxyLayoutMarginsPadding())
    }
  }

  // MARK: - EnvironmentValues

  @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
  extension EnvironmentValues {
    /// The layout margins of the parent `NEEpoxySwiftUIHostingView`, else zero if there is none.
    var epoxyLayoutMargins: EdgeInsets {
      get { self[EpoxyLayoutMarginsKey.self] }
      set { self[EpoxyLayoutMarginsKey.self] = newValue }
    }
  }

  // MARK: - EpoxyLayoutMarginsKey

  @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
  private struct EpoxyLayoutMarginsKey: EnvironmentKey {
    static let defaultValue = EdgeInsets()
  }

  // MARK: - NEEpoxyLayoutMarginsPadding

  /// A view modifier that applies the layout margins from an enclosing `NEEpoxySwiftUIHostingView` to
  /// the modified `View`.
  @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
  private struct NEEpoxyLayoutMarginsPadding: ViewModifier {
    @Environment(\.epoxyLayoutMargins) var epoxyLayoutMargins

    func body(content: Content) -> some View {
      content.padding(epoxyLayoutMargins)
    }
  }
#endif
