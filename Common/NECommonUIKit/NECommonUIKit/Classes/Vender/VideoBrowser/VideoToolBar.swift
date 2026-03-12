
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import UIKit

protocol VideoToolBarDelegate: AnyObject {
  func didClickPause()
  func didClickPlay()
  func didSeek(_ progress: Float)
  func didStopRefreshProgress()
  func didStartRefreshProgress()
}

public class VideoToolBar: UIView {
  var total: Int = 0

  weak var delegate: VideoToolBarDelegate?

  public lazy var playButton: ExpandButton = {
    let button = ExpandButton()
    button.setImage(coreLoader.loadImage("video_stop_icon"), for: .normal)
    button.setImage(coreLoader.loadImage("video_play_icon"), for: .selected)
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  public lazy var currentTimeLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = .white
    label.font = NEConstant.defaultTextFont(12.0)
    label.text = "00:00"
    return label
  }()

  public lazy var totalTimeLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = .white
    label.font = NEConstant.defaultTextFont(12.0)
    return label
  }()

  public lazy var progressSlider: UISlider = {
    let slider = UISlider()
    slider.tintColor = .white
    slider.thumbTintColor = .white
    slider.maximumValue = 1
    slider.minimumValue = 0
    slider.value = 0
    slider.minimumTrackTintColor = .white
    slider.isContinuous = true
    slider.maximumTrackTintColor = NEConstant.hexRGB(0x000000).withAlphaComponent(0.3)
    slider.translatesAutoresizingMaskIntoConstraints = false
    return slider
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    addSubview(playButton)
    NSLayoutConstraint.activate([
      playButton.leftAnchor.constraint(equalTo: leftAnchor),
      playButton.centerYAnchor.constraint(equalTo: centerYAnchor),
      playButton.widthAnchor.constraint(equalToConstant: 60.0),
    ])
    playButton.addTarget(self, action: #selector(playClick(_:)), for: .touchUpInside)

    addSubview(currentTimeLabel)
    NSLayoutConstraint.activate([
      currentTimeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
      currentTimeLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 48.0),
    ])

    addSubview(progressSlider)
    NSLayoutConstraint.activate([
      progressSlider.centerYAnchor.constraint(equalTo: centerYAnchor),
      progressSlider.leftAnchor.constraint(equalTo: leftAnchor, constant: 90),
      progressSlider.rightAnchor.constraint(equalTo: rightAnchor, constant: -55),
    ])
    progressSlider.addTarget(self, action: #selector(sliderChange), for: .valueChanged)
    progressSlider.addTarget(self, action: #selector(sliderTouchUp), for: .touchUpInside)
    progressSlider.addTarget(self, action: #selector(sliderTouchUp), for: .touchUpOutside)
    progressSlider.addTarget(self, action: #selector(sliderTouchDown), for: .touchDown)

    addSubview(totalTimeLabel)
    NSLayoutConstraint.activate([
      totalTimeLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -15.0),
      totalTimeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  @objc func sliderChange() {
    delegate?.didSeek(progressSlider.value)
    if playButton.isSelected == true {
      let current = Float(total) * progressSlider.value
      currentTimeLabel.text = Date.getFormatPlayTime(Double(current) / 1000.0)
    }
  }

  @objc func sliderTouchUp() {
    delegate?.didStartRefreshProgress()
    delegate?.didSeek(progressSlider.value)
  }

  @objc func sliderTouchDown() {
    delegate?.didStopRefreshProgress()
  }

  @objc func playClick(_ btn: ExpandButton) {
    btn.isSelected = !btn.isSelected
    if btn.isSelected == true {
      delegate?.didClickPause()
    } else {
      delegate?.didClickPlay()
    }
  }

  public func resetState() {
    playButton.isSelected = true
    progressSlider.value = 0
    currentTimeLabel.text = "00:00"
  }
}
