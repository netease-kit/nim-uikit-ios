// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#if canImport(SwiftUI) && !os(macOS)
  import SwiftUI

  // MARK: - EpoxySwiftUIUIHostingController

  /// A `UIHostingController` that hosts SwiftUI views within an Epoxy container, e.g. an Epoxy
  /// `CollectionView`.
  ///
  /// Exposed internally to allow consumers to reason about these view controllers, e.g. to opt
  /// collection view cells out of automated view controller impression tracking.
  ///
  /// - SeeAlso: `NEEpoxySwiftUIHostingView`
  @available(iOS 13.0, tvOS 13.0, *)
  open class NEEpoxySwiftUIHostingController<Content: View>: UIHostingController<Content> {
    // MARK: Lifecycle

    /// Creates a `UIHostingController` that optionally ignores the `safeAreaInsets` when laying out
    /// its contained `RootView`.
    convenience init(rootView: Content, ignoreSafeArea: Bool) {
      self.init(rootView: rootView)

      // We unfortunately need to call a private API to disable the safe area. We can also accomplish
      // this by dynamically subclassing this view controller's view at runtime and overriding its
      // `safeAreaInsets` property and returning `.zero`. An implementation of that logic is
      // available in this file in the `2d28b3181cca50b89618b54836f7a9b6e36ea78e` commit if this API
      // no longer functions in future SwiftUI NEVersions.
      _disableSafeArea = ignoreSafeArea
    }

    // MARK: Open

    override open func viewDidLoad() {
      super.viewDidLoad()

      // A `UIHostingController` has a system background color by default as it's typically used in
      // full-screen use cases. Since we're using this view controller to place SwiftUI views within
      // other view controllers we default the background color to clear so we can see the views
      // below, e.g. to draw highlight states in a `CollectionView`.
      view.backgroundColor = .clear
    }
  }
#endif
