
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objc
public protocol ChatRecordViewDelegate: NSObjectProtocol {
  func startRecord()
  func moveOutView()
  func moveInView()
  func endRecord(insideView: Bool)
}

@objcMembers
open class ChatRecordView: UIView, UIGestureRecognizerDelegate {
  var recordImageView = UIImageView()
  var topTipLabel = UILabel()
  var tipLabel = UILabel()
  public weak var delegate: ChatRecordViewDelegate?
  private var outView = false
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func commonUI() {
    topTipLabel.translatesAutoresizingMaskIntoConstraints = false
    topTipLabel.text = chatLocalizable("send_after_let_go")
    topTipLabel.font = UIFont.systemFont(ofSize: 12)
    topTipLabel.textColor = .ne_lightText
    topTipLabel.textAlignment = .center
    topTipLabel.isHidden = true // 不展示
    addSubview(topTipLabel)
    NSLayoutConstraint.activate([
      topTipLabel.topAnchor.constraint(equalTo: topAnchor, constant: 0),
      topTipLabel.heightAnchor.constraint(equalToConstant: 23),
      topTipLabel.leftAnchor.constraint(equalTo: leftAnchor),
      topTipLabel.rightAnchor.constraint(equalTo: rightAnchor),
    ])

    recordImageView.translatesAutoresizingMaskIntoConstraints = false
    recordImageView.image = UIImage.ne_imageNamed(name: "chat_record")
    recordImageView.contentMode = .center
    addSubview(recordImageView)
    NSLayoutConstraint.activate([
      recordImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
      recordImageView.topAnchor.constraint(equalTo: topAnchor, constant: 40),
      recordImageView.heightAnchor.constraint(equalToConstant: 103),
      recordImageView.widthAnchor.constraint(equalToConstant: 103),
    ])

    if let image1 = UIImage.ne_imageNamed(name: "record_3"),
       let image2 = UIImage.ne_imageNamed(name: "record_2"),
       let image3 = UIImage.ne_imageNamed(name: "record_1") {
      recordImageView.animationImages = [image1, image2, image3]
    }
    recordImageView.animationDuration = 0.8
    let guesture = UILongPressGestureRecognizer(target: self, action: #selector(clickLabel))
    recordImageView.isUserInteractionEnabled = true
    recordImageView.addGestureRecognizer(guesture)

    tipLabel.translatesAutoresizingMaskIntoConstraints = false
    tipLabel.text = chatLocalizable("press_speak")
    tipLabel.font = UIFont.systemFont(ofSize: 12)
    tipLabel.textColor = .ne_lightText
    tipLabel.textAlignment = .center
    addSubview(tipLabel)
    NSLayoutConstraint.activate([
      tipLabel.topAnchor.constraint(equalTo: recordImageView.bottomAnchor, constant: 12),
      tipLabel.heightAnchor.constraint(equalToConstant: 23),
      tipLabel.leftAnchor.constraint(equalTo: leftAnchor),
      tipLabel.rightAnchor.constraint(equalTo: rightAnchor),
    ])
  }

  func clickLabel(recognizer: UILongPressGestureRecognizer) {
//    print("location:\(recognizer.location(in: recognizer.view))")
    switch recognizer.state {
    case .began:
      print("state:begin")
      startRecord()
    case .changed:
      print("state:changed")
    case .ended:
      endRecord(recognizer: recognizer)
    case .cancelled:
      endRecord(recognizer: recognizer)
      print("state:cancelled")
    case .failed:
      endRecord(recognizer: recognizer)
      print("state:failed")
    default:
      print("state:default")
    }
  }

  open func stopRecordAnimation() {
    topTipLabel.isHidden = true
    recordImageView.stopAnimating()
  }

  private func startRecord() {
    topTipLabel.isHidden = false
    recordImageView.startAnimating()
    delegate?.startRecord()
  }

  private func moveOutView() {
    delegate?.moveOutView()
  }

  private func moveInView() {
    delegate?.moveInView()
  }

  private func endRecord(recognizer: UILongPressGestureRecognizer) {
    stopRecordAnimation()
    let inView = isInRecordView(recognizer: recognizer)
    delegate?.endRecord(insideView: inView)
  }

  private func isInRecordView(recognizer: UILongPressGestureRecognizer) -> Bool {
    let point = recognizer.location(in: recognizer.view)
    if point.x < 0 || point.x > recognizer.view?.bounds.size.width ?? 0 || point.y < 0 || point
      .y > recognizer.view?.bounds.size.height ?? 0 {
      return false
    }
    return true
  }
}
