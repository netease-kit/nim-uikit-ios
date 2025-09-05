
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
  import UIKit

  /// An Objective-C compatible wrapper around Lottie's Animation class.
  /// Use in tandem with NECompatibleAnimationView when using Lottie in Objective-C
  @objc
  public final class NECompatibleAnimation: NSObject {
    // MARK: Lifecycle

    @objc
    public init(name: String,
                subdirectory: String? = nil,
                bundle: Bundle = Bundle.main) {
      self.name = name
      self.subdirectory = subdirectory
      self.bundle = bundle
      super.init()
    }

    // MARK: Internal

    var animation: NELottieAnimation? {
      NELottieAnimation.named(name, bundle: bundle, subdirectory: subdirectory)
    }

    @objc
    static func named(_ name: String) -> NECompatibleAnimation {
      NECompatibleAnimation(name: name)
    }

    // MARK: Private

    private let name: String
    private let subdirectory: String?
    private let bundle: Bundle
  }

  /// An Objective-C compatible wrapper around Lottie's NERenderingEngineOption enum. Pass in an option
  /// to the NECompatibleAnimationView initializers to configure the rendering engine for the view.
  @objc
  public enum NECompatibleRenderingEngineOption: Int {
    /// Uses the rendering engine specified in NELottieConfiguration.shared.
    case shared

    /// Uses the library default rendering engine, coreAnimation.
    case defaultEngine

    /// Optimizes rendering performance by using the Core Animation rendering engine for animations it
    /// can render while falling back to the main thread renderer for all other animations.
    case automatic

    /// Only renders animations using the main thread rendering engine.
    case mainThread

    /// Only renders animations using the Core Animation rendering engine. Those animations that use
    /// features not yet supported on this renderer will not be rendered.
    case coreAnimation

    // MARK: Public

    /// Converts a NECompatibleRenderingEngineOption to the corresponding NELottieConfiguration for
    /// internal rendering engine configuration.
    public static func generateLottieConfiguration(
      _ configuration: NECompatibleRenderingEngineOption)
      -> NELottieConfiguration {
      switch configuration {
      case .shared:
        return NELottieConfiguration.shared
      case .defaultEngine:
        return NELottieConfiguration(renderingEngine: .coreAnimation)
      case .automatic:
        return NELottieConfiguration(renderingEngine: .automatic)
      case .mainThread:
        return NELottieConfiguration(renderingEngine: .mainThread)
      case .coreAnimation:
        return NELottieConfiguration(renderingEngine: .coreAnimation)
      }
    }
  }

  /// An Objective-C compatible NEVersion of `NELottieBackgroundBehavior`.
  @objc
  public enum NECompatibleBackgroundBehavior: Int {
    /// Stop the animation and reset it to the beginning of its current play time. The completion block is called.
    case stop

    /// Pause the animation in its current state. The completion block is called.
    case pause

    /// Pause the animation and restart it when the application moves to the foreground.
    /// The completion block is stored and called when the animation completes.
    ///  - This is the default when using the Main Thread rendering engine.
    case pauseAndRestore

    /// Stops the animation and sets it to the end of its current play time. The completion block is called.
    case forceFinish

    /// The animation continues playing in the background.
    ///  - This is the default when using the Core Animation rendering engine.
    ///    Playing an animation using the Core Animation engine doesn't come with any CPU overhead,
    ///    so using `.continuePlaying` avoids the need to stop and then resume the animation
    ///    (which does come with some CPU overhead).
    ///  - This mode should not be used with the Main Thread rendering engine.
    case continuePlaying
  }

  /// An Objective-C compatible wrapper around Lottie's NELottieAnimationView.
  @objc
  public final class NECompatibleAnimationView: UIView {
    // MARK: Lifecycle

    /// Initializes a compatible AnimationView with a given compatible animation. Defaults to using
    /// the rendering engine specified in NELottieConfiguration.shared.
    @objc
    public convenience init(compatibleAnimation: NECompatibleAnimation) {
      self.init(compatibleAnimation: compatibleAnimation, compatibleRenderingEngineOption: .shared)
    }

    /// Initializes a compatible AnimationView with a given compatible animation and rendering engine
    /// configuration.
    @objc
    public init(compatibleAnimation: NECompatibleAnimation,
                compatibleRenderingEngineOption: NECompatibleRenderingEngineOption) {
      animationView = NELottieAnimationView(
        animation: compatibleAnimation.animation,
        configuration: NECompatibleRenderingEngineOption.generateLottieConfiguration(compatibleRenderingEngineOption)
      )
      self.compatibleAnimation = compatibleAnimation
      super.init(frame: .zero)
      commonInit()
    }

    /// Initializes a compatible AnimationView with the resources asynchronously loaded from a given
    /// URL. Defaults to using the rendering engine specified in NELottieConfiguration.shared.
    @objc
    public convenience init(url: URL) {
      self.init(url: url, compatibleRenderingEngineOption: .shared)
    }

    /// Initializes a compatible AnimationView with the resources asynchronously loaded from a given
    /// URL using the given rendering engine configuration.
    @objc
    public init(url: URL, compatibleRenderingEngineOption: NECompatibleRenderingEngineOption) {
      animationView = NELottieAnimationView(
        url: url,
        closure: { _ in },
        configuration: NECompatibleRenderingEngineOption.generateLottieConfiguration(compatibleRenderingEngineOption)
      )
      super.init(frame: .zero)
      commonInit()
    }

    /// Initializes a compatible AnimationView from a given Data object specifying the Lottie
    /// animation. Defaults to using the rendering engine specified in NELottieConfiguration.shared.
    @objc
    public convenience init(data: Data) {
      self.init(data: data, compatibleRenderingEngineOption: .shared)
    }

    /// Initializes a compatible AnimationView from a given Data object specifying the Lottie
    /// animation using the given rendering engine configuration.
    @objc
    public init(data: Data, compatibleRenderingEngineOption: NECompatibleRenderingEngineOption) {
      if let animation = try? NELottieAnimation.from(data: data) {
        animationView = NELottieAnimationView(
          animation: animation,
          configuration: NECompatibleRenderingEngineOption.generateLottieConfiguration(compatibleRenderingEngineOption)
        )
      } else {
        animationView = NELottieAnimationView(
          configuration: NECompatibleRenderingEngineOption.generateLottieConfiguration(compatibleRenderingEngineOption))
      }
      super.init(frame: .zero)
      commonInit()
    }

    @objc
    override public init(frame: CGRect) {
      animationView = NELottieAnimationView()
      super.init(frame: frame)
      commonInit()
    }

    required init?(coder: NSCoder) {
      animationView = NELottieAnimationView()
      super.init(coder: coder)
      commonInit()
    }

    // MARK: Public

    @objc public var compatibleAnimation: NECompatibleAnimation? {
      didSet {
        animationView.animation = compatibleAnimation?.animation
      }
    }

    @objc public var loopAnimationCount: CGFloat = 0 {
      didSet {
        animationView.loopMode = loopAnimationCount == -1 ? .loop : .repeat(Float(loopAnimationCount))
      }
    }

    @objc public var compatibleDictionaryTextProvider: NECompatibleDictionaryTextProvider? {
      didSet {
        animationView.textProvider = compatibleDictionaryTextProvider?.textProvider ?? NEDefaultTextProvider()
      }
    }

    @objc override public var contentMode: UIView.ContentMode {
      set { animationView.contentMode = newValue }
      get { animationView.contentMode }
    }

    @objc
    public var shouldRasterizeWhenIdle: Bool {
      set { animationView.shouldRasterizeWhenIdle = newValue }
      get { animationView.shouldRasterizeWhenIdle }
    }

    @objc
    public var currentProgress: CGFloat {
      set { animationView.currentProgress = newValue }
      get { animationView.currentProgress }
    }

    @objc
    public var duration: CGFloat {
      animationView.animation?.duration ?? 0.0
    }

    @objc
    public var currentTime: TimeInterval {
      set { animationView.currentTime = newValue }
      get { animationView.currentTime }
    }

    @objc
    public var currentFrame: CGFloat {
      set { animationView.currentFrame = newValue }
      get { animationView.currentFrame }
    }

    @objc
    public var realtimeAnimationFrame: CGFloat {
      animationView.realtimeAnimationFrame
    }

    @objc
    public var realtimeAnimationProgress: CGFloat {
      animationView.realtimeAnimationProgress
    }

    @objc
    public var animationSpeed: CGFloat {
      set { animationView.animationSpeed = newValue }
      get { animationView.animationSpeed }
    }

    @objc
    public var respectAnimationFrameRate: Bool {
      set { animationView.respectAnimationFrameRate = newValue }
      get { animationView.respectAnimationFrameRate }
    }

    @objc
    public var isAnimationPlaying: Bool {
      animationView.isAnimationPlaying
    }

    @objc
    public var backgroundMode: NECompatibleBackgroundBehavior {
      get {
        switch animationView.backgroundBehavior {
        case .stop:
          return .stop
        case .pause:
          return .pause
        case .pauseAndRestore:
          return .pauseAndRestore
        case .forceFinish:
          return .forceFinish
        case .continuePlaying:
          return .continuePlaying
        }
      }
      set {
        switch newValue {
        case .stop:
          animationView.backgroundBehavior = .stop
        case .pause:
          animationView.backgroundBehavior = .pause
        case .pauseAndRestore:
          animationView.backgroundBehavior = .pauseAndRestore
        case .forceFinish:
          animationView.backgroundBehavior = .forceFinish
        case .continuePlaying:
          animationView.backgroundBehavior = .continuePlaying
        }
      }
    }

    @objc
    public func play() {
      play(completion: nil)
    }

    @objc
    public func play(completion: ((Bool) -> Void)?) {
      animationView.play(completion: completion)
    }

    /// Note: When calling this code from Objective-C, the method signature is
    /// playFromProgress:toProgress:completion which drops the standard "With" naming convention.
    @objc
    public func play(fromProgress: CGFloat,
                     toProgress: CGFloat,
                     completion: ((Bool) -> Void)? = nil) {
      animationView.play(
        fromProgress: fromProgress,
        toProgress: toProgress,
        loopMode: nil,
        completion: completion
      )
    }

    /// Note: When calling this code from Objective-C, the method signature is
    /// playFromFrame:toFrame:completion which drops the standard "With" naming convention.
    @objc
    public func play(fromFrame: CGFloat,
                     toFrame: CGFloat,
                     completion: ((Bool) -> Void)? = nil) {
      animationView.play(
        fromFrame: fromFrame,
        toFrame: toFrame,
        loopMode: nil,
        completion: completion
      )
    }

    /// Note: When calling this code from Objective-C, the method signature is
    /// playFromMarker:toMarker:completion which drops the standard "With" naming convention.
    @objc
    public func play(fromMarker: String,
                     toMarker: String,
                     completion: ((Bool) -> Void)? = nil) {
      animationView.play(
        fromMarker: fromMarker,
        toMarker: toMarker,
        completion: completion
      )
    }

    @objc
    public func play(marker: String,
                     completion: ((Bool) -> Void)? = nil) {
      animationView.play(
        marker: marker,
        completion: completion
      )
    }

    @objc
    public func stop() {
      animationView.stop()
    }

    @objc
    public func pause() {
      animationView.pause()
    }

    @objc
    public func reloadImages() {
      animationView.reloadImages()
    }

    @objc
    public func forceDisplayUpdate() {
      animationView.forceDisplayUpdate()
    }

    @objc
    public func getValue(for keypath: NECompatibleAnimationKeypath,
                         atFrame: CGFloat)
      -> Any? {
      animationView.getValue(
        for: keypath.animationKeypath,
        atFrame: atFrame
      )
    }

    @objc
    public func logHierarchyKeypaths() {
      animationView.logHierarchyKeypaths()
    }

    @objc
    public func setColorValue(_ color: UIColor, forKeypath keypath: NECompatibleAnimationKeypath) {
      var red: CGFloat = 0
      var green: CGFloat = 0
      var blue: CGFloat = 0
      var alpha: CGFloat = 0

      let colorspace = NELottieConfiguration.shared.colorSpace

      let convertedColor = color.cgColor.converted(to: colorspace, intent: .defaultIntent, options: nil)

      if let components = convertedColor?.components, components.count == 4 {
        red = components[0]
        green = components[1]
        blue = components[2]
        alpha = components[3]
      } else {
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
      }

      let valueProvider = NEColorValueProvider(NELottieColor(r: Double(red), g: Double(green), b: Double(blue), a: Double(alpha)))
      animationView.setValueProvider(valueProvider, keypath: keypath.animationKeypath)
    }

    @objc
    public func getColorValue(for keypath: NECompatibleAnimationKeypath, atFrame: CGFloat) -> UIColor? {
      let value = animationView.getValue(for: keypath.animationKeypath, atFrame: atFrame)
      guard let colorValue = value as? NELottieColor else {
        return nil
      }

      return UIColor(
        red: CGFloat(colorValue.r),
        green: CGFloat(colorValue.g),
        blue: CGFloat(colorValue.b),
        alpha: CGFloat(colorValue.a)
      )
    }

    @objc
    public func addSubview(_ subview: NEAnimationSubview,
                           forLayerAt keypath: NECompatibleAnimationKeypath) {
      animationView.addSubview(
        subview,
        forLayerAt: keypath.animationKeypath
      )
    }

    @objc
    public func convert(rect: CGRect,
                        toLayerAt keypath: NECompatibleAnimationKeypath?)
      -> CGRect {
      animationView.convert(
        rect,
        toLayerAt: keypath?.animationKeypath
      ) ?? .zero
    }

    @objc
    public func convert(point: CGPoint,
                        toLayerAt keypath: NECompatibleAnimationKeypath?)
      -> CGPoint {
      animationView.convert(
        point,
        toLayerAt: keypath?.animationKeypath
      ) ?? .zero
    }

    @objc
    public func progressTime(forMarker named: String) -> CGFloat {
      animationView.progressTime(forMarker: named) ?? 0
    }

    @objc
    public func frameTime(forMarker named: String) -> CGFloat {
      animationView.frameTime(forMarker: named) ?? 0
    }

    @objc
    public func durationFrameTime(forMarker named: String) -> CGFloat {
      animationView.durationFrameTime(forMarker: named) ?? 0
    }

    // MARK: Private

    private let animationView: NELottieAnimationView

    private func commonInit() {
      setUpViews()
    }

    private func setUpViews() {
      animationView.translatesAutoresizingMaskIntoConstraints = false
      addSubview(animationView)
      animationView.topAnchor.constraint(equalTo: topAnchor).isActive = true
      animationView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
      animationView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
      animationView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
  }

  /// An Objective-C compatible wrapper around Lottie's NEDictionaryTextProvider.
  /// Use in tandem with NECompatibleAnimationView to supply text to NELottieAnimationView
  /// when using Lottie in Objective-C.
  @objc
  public final class NECompatibleDictionaryTextProvider: NSObject {
    // MARK: Lifecycle

    @objc
    public init(values: [String: String]) {
      self.values = values
      super.init()
    }

    // MARK: Internal

    var textProvider: NEAnimationKeypathTextProvider? {
      NEDictionaryTextProvider(values)
    }

    // MARK: Private

    private let values: [String: String]
  }
#endif
