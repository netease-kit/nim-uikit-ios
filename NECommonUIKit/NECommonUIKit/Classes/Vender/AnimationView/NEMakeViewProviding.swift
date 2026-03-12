// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEMakeViewProviding

/// The capability of constructing a `UIView`.
protocol NEMakeViewProviding {
  /// The view constructed when the `MakeView` closure is called.
  associatedtype View: NEViewType

  /// A closure that's called to construct an instance of `View`.
  typealias MakeView = () -> View

  /// A closure that's called to construct an instance of `View`.
  var makeView: MakeView { get }
}

// MARK: - NEViewEpoxyModeled

extension NEViewEpoxyModeled where Self: NEMakeViewProviding {
  // MARK: Internal

  /// A closure that's called to construct an instance of `View` represented by this model.
  var makeView: MakeView {
    get { self[makeViewProperty] }
    set { self[makeViewProperty] = newValue }
  }

  /// Replaces the default closure to construct the view with the given closure.
  func makeView(_ value: @escaping MakeView) -> Self {
    copy(updating: makeViewProperty, to: value)
  }

  // MARK: Private

  private var makeViewProperty: NEEpoxyModelProperty<MakeView> {
    // If you're getting a `EXC_BAD_INSTRUCTION` crash with this property in your stack trace, you
    // probably either:
    // - Conformed a view to `NEEpoxyableView` / `NEStyledView` with a custom initializer that
    // takes parameters, or:
    // - Used the `NEEpoxyModeled.init(dataID:)` initializer on a view has required initializer
    //   parameters.
    // If you have parameters to view initialization, they should either be passed to `init(style:)`
    // or you should provide a `makeView` closure when constructing your view's corresponding model,
    // e.g:
    // ```
    // MyView.itemModel(…)
    //   .makeView { MyView(customParameter: …) }
    //   .styleID(…)
    // ```
    // Note that with the above approach that you must supply an `styleID` with the same identity as
    // your view parameters to ensure that views with different parameters are not reused in place
    // of one another.
    .init(
      keyPath: \Self.makeView,
      defaultValue: View.init,
      updateStrategy: .replace
    )
  }
}
