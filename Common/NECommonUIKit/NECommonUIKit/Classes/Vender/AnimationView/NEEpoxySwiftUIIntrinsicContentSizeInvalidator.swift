// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#if canImport(SwiftUI)
  import SwiftUI

  // MARK: - NEEpoxyIntrinsicContentSizeInvalidator

  /// Allows the SwiftUI view contained in an Epoxy model to request the invalidation of
  /// the container's intrinsic content size.
  ///
  /// ```
  /// @Environment(\.epoxyIntrinsicContentSizeInvalidator) var invalidateIntrinsicContentSize
  ///
  /// var body: some View {
  ///   ...
  ///   .onChange(of: size) {
  ///     invalidateIntrinsicContentSize()
  ///   }
  /// }
  /// ```
  struct NEEpoxyIntrinsicContentSizeInvalidator {
    let invalidate: () -> Void

    func callAsFunction() {
      invalidate()
    }
  }

  // MARK: - EnvironmentValues

  @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
  extension EnvironmentValues {
    /// A means of invalidating the intrinsic content size of the parent `NEEpoxySwiftUIHostingView`.
    var epoxyIntrinsicContentSizeInvalidator: NEEpoxyIntrinsicContentSizeInvalidator {
      get { self[NEEpoxyIntrinsicContentSizeInvalidatorKey.self] }
      set { self[NEEpoxyIntrinsicContentSizeInvalidatorKey.self] = newValue }
    }
  }

  // MARK: - NEEpoxyIntrinsicContentSizeInvalidatorKey

  private struct NEEpoxyIntrinsicContentSizeInvalidatorKey: EnvironmentKey {
    static let defaultValue = NEEpoxyIntrinsicContentSizeInvalidator(invalidate: {})
  }
#endif
