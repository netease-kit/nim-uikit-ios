// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#if canImport(SwiftUI)
  import SwiftUI

  // MARK: - NEStyledView

  @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
  extension NEStyledView where Self: NEContentConfigurableView & NEBehaviorsConfigurableView {
    /// Returns a SwiftUI `View` representing this `NEEpoxyableView`.
    ///
    /// To perform additional configuration of the `NEEpoxyableView` instance, call `configure` on the
    /// returned SwiftUI `View`:
    /// ```
    /// MyView.swiftUIView(…)
    ///   .configure { context in
    ///     context.view.doSomething()
    ///   }
    /// ```
    ///
    /// To configure the sizing behavior of the `NEEpoxyableView` instance, call `sizing` on the
    /// returned SwiftUI `View`:
    /// ```
    /// MyView.swiftUIView(…).sizing(.intrinsicSize)
    /// ```
    static func swiftUIView(content: Content,
                            style: Style,
                            behaviors: Behaviors? = nil)
      -> NESwiftUIView<Self, (content: Content, style: Style)> {
      NESwiftUIView(storage: (content: content, style: style)) {
        let view = Self(style: style)
        view.setContent(content, animated: false)
        return view
      }
      .configure { context in
        // We need to create a new view instance when the style changes.
        if context.oldStorage.style != style {
          context.view = Self(style: style)
          context.view.setContent(content, animated: context.animated)
        }
        // Otherwise, if the just the content changes, we need to update it.
        else if context.oldStorage.content != content {
          context.view.setContent(content, animated: context.animated)
          context.container.invalidateIntrinsicContentSize()
        }

        context.view.setBehaviors(behaviors)
      }
    }
  }

  @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
  extension NEStyledView
    where
    Self: NEContentConfigurableView & NEBehaviorsConfigurableView,
    Style == Never {
    /// Returns a SwiftUI `View` representing this `NEEpoxyableView`.
    ///
    /// To perform additional configuration of the `NEEpoxyableView` instance, call `configure` on the
    /// returned SwiftUI `View`:
    /// ```
    /// MyView.swiftUIView(…)
    ///   .configure { context in
    ///     context.view.doSomething()
    ///   }
    /// ```
    ///
    /// To configure the sizing behavior of the `NEEpoxyableView` instance, call `sizing` on the
    /// returned SwiftUI `View`:
    /// ```
    /// MyView.swiftUIView(…).sizing(.intrinsicSize)
    /// ```
    static func swiftUIView(content: Content,
                            behaviors: Behaviors? = nil)
      -> NESwiftUIView<Self, Content> {
      NESwiftUIView(storage: content) {
        let view = Self()
        view.setContent(content, animated: false)
        return view
      }
      .configure { context in
        // We need to update the content of the existing view when the content is updated.
        if context.oldStorage != content {
          context.view.setContent(content, animated: context.animated)
          context.container.invalidateIntrinsicContentSize()
        }

        context.view.setBehaviors(behaviors)
      }
    }
  }

  @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
  extension NEStyledView
    where
    Self: NEContentConfigurableView & NEBehaviorsConfigurableView,
    Content == Never {
    /// Returns a SwiftUI `View` representing this `NEEpoxyableView`.
    ///
    /// To perform additional configuration of the `NEEpoxyableView` instance, call `configure` on the
    /// returned SwiftUI `View`:
    /// ```
    /// MyView.swiftUIView(…)
    ///   .configure { context in
    ///     context.view.doSomething()
    ///   }
    /// ```
    ///
    /// To configure the sizing behavior of the `NEEpoxyableView` instance, call `sizing` on the
    /// returned SwiftUI `View`:
    /// ```
    /// MyView.swiftUIView(…).sizing(.intrinsicSize)
    /// ```
    /// The sizing defaults to `.automatic`.
    static func swiftUIView(style: Style,
                            behaviors: Behaviors? = nil)
      -> NESwiftUIView<Self, Style> {
      NESwiftUIView(storage: style) {
        Self(style: style)
      }
      .configure { context in
        // We need to create a new view instance when the style changes.
        if context.oldStorage != style {
          context.view = Self(style: style)
        }

        context.view.setBehaviors(behaviors)
      }
    }
  }

  @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
  extension NEStyledView
    where
    Self: NEContentConfigurableView & NEBehaviorsConfigurableView,
    Content == Never,
    Style == Never {
    /// Returns a SwiftUI `View` representing this `NEEpoxyableView`.
    ///
    /// To perform additional configuration of the `NEEpoxyableView` instance, call `configure` on the
    /// returned SwiftUI `View`:
    /// ```
    /// MyView.swiftUIView(…)
    ///   .configure { context in
    ///     context.view.doSomething()
    ///   }
    /// ```
    ///
    /// To configure the sizing behavior of the `NEEpoxyableView` instance, call `sizing` on the
    /// returned SwiftUI `View`:
    /// ```
    /// MyView.swiftUIView(…).sizing(.intrinsicSize)
    /// ```
    /// The sizing defaults to `.automatic`.
    static func swiftUIView(behaviors: Behaviors? = nil) -> NESwiftUIView<Self, Void> {
      NESwiftUIView {
        Self()
      }
      .configure { context in
        context.view.setBehaviors(behaviors)
      }
    }
  }
#endif
