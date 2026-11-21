import CoreGraphics
import Foundation

public enum NEWindowSizeClass: Equatable {
  case unspecified, compact, regular
}

/// 当前激活的系统占位区（折叠区 / 摄像头遮挡等）的快照。
///
/// 只用于判断窗口几何是否发生变化并触发一次刷新，不直接参与页面或
/// rail 的尺寸计算；布局仍读取实时 `reservedRegions`。
public struct NEReservedRegionSnapshot: Equatable {
  public enum Kind: Equatable {
    case occlusion
    case division
  }

  public let kind: Kind
  public let frame: CGRect

  public init(kind: Kind, frame: CGRect) {
    self.kind = kind
    self.frame = frame
  }

  public static func == (lhs: NEReservedRegionSnapshot, rhs: NEReservedRegionSnapshot) -> Bool {
    lhs.kind == rhs.kind &&
      lhs.frame.origin.x == rhs.frame.origin.x &&
      lhs.frame.origin.y == rhs.frame.origin.y &&
      lhs.frame.size.width == rhs.frame.size.width &&
      lhs.frame.size.height == rhs.frame.size.height
  }
}

public struct NEWindowSnapshot: Equatable {
  public let size: CGSize
  public let safeAreaTop: CGFloat
  public let safeAreaLeft: CGFloat
  public let safeAreaBottom: CGFloat
  public let safeAreaRight: CGFloat
  public let horizontalSizeClass: NEWindowSizeClass
  public let verticalSizeClass: NEWindowSizeClass
  /// 窗口所在屏幕的 display scale。
  public let displayScale: CGFloat
  /// 当前激活的 division / occlusion 占位区，按类别与位置稳定排序。
  public let reservedRegions: [NEReservedRegionSnapshot]
  public init(size: CGSize, safeAreaTop: CGFloat, safeAreaLeft: CGFloat, safeAreaBottom: CGFloat, safeAreaRight: CGFloat,
              horizontalSizeClass: NEWindowSizeClass, verticalSizeClass: NEWindowSizeClass,
              displayScale: CGFloat = 0, reservedRegions: [NEReservedRegionSnapshot] = []) {
    self.size = size; self.safeAreaTop = safeAreaTop; self.safeAreaLeft = safeAreaLeft; self.safeAreaBottom = safeAreaBottom
    self.safeAreaRight = safeAreaRight; self.horizontalSizeClass = horizontalSizeClass; self.verticalSizeClass = verticalSizeClass
    self.displayScale = displayScale
    self.reservedRegions = reservedRegions
  }

  /// 占位区集合的稳定指纹，便于诊断与比较；相等性仍以 `reservedRegions` 为准。
  public var reservedRegionFingerprint: UInt64 {
    var hash: UInt64 = 0xcbf2_9ce4_8422_2325
    for region in reservedRegions {
      hash = Self.mix(hash, region.kind == .occlusion ? 1 : 2)
      hash = Self.mix(hash, Double(region.frame.minX).bitPattern)
      hash = Self.mix(hash, Double(region.frame.minY).bitPattern)
      hash = Self.mix(hash, Double(region.frame.width).bitPattern)
      hash = Self.mix(hash, Double(region.frame.height).bitPattern)
    }
    return hash
  }

  public static func == (lhs: NEWindowSnapshot, rhs: NEWindowSnapshot) -> Bool {
    lhs.size.width == rhs.size.width && lhs.size.height == rhs.size.height &&
      lhs.safeAreaTop == rhs.safeAreaTop && lhs.safeAreaLeft == rhs.safeAreaLeft &&
      lhs.safeAreaBottom == rhs.safeAreaBottom && lhs.safeAreaRight == rhs.safeAreaRight &&
      lhs.horizontalSizeClass == rhs.horizontalSizeClass && lhs.verticalSizeClass == rhs.verticalSizeClass &&
      lhs.displayScale == rhs.displayScale && lhs.reservedRegions == rhs.reservedRegions
  }

  private static func mix(_ hash: UInt64, _ value: UInt64) -> UInt64 {
    (hash ^ value) &* 0x100_0000_01b3
  }
}

/// Hosts forward scene, root transition and safe-area updates to refresh().
public final class NEAdaptiveWindowContext {
  private var sample: (() -> NEWindowSnapshot?)?
  private var onChange: ((NEWindowSnapshot) -> Void)?
  private var isPublishing = false
  private var needsRefresh = false
  public private(set) var snapshot: NEWindowSnapshot?

  public init(sample: @escaping () -> NEWindowSnapshot?, onChange: @escaping (NEWindowSnapshot) -> Void) {
    precondition(Thread.isMainThread)
    self.sample = sample
    self.onChange = onChange
  }

  public func refresh() {
    precondition(Thread.isMainThread)
    guard sample != nil else { return }
    if isPublishing {
      needsRefresh = true
      return
    }
    isPublishing = true
    defer { isPublishing = false }
    // Reentrant refreshes sample only after the current consumer finishes.
    repeat {
      needsRefresh = false
      guard let sample else { break }
      let next = sample()
      guard self.sample != nil else { break }
      guard next != snapshot else {
        #if canImport(UIKit)
          // 去重是"安全区变化被吞掉"最可疑的入口：即使这里 continue，也要留下痕迹
          // （verbose 打开后才写），便于和外壳的 layout 日志对齐。
          NEAdaptiveDiagnostics.shared.logVerbose("context", "dedupe \(Self.summary(next))")
        #endif
        continue
      }
      snapshot = next
      #if canImport(UIKit)
        NEAdaptiveDiagnostics.shared.log("context", "change \(Self.summary(next))")
      #endif
      if let next { onChange?(next) }
    } while needsRefresh
  }

  static func summary(_ snapshot: NEWindowSnapshot?) -> String {
    guard let snapshot else { return "nil" }
    func sizeClass(_ value: NEWindowSizeClass) -> String {
      switch value {
      case .compact: return "c"
      case .regular: return "r"
      case .unspecified: return "u"
      }
    }
    return "size=\(String(format: "%.1fx%.1f", snapshot.size.width, snapshot.size.height)) "
      + "safe=\(String(format: "t%.1f l%.1f b%.1f r%.1f", snapshot.safeAreaTop, snapshot.safeAreaLeft, snapshot.safeAreaBottom, snapshot.safeAreaRight)) "
      + "class=\(sizeClass(snapshot.horizontalSizeClass))/\(sizeClass(snapshot.verticalSizeClass)) "
      + "scale=\(String(format: "%.2f", snapshot.displayScale)) regions=\(snapshot.reservedRegions.count)"
  }

  public func invalidate() {
    precondition(Thread.isMainThread)
    sample = nil
    onChange = nil
    snapshot = nil
    needsRefresh = false
  }
}

#if canImport(UIKit)
  import UIKit

  public extension NEAdaptiveWindowContext {
    /// 只采窗口事实（既有行为）。
    convenience init(window: UIWindow, onChange: @escaping (NEWindowSnapshot) -> Void) {
      self.init(window: window, samplingView: nil, onChange: onChange)
    }

    /// 在同一窗口内优先采 `samplingView` 的事实。
    ///
    /// 折叠/展开时窗口与视图的安全区会短暂不同步（真机实测 `view r88 / window r84`），
    /// 而布局读的是视图；若快照仍采窗口，就可能把“视图安全区已变”判成无变化、
    /// 跳过重排。传入外壳自己的 view 可让两者使用同一事实源。
    convenience init(window: UIWindow,
                     samplingView: UIView?,
                     onChange: @escaping (NEWindowSnapshot) -> Void) {
      self.init(sample: { [weak window, weak samplingView] in
        guard let window else { return nil }
        let sampler: UIView
        if let samplingView, samplingView.window === window {
          sampler = samplingView
        } else {
          sampler = window
        }
        let insets = sampler.safeAreaInsets
        return NEWindowSnapshot(
          size: sampler.bounds.size,
          safeAreaTop: insets.top,
          safeAreaLeft: insets.left,
          safeAreaBottom: insets.bottom,
          safeAreaRight: insets.right,
          horizontalSizeClass: NEWindowSizeClass(sampler.traitCollection.horizontalSizeClass),
          verticalSizeClass: NEWindowSizeClass(sampler.traitCollection.verticalSizeClass),
          displayScale: sampler.traitCollection.displayScale,
          reservedRegions: NEWindowSnapshot.activeReservedRegions(in: sampler)
        )
      }, onChange: onChange)
    }
  }

  extension NEWindowSnapshot {
    /// 读取视图当前激活的 division / occlusion 占位区。
    /// 同一类别内按坐标排序，避免系统返回顺序变化造成误判。
    static func activeReservedRegions(in view: UIView) -> [NEReservedRegionSnapshot] {
      guard #available(iOS 27.1, *) else { return [] }
      let occlusions = view.reservedRegions(kind: .occlusion)
        .filter(\.isActive)
        .map { NEReservedRegionSnapshot(kind: .occlusion, frame: $0.frame) }
      let divisions = view.reservedRegions(kind: .division)
        .filter(\.isActive)
        .map { NEReservedRegionSnapshot(kind: .division, frame: $0.frame) }
      return (occlusions + divisions).sorted { lhs, rhs in
        if lhs.kind != rhs.kind { return lhs.kind == .occlusion }
        if lhs.frame.minX != rhs.frame.minX { return lhs.frame.minX < rhs.frame.minX }
        if lhs.frame.minY != rhs.frame.minY { return lhs.frame.minY < rhs.frame.minY }
        if lhs.frame.width != rhs.frame.width { return lhs.frame.width < rhs.frame.width }
        return lhs.frame.height < rhs.frame.height
      }
    }
  }

  private extension NEWindowSizeClass {
    init(_ value: UIUserInterfaceSizeClass) {
      switch value {
      case .compact: self = .compact
      case .regular: self = .regular
      default: self = .unspecified
      }
    }
  }
#endif

#if canImport(UIKit)
  import Foundation
  import UIKit

  /// 折叠屏（Duo）真机排障诊断设施。
  ///
  /// 真机无法接调试器时，结论必须能"随 App 带走"：日志同时进控制台和
  /// `Documents/NEAdaptive.log`（Info.plist 打开 `UIFileSharingEnabled` 后可直接在
  /// 「文件」App / Finder 取出）。默认关闭，由宿主显式 `enable()`；未开启时所有
  /// 调用都是空操作，不影响普通设备。
  ///
  /// 约定：
  /// - 只依赖 Foundation/UIKit，不引用 SDK 日志组件（本模块需可独立发布）；
  /// - 主线程调用，文件写入失败不影响布局；
  /// - 同一类别相同内容在 `duplicateWindow` 内只记一次（直接丢弃，不补计数）。
  public final class NEAdaptiveDiagnostics: NSObject {
    public static let shared = NEAdaptiveDiagnostics()

    /// 宿主显式开启后才会写日志。
    public var isEnabled = false {
      didSet {
        guard isEnabled, !oldValue else { return }
        openFile()
        log("diag", "enabled file=\(fileURL?.path ?? "<none>") console=\(logToConsole)")
      }
    }

    /// 是否同时输出到控制台（Xcode / Console.app / sysdiagnose）。
    public var logToConsole = true
    /// 高频采样日志（窗口快照去重、每次布局输入）开关。
    public var isVerbose = false
    /// 单个日志文件上限，超出后轮转为 `<fileName>.1`。
    public var maximumFileSize = 1_000_000
    /// 相同内容抑制窗口（秒）。
    public var duplicateWindow: TimeInterval = 0.75
    /// 日志文件；`enable()` 后才存在。
    public private(set) var fileURL: URL?
    /// 已写入文件的日志行数。
    public private(set) var writtenLines = 0

    private var sequence: UInt64 = 0
    private var handle: FileHandle?
    private var ring: [String] = []
    private let ringLimit = 3000
    private var recentTimes: [String: TimeInterval] = [:]

    // MARK: - Public

    /// 开启诊断日志。`fileName` 位于 Documents 下。
    public func enable(fileName: String = "NEAdaptive.log") {
      if fileURL == nil {
        fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
          .first?.appendingPathComponent(fileName)
      }
      if isEnabled { openFile() } else { isEnabled = true }
    }

    /// 记录一条诊断日志；`message` 为 `@autoclosure`，未开启时不构造字符串。
    public func log(_ category: String, _ message: @autoclosure () -> String) {
      guard isEnabled else { return }
      guard Thread.isMainThread else {
        let text = message()
        DispatchQueue.main.async { [weak self] in self?.log(category, text) }
        return
      }
      let now = Date().timeIntervalSince1970
      let text = message()
      let key = category + "|" + text
      if let last = recentTimes[key], now - last < duplicateWindow { return }
      recentTimes[key] = now
      if recentTimes.count > 512 { recentTimes.removeAll(keepingCapacity: true) }
      sequence += 1
      let line = "\(Self.timeString(now)) #\(sequence) [\(category)] \(text)"
      ring.append(line)
      if ring.count > ringLimit { ring.removeFirst(ring.count - ringLimit) }
      if logToConsole { NSLog("[NEAdaptive] %@", line) }
      write(line)
    }

    /// 只在 `isVerbose` 打开时记录。
    public func logVerbose(_ category: String, _ message: @autoclosure () -> String) {
      guard isVerbose else { return }
      log(category, message())
    }

    /// 输出一次完整的窗口/场景/安全区/占位区快照。
    ///
    /// 这是判断"模拟器与真机几何差异"的唯一权威入口：连接真机后先抓这一段，
    /// 对照 `docs/duo-real-device-log-playbook.md` 的期望值即可定位。
    public func dumpEnvironment(_ tag: String) {
      guard isEnabled else { return }
      var lines: [String] = []
      let info = Bundle.main.infoDictionary
      let version = info?["CFBundleShortVersionString"] as? String ?? "-"
      let build = info?["CFBundleVersion"] as? String ?? "-"
      lines.append("== ENV " + tag + " ==")
      lines.append("app=" + version + "(" + build + ")")
      lines.append("system=" + UIDevice.current.systemVersion)
      lines.append("model=" + Self.hardwareModel() + " sim=" + (Self.isSimulator ? "true" : "false"))
      lines.append("idiom=" + String(UIDevice.current.userInterfaceIdiom.rawValue))
      lines.append("UIScreen=" + Self.describe(UIScreen.main.bounds) + " scale=" + String(format: "%.2f", UIScreen.main.scale))
      let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
      for (sceneIndex, scene) in scenes.enumerated() {
        let sceneBounds = scene.coordinateSpace.bounds
        var sceneLine = "scene[" + String(sceneIndex) + "]"
        sceneLine += " state=" + String(scene.activationState.rawValue)
        sceneLine += " bounds=" + Self.describe(sceneBounds)
        sceneLine += " orient=" + String(scene.interfaceOrientation.rawValue)
        sceneLine += " trait=" + Self.describe(scene.traitCollection)
        sceneLine += " screen=" + Self.describe(scene.screen.bounds)
        sceneLine += " uiScreenMismatch=" + (Self.mismatch(sceneBounds, UIScreen.main.bounds) ? "true" : "false")
        lines.append(sceneLine)
        if let statusBar = scene.statusBarManager {
          lines.append("scene[" + String(sceneIndex) + "] statusBarFrame=" + Self.describe(statusBar.statusBarFrame))
        }
        for (windowIndex, window) in scene.windows.enumerated() {
          var text = "window[" + String(windowIndex) + "]"
          text += " key=" + (window.isKeyWindow ? "true" : "false")
          text += " level=" + String(format: "%.0f", window.windowLevel.rawValue)
          text += " hidden=" + (window.isHidden ? "true" : "false")
          text += " frame=" + Self.describe(window.frame)
          text += " bounds=" + Self.describe(window.bounds)
          text += " safe=" + Self.describe(window.safeAreaInsets)
          text += " root=" + String(describing: type(of: window.rootViewController))
          text += " sceneMismatch=" + (Self.mismatch(window.bounds, sceneBounds) ? "true" : "false")
          if #available(iOS 27.1, *) {
            let occlusion = Self.describeReserved(window.reservedRegions(kind: .occlusion),
                                                  frame: { $0.frame },
                                                  isActive: { $0.isActive })
            let division = Self.describeReserved(window.reservedRegions(kind: .division),
                                                 frame: { $0.frame },
                                                 isActive: { $0.isActive })
            text += " occlusion=[" + occlusion + "]"
            text += " division=[" + division + "]"
          }
          lines.append(text)
        }
      }
      log("env", lines.joined(separator: "\n    "))
    }

    /// 当前窗口/场景的单行摘要，供每次布局日志携带。
    public static func currentSummary() -> String {
      let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
      guard let scene else { return "no-scene" }
      var summary = "scene=" + describe(scene.coordinateSpace.bounds)
      if let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first {
        summary += " win=" + describe(window.bounds)
        summary += " winSafe=" + describe(window.safeAreaInsets)
        summary += " winSceneMismatch=" + (mismatch(window.bounds, scene.coordinateSpace.bounds) ? "true" : "false")
      } else {
        summary += " win=nil"
      }
      return summary
    }

    /// 导出全部日志文本（文件内容优先，回退内存环形缓冲）。
    public func exportText() -> String {
      if let url = fileURL, let text = try? String(contentsOf: url, encoding: .utf8), !text.isEmpty {
        return text
      }
      return ring.joined(separator: "\n")
    }

    /// 立即落盘（进入后台、导出前调用）。
    public func flush() {
      if !Thread.isMainThread {
        DispatchQueue.main.async { [weak self] in self?.flush() }
        return
      }
      try? handle?.synchronize()
    }

    /// 清空日志（下一轮验证前调用）。
    public func clear() {
      ring.removeAll()
      writtenLines = 0
      if let url = fileURL { try? FileManager.default.removeItem(at: url) }
      handle = nil
      openFile()
      log("diag", "cleared")
    }

    // MARK: - Formatting

    public static func describe(_ rect: CGRect) -> String {
      String(format: "%.1f,%.1f %.1fx%.1f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)
    }

    public static func describe(_ insets: UIEdgeInsets) -> String {
      String(format: "t%.1f l%.1f b%.1f r%.1f", insets.top, insets.left, insets.bottom, insets.right)
    }

    public static func describe(_ traits: UITraitCollection) -> String {
      "h\(traits.horizontalSizeClass.rawValue)/v\(traits.verticalSizeClass.rawValue)/s\(traits.displayScale)"
    }

    /// 占位区列表的紧凑描述：`x,y wxh:on/off, ...`。
    static func describeReserved<T>(_ regions: [T],
                                   frame: (T) -> CGRect,
                                   isActive: (T) -> Bool) -> String {
      regions.map { "\(describe(frame($0)))::\(isActive($0) ? "on" : "off")" }.joined(separator: " ")
    }

    public static func mismatch(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
      abs(lhs.width - rhs.width) > 0.5 || abs(lhs.height - rhs.height) > 0.5
    }

    public static var isSimulator: Bool {
      #if targetEnvironment(simulator)
        return true
      #else
        return false
      #endif
    }

    public static func hardwareModel() -> String {
      var systemInfo = utsname()
      uname(&systemInfo)
      return withUnsafeBytes(of: &systemInfo.machine) { bytes in
        String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
      }
    }

    // MARK: - File

    private static let timeFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "HH:mm:ss.SSS"
      return formatter
    }()

    private static func timeString(_ value: TimeInterval) -> String {
      timeFormatter.string(from: Date(timeIntervalSince1970: value))
    }

    private func openFile() {
      guard handle == nil, let url = fileURL else { return }
      let manager = FileManager.default
      if !manager.fileExists(atPath: url.path) {
        manager.createFile(atPath: url.path, contents: nil)
      }
      handle = try? FileHandle(forWritingTo: url)
      try? handle?.seekToEnd()
      let header = "\n===== session \(Date()) app=\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-") "
        + "system=\(UIDevice.current.systemVersion) model=\(Self.hardwareModel()) sim=\(Self.isSimulator) =====\n"
      if let data = header.data(using: .utf8) {
        try? handle?.write(contentsOf: data)
      }
    }

    private func write(_ line: String) {
      guard fileURL != nil else { return }
      if handle == nil { openFile() }
      guard let handle, let data = (line + "\n").data(using: .utf8) else { return }
      do {
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
        writtenLines += 1
        if writtenLines % 40 == 0 { try? handle.synchronize() }
        if writtenLines % 200 == 0 { rotateIfNeeded() }
      } catch {
        self.handle = nil
      }
    }

    private func rotateIfNeeded() {
      guard let url = fileURL else { return }
      let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
      let size = (attributes?[.size] as? NSNumber)?.intValue ?? 0
      guard size > maximumFileSize else { return }
      try? handle?.close()
      handle = nil
      let backup = url.deletingPathExtension().appendingPathExtension("1.log")
      try? FileManager.default.removeItem(at: backup)
      try? FileManager.default.moveItem(at: url, to: backup)
      openFile()
    }
  }
#endif
