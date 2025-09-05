// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#if canImport(SwiftUI)
  import SwiftUI

  /// A wrapper which exposes Lottie's `NEAnimatedButton` to SwiftUI
  @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
  public struct NELottieButton: NEUIViewConfiguringSwiftUIView {
    // MARK: Lifecycle

    public init(animation: NELottieAnimation?, action: @escaping () -> Void) {
      self.animation = animation
      self.action = action
    }

    // MARK: Public

    public var body: some View {
      NEAnimatedButton.swiftUIView {
        let button = NEAnimatedButton(animation: animation, configuration: configuration)
        button.performAction = action
        return button
      }
      .configure { context in
        // We check referential equality of the animation before updating as updating the
        // animation has a side-effect of rebuilding the animation layer, and it would be
        // prohibitive to do so on every state update.
        if animation !== context.view.animationView.animation {
          context.view.animationView.animation = animation
        }

        #if os(macOS)
          // Disable the intrinsic content size constraint on the inner animation view,
          // or the Epoxy `NESwiftUIMeasurementContainer` won't size this view correctly.
          context.view.animationView.isVerticalContentSizeConstraintActive = false
          context.view.animationView.isHorizontalContentSizeConstraintActive = false
        #endif
      }
      .configurations(configurations)
    }

    /// Returns a copy of this `NELottieView` updated to have the given closure applied to its
    /// represented `NELottieAnimationView` whenever it is updated via the `updateUIView(…)`
    /// or `updateNSView(…)` method.
    public func configure(_ configure: @escaping (NEAnimatedButton) -> Void) -> Self {
      var copy = self
      copy.configurations.append { context in
        configure(context.view)
      }
      return copy
    }

    /// Returns a copy of this view with its `NELottieConfiguration` updated to the given value.
    public func configuration(_ configuration: NELottieConfiguration) -> Self {
      var copy = self
      copy.configuration = configuration

      copy = copy.configure { view in
        if view.animationView.configuration != configuration {
          view.animationView.configuration = configuration
        }
      }

      return copy
    }

    /// Returns a copy of this view configured to animate between the
    /// given progress values when the given event is triggered
    public func animate(fromProgress: NEAnimationProgressTime,
                        toProgress: NEAnimationProgressTime,
                        on event: NELottieControlEvent)
      -> Self {
      configure { view in
        // `setPlayRange` just modifies a dictionary,
        // so we can just call it on every state update without diffing
        view.setPlayRange(fromProgress: fromProgress, toProgress: toProgress, event: event)
      }
    }

    /// Returns a copy of this view configured to animate between the
    /// given markers when the given event is triggered
    public func animate(fromMarker: String,
                        toMarker: String,
                        on event: NELottieControlEvent)
      -> Self {
      configure { view in
        // `setPlayRange` just modifies a dictionary,
        // so we can just call it on every state update without diffing
        view.setPlayRange(fromMarker: fromMarker, toMarker: toMarker, event: event)
      }
    }

    /// Returns a copy of this view using the given value provider for the given keypath.
    /// The value provider must be `Equatable` to avoid unnecessary state updates / re-renders.
    public func valueProvider<NEValueProvider: NEAnyValueProvider & Equatable>(_ valueProvider: NEValueProvider,
                                                                               for keypath: NEAnimationKeypath)
      -> Self {
      configure { view in
        if (view.animationView.valueProviders[keypath] as? NEValueProvider) != valueProvider {
          view.animationView.setValueProvider(valueProvider, keypath: keypath)
        }
      }
    }

    // MARK: Internal

    var configurations = [NESwiftUIView<NEAnimatedButton, Void>.Configuration]()

    // MARK: Private

    private let animation: NELottieAnimation?
    private let action: () -> Void
    private var configuration: NELottieConfiguration = .shared
  }
#endif
