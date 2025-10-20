//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import AVFoundation

@objcMembers
open class NEAudioSessionManager: NSObject {
  static let shared = NEAudioSessionManager()

  private var isSpeakerActive = false {
    didSet {
      isSpeakerActive ? startProximityMonitoring() : stopProximityMonitoring()
    }
  }

  override private init() {
    super.init()
    configureAudioSession()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  /// 设置扬声器播放
  func switchToSpeaker() {
    setAudioRoute(to: .speaker)
    isSpeakerActive = true
  }

  /// 设置听筒播放
  func switchToReceiver() {
    setAudioRoute(to: .none)
    isSpeakerActive = false
  }

  private func configureAudioSession() {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.playAndRecord, mode: .voiceChat)
      try session.setActive(true)
    } catch {
      print("[Audio] Session config error: \(error)")
    }
  }

  private func setAudioRoute(to port: AVAudioSession.PortOverride) {
    configureAudioSession()
    let session = AVAudioSession.sharedInstance()
    do {
      try session.overrideOutputAudioPort(port)
      try session.setPreferredOutputNumberOfChannels(1)
    } catch {
      print("[Audio] Route切换失败: \(error)")
    }
  }

  // MARK: - 贴耳检测

  private func startProximityMonitoring() {
    guard UIDevice.current.isProximityMonitoringEnabled == false else { return }

    UIDevice.current.isProximityMonitoringEnabled = true
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleProximityChange),
      name: UIDevice.proximityStateDidChangeNotification,
      object: nil
    )
  }

  /// 关闭贴耳检测
  public func stopProximityMonitoring() {
    guard UIDevice.current.isProximityMonitoringEnabled else { return }

    UIDevice.current.isProximityMonitoringEnabled = false
    NotificationCenter.default.removeObserver(
      self,
      name: UIDevice.proximityStateDidChangeNotification,
      object: nil
    )
  }

  @objc private func handleProximityChange() {
    guard isSpeakerActive else { return }

    if UIDevice.current.proximityState {
      // 贴耳时切回听筒
      setAudioRoute(to: .none)
    } else {
      // 恢复扬声器
      setAudioRoute(to: .speaker)
    }
  }
}
