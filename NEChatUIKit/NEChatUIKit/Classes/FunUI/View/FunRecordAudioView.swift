// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Lottie
import UIKit

@objc
public protocol FunChatRecordViewDelegate: NSObjectProtocol {
  func didEndRecord(view: FunRecordAudioView)
}

@objcMembers
open class FunRecordAudioView: UIView {
  public weak var delegate: FunChatRecordViewDelegate?

  public var maxDuration: Int = 60

  private var timeCount = 0

  public var lastTimeDuration = 10

  public var timer: Timer?

  public var maxRecordProgressMargin: CGFloat = 30.0

  public var minRecordProgressWidth: CGFloat = 165.0

  lazy var lottieView: LOTAnimationView = {
    let lottie = LOTAnimationView()
    lottie.translatesAutoresizingMaskIntoConstraints = false
    lottie.setAnimation(named: "fun_vioce_data", bundle: coreLoader.bundle)
    lottie.loopAnimation = true
    lottie.contentMode = .scaleToFill
    lottie.translatesAutoresizingMaskIntoConstraints = false
    return lottie
  }()

  lazy var lottieContentView: UIView = {
    let content = UIView()
    content.translatesAutoresizingMaskIntoConstraints = false
    content.backgroundColor = UIColor.clear
    return content
  }()

  public var triangleView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.funRecordAudioProgressNormalColor
    view.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 4)
    return view
  }()

  public var recordProgressView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.clipsToBounds = true
    view.layer.cornerRadius = 16.0
    view.backgroundColor = UIColor.funRecordAudioProgressNormalColor
    return view
  }()

  public let recordGestureArea: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = coreLoader.loadImage("fun_chat_record_gesture_inner")
    imageView.highlightedImage = coreLoader.loadImage("fun_chat_record_gesture_outter")
    imageView.isHighlighted = false
    return imageView
  }()

  public let recordCloseImage: UIImageView = {
    let close = UIImageView()
    close.contentMode = .center
    close.translatesAutoresizingMaskIntoConstraints = false
    close.image = coreLoader.loadImage("fun_chat_record_close_dark")
    close.highlightedImage = coreLoader.loadImage("fun_chat_record_close_light")
    close.isHighlighted = false
    return close
  }()

  public let releaseToSendLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 16.0)
    label.textColor = UIColor.funRecordAudioTextColor
    label.text = chatLocalizable("release_to_send")
    label.textAlignment = .center
    return label
  }()

  public let releaseToCancelLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 16.0)
    label.textColor = UIColor.funRecordAudioTextColor
    label.text = chatLocalizable("release_to_cancel")
    label.isHidden = true
    label.textAlignment = .center
    return label
  }()

  public let lastTimeLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 18.0)
    label.textColor = UIColor.funRecordAudioLastTimeColor
    label.textAlignment = .center
    label.isHidden = true
    return label
  }()

  private var progressWidthIncreaseFactor: CGFloat = 0

  private var progressWidthConstraint: NSLayoutConstraint?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func setupUI() {
    let totalWidth = UIScreen.main.bounds.width - maxRecordProgressMargin * 2 - minRecordProgressWidth
    let delta = CGFloat(maxDuration - lastTimeDuration)
    progressWidthIncreaseFactor = totalWidth / delta

    backgroundColor = UIColor.funRecordAudioViewBg.withAlphaComponent(0.7)
    addSubview(recordGestureArea)
    NSLayoutConstraint.activate([
      recordGestureArea.leftAnchor.constraint(equalTo: leftAnchor),
      recordGestureArea.rightAnchor.constraint(equalTo: rightAnchor),
      recordGestureArea.bottomAnchor.constraint(equalTo: bottomAnchor),
      recordGestureArea.heightAnchor.constraint(equalToConstant: FunRecordAudioView.getGestureHeight()),
    ])

    addSubview(recordCloseImage)
    NSLayoutConstraint.activate([
      recordCloseImage.centerXAnchor.constraint(equalTo: centerXAnchor),
      recordCloseImage.centerYAnchor.constraint(equalTo: recordGestureArea.centerYAnchor, constant: -152),
      recordCloseImage.widthAnchor.constraint(equalToConstant: 88.0),
      recordCloseImage.heightAnchor.constraint(equalToConstant: 88.0),
    ])

    addSubview(releaseToSendLabel)
    NSLayoutConstraint.activate([
      releaseToSendLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
      releaseToSendLabel.bottomAnchor.constraint(equalTo: recordGestureArea.topAnchor, constant: -16),
    ])

    addSubview(releaseToCancelLabel)
    NSLayoutConstraint.activate([
      releaseToCancelLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
      releaseToCancelLabel.bottomAnchor.constraint(equalTo: recordCloseImage.topAnchor, constant: -16),
    ])

    addSubview(recordProgressView)
    progressWidthConstraint = recordProgressView.widthAnchor.constraint(equalToConstant: minRecordProgressWidth)
    NSLayoutConstraint.activate([
      recordProgressView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -354),
      recordProgressView.heightAnchor.constraint(equalToConstant: 80),
      progressWidthConstraint!,
      recordProgressView.centerXAnchor.constraint(equalTo: centerXAnchor),
    ])

    recordProgressView.addSubview(lastTimeLabel)
    NSLayoutConstraint.activate([
      lastTimeLabel.centerXAnchor.constraint(equalTo: recordProgressView.centerXAnchor),
      lastTimeLabel.centerYAnchor.constraint(equalTo: recordProgressView.centerYAnchor),
    ])

    addSubview(lottieView)
    NSLayoutConstraint.activate([
      lottieView.centerXAnchor.constraint(equalTo: recordProgressView.centerXAnchor),
      lottieView.centerYAnchor.constraint(equalTo: recordProgressView.centerYAnchor),
      lottieView.widthAnchor.constraint(equalToConstant: 80),
      lottieView.heightAnchor.constraint(equalToConstant: 40),
    ])
    lottieView.play()

    addSubview(triangleView)
    insertSubview(triangleView, belowSubview: recordProgressView)
    NSLayoutConstraint.activate([
      triangleView.widthAnchor.constraint(equalToConstant: 21),
      triangleView.heightAnchor.constraint(equalToConstant: 21),
      triangleView.centerXAnchor.constraint(equalTo: centerXAnchor),
      triangleView.topAnchor.constraint(equalTo: recordProgressView.topAnchor, constant: 60),
    ])

    weak var weakSelf = self
    let finalWidth = UIScreen.main.bounds.width - maxRecordProgressMargin * 2
    let animDuration = TimeInterval(maxDuration - lastTimeDuration)
//    DispatchQueue.main.async {
//      weakSelf?.progressWidthConstraint?.constant = finalWidth
//      UIView.animate(withDuration: animDuration) {
//        weakSelf?.layoutSubviews()
//      }
//    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: DispatchWorkItem(block: {
      weakSelf?.progressWidthConstraint?.constant = finalWidth
      UIView.animate(withDuration: animDuration) {
        weakSelf?.layoutIfNeeded()
      }
    }))

//        UIView.animate(withDuration: TimeInterval(maxDuration - lastTimeDuration), delay: 0, options: [.curveLinear]) {
//            weakSelf?.progressWidthConstraint?.constant = finalWidth
//        }

    timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timeCountIncrease), userInfo: nil, repeats: true)
  }

  static func getGestureHeight() -> CGFloat {
    let windowWidth = UIScreen.main.bounds.width
    return windowWidth / 375.0 * 128.0
  }

  open func changeToCancelStyle() {
    if releaseToSendLabel.isHidden == true {
      return
    }
    recordCloseImage.isHighlighted = true
    recordGestureArea.isHighlighted = true
    releaseToSendLabel.isHidden = true
    releaseToCancelLabel.isHidden = false
    recordProgressView.backgroundColor = UIColor.funRecordAudioProgressCancelColor
    triangleView.backgroundColor = UIColor.funRecordAudioProgressCancelColor
  }

  open func changeToNormalStyle() {
    if releaseToSendLabel.isHidden == false {
      return
    }
    recordCloseImage.isHighlighted = false
    recordGestureArea.isHighlighted = false
    releaseToSendLabel.isHidden = false
    releaseToCancelLabel.isHidden = true
    recordProgressView.backgroundColor = UIColor.funRecordAudioProgressNormalColor
    triangleView.backgroundColor = UIColor.funRecordAudioProgressNormalColor
  }

  open func isRecordNormalStyle() -> Bool {
    if releaseToSendLabel.isHidden == false {
      return true
    }
    return false
  }

  func timeCountIncrease() {
    print("timeCountIncrease : \(timeCount)")
    let lastTime = maxDuration - timeCount
    if lastTime == 0 {
      timer?.invalidate()
      timer = nil
      delegate?.didEndRecord(view: self)
      return
    }

    if lastTimeDuration >= lastTime {
      lastTimeLabel.isHidden = false
      if lottieView.isAnimationPlaying {
        lottieView.stop()
        lottieView.isHidden = true
      }
      lastTimeLabel.text = String(format: chatLocalizable("stop_record"), lastTime)
    }
    timeCount += 1
  }

//    deinit {
//        if let valid = timer?.isValid, valid {
//            timer?.invalidate()
//            timer = nil
//        }
//    }

  override open func willMove(toWindow newWindow: UIWindow?) {}

  override open func willMove(toSuperview newSuperview: UIView?) {
    if newSuperview != nil {
      return
    }
    if let valid = timer?.isValid, valid {
      timer?.invalidate()
      timer = nil
    }
  }
}
