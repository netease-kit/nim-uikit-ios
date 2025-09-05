
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import AVFoundation
import NECommonKit
import UIKit

@objc
@objcMembers
open class VideoPlayerViewController: UIViewController {
  public var videoUrl: URL?
  public var totalTime: Int?
  let kCallKitDismissNoti = "kCallKitDismissNoti"
  let kCallKitShowNoti = "kCallKitShowNoti"

  public lazy var playButton: ExpandButton = {
    let button = ExpandButton()
    button.isHidden = true
    button.setImage(coreLoader.loadImage("video_play"), for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  var isRefreshProgress: Bool = true

  var isPlayingEnd: Bool = false

  public lazy var toolsBar: BrowserToolsBar = {
    let bar = BrowserToolsBar()
    bar.delegate = self
    bar.translatesAutoresizingMaskIntoConstraints = false
    return bar
  }()

  public lazy var successView: ToastImageView = {
    let success = ToastImageView()
    success.frame = CGRect(x: 0, y: 0, width: 118, height: 120)
    success.contentLabel.text = commonLocalizable("save_system_album")
    return success
  }()

  public lazy var videoToolBar: VideoToolBar = {
    let bar = VideoToolBar()
    bar.translatesAutoresizingMaskIntoConstraints = false
    bar.backgroundColor = .clear
    bar.delegate = self
    return bar
  }()

  private var dismissGesture: UITapGestureRecognizer = {
    let tap = UITapGestureRecognizer()
    tap.numberOfTapsRequired = 1
    tap.numberOfTouchesRequired = 1
    return tap
  }()

  var avPlayer: AVPlayer?

  override public func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    setupUI()
    setupNotifications()
  }

  func setupUI() {
    if let url = videoUrl {
      let palyerItem = AVPlayerItem(url: url)
      avPlayer = AVPlayer(playerItem: palyerItem)
      let playerLayer = AVPlayerLayer(player: avPlayer)
      playerLayer.videoGravity = .resizeAspect
      playerLayer.frame = view.bounds
      view.layer.addSublayer(playerLayer)
      // 播放
      avPlayer?.play()

      weak var weakSelf = self
      let interval = CMTime(seconds: 0.2, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
      avPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { time in
        // Update slider value to audio item progress.
        if weakSelf?.isRefreshProgress == false {
          return
        }
        if let duration = weakSelf?.avPlayer?.currentItem?.duration.seconds,
           let seekTime = weakSelf?.avPlayer?.currentTime().seconds {
          let proress = seekTime / duration
          DispatchQueue.main.async {
            weakSelf?.videoToolBar.progressSlider.value = Float(proress)
            weakSelf?.videoToolBar.currentTimeLabel.text = Date.getFormatPlayTime(seekTime)
            if proress >= 1.0 {
              weakSelf?.endPlay()
            }
          }
        }
      })
    }

    view.backgroundColor = .black
    view.addSubview(toolsBar)
    NSLayoutConstraint.activate([
      toolsBar.leftAnchor.constraint(equalTo: view.leftAnchor),
      toolsBar.rightAnchor.constraint(equalTo: view.rightAnchor),
      toolsBar.heightAnchor.constraint(equalToConstant: 44.0),
      toolsBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -27),
    ])

    view.addSubview(videoToolBar)
    NSLayoutConstraint.activate([
      videoToolBar.leftAnchor.constraint(equalTo: view.leftAnchor),
      videoToolBar.rightAnchor.constraint(equalTo: view.rightAnchor),
      videoToolBar.heightAnchor.constraint(equalToConstant: 44.0),
      videoToolBar.bottomAnchor.constraint(equalTo: toolsBar.topAnchor),
    ])

    if let total = totalTime {
      let time = Date.getFormatPlayTime(TimeInterval(total / 1000))
      videoToolBar.totalTimeLabel.text = time
      videoToolBar.total = total
    }

    view.addSubview(playButton)
    NSLayoutConstraint.activate([
      playButton.leftAnchor.constraint(equalTo: view.leftAnchor),
      playButton.topAnchor.constraint(equalTo: view.topAnchor),
      playButton.rightAnchor.constraint(equalTo: view.rightAnchor),
      playButton.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    playButton.addTarget(self, action: #selector(toPlay), for: .touchUpInside)

    view.addGestureRecognizer(dismissGesture)
    dismissGesture.addTarget(self, action: #selector(dismissVideoToolBar))

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(playerDidFinishPlaying),
      name: .AVPlayerItemDidPlayToEndTime,
      object: nil
    )

    NotificationCenter.default.addObserver(self, selector: #selector(interruptionStart), name: Notification.Name(kCallKitShowNoti), object: nil)

//      NotificationCenter.default.addObserver(self, selector: #selector(interruptionEnd), name: Notification.Name(kCallKitDismissNoti), object: nil)
  }

  func interruptionStart() {
    if isPlayingEnd == false {
      videoToolBar.playButton.isSelected = true
      didClickPause()
    }
  }

  func interruptionEnd() {
    if isPlayingEnd == false {
      videoToolBar.playButton.isSelected = false
      didClickPlay()
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func toPlay() {
    if isPlayingEnd == true {
      avPlayer?.seek(to: CMTime.zero)
      isPlayingEnd = false
    }
    playButton.isHidden = true
    avPlayer?.play()
    videoToolBar.playButton.isSelected = false
  }

  func dismissVideoToolBar() {
    videoToolBar.isHidden = !videoToolBar.isHidden
  }

  func setupNotifications() {
    // Get the default notification center instance.
    let nc = NotificationCenter.default
    nc.addObserver(self,
                   selector: #selector(handleInterruption(notification:)),
                   name: AVAudioSession.interruptionNotification,
                   object: nil)
  }

  func handleInterruption(notification: Notification) {
    print("handleInterruption : ", notification)
    guard let userInfo = notification.userInfo,
          let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
      return
    }

    // Switch over the interruption type.
    switch type {
    case .began:
      interruptionStart()
                // An interruption began. Update the UI as necessary.

    case .ended:
      // An interruption ended. Resume playback, if appropriate.

      guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
      let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
      if options.contains(.shouldResume) {
        // An interruption ended. Resume playback.
        interruptionEnd()
      } else {
        // An interruption ended. Don't resume playback.
      }

    default: ()
    }
  }
}

extension VideoPlayerViewController: BrowserToolsBarDelegate, UINavigationControllerDelegate,
  VideoToolBarDelegate, UIImagePickerControllerDelegate {
  func didClickPause() {
    avPlayer?.pause()
    playButton.isHidden = false
  }

  func didClickPlay() {
    if isPlayingEnd == true {
      avPlayer?.seek(to: CMTime.zero)
      isPlayingEnd = false
    }
    avPlayer?.play()
    isRefreshProgress = true
    playButton.isHidden = true
  }

  func didSeek(_ progress: Float) {
    if let duration = totalTime {
      let seekTime = Float(duration) * progress / 1000.0
      print("seek value : ", seekTime)
      avPlayer?.seek(to: CMTime(seconds: Double(seekTime), preferredTimescale: 1))
    }
  }

  func didStopRefreshProgress() {
    isRefreshProgress = false
  }

  func didStartRefreshProgress() {
    isRefreshProgress = true
  }

  public func didCloseClick() {
    dismiss(animated: true, completion: nil)
  }

  public func didPhotoClick() {
    goPhotoAlbum(self, false, true)
  }

  public func didSaveClick() {
    weak var weakSelf = self
    NEAuthManager.requestPhotoAuthorization { granted in
      if granted == false {
        weakSelf?.showToast(commonLocalizable("jump_photo_setting"))
        return
      }
      DispatchQueue.main.async {
        weakSelf?.view.makeToastActivity(.center)
        weakSelf?.didToSave()
      }
    }
  }

  func didToSave() {
    if videoUrl?.isFileURL == true, let path = videoUrl?.path {
      print("save  path : ", path)
      UISaveVideoAtPathToSavedPhotosAlbum(
        path,
        self,
        #selector(save(path:didFinishSavingWithError:contextInfo:)),
        nil
      )
    } else {
      view.hideToastActivity()
      showToast(commonLocalizable("video_not_save"))
    }
  }

  public func endPlay() {
    videoToolBar.resetState()
    playButton.isHidden = false
  }

  @objc func save(path: String, didFinishSavingWithError: NSError?, contextInfo: AnyObject) {
    view.hideToastActivity()
    if let error = didFinishSavingWithError {
      showToast(error.localizedDescription)
    } else {
      view.showToast(successView, point: view.center)
    }
  }

  @objc func playerDidFinishPlaying(note: NSNotification) {
    isPlayingEnd = true
  }
}
