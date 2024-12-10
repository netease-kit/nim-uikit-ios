// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

@objcMembers
open class ChatMessageLocationCell: NormalChatMessageBaseCell {
  public lazy var titleLabelLeft: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_darkText
    label.font = UIFont.systemFont(ofSize: 16.0)
    label.accessibilityIdentifier = "id.locationItemTitle"
    return label
  }()

  public lazy var subTitleLabelLeft: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_lightText
    label.font = UIFont.systemFont(ofSize: 12.0)
    label.accessibilityIdentifier = "id.locationItemAddress"
    return label
  }()

  public lazy var emptyLabelLeft: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 16)
    label.text = chatLocalizable("no_map_plugin")
    label.textAlignment = .center
    label.textColor = UIColor.ne_greyText
    label.isHidden = true
    return label
  }()

  public lazy var backgroundViewLeft: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.white
    view.translatesAutoresizingMaskIntoConstraints = false
    view.clipsToBounds = true
    view.layer.cornerRadius = 4
    view.layer.borderWidth = 1
    view.layer.borderColor = UIColor.ne_outlineColor.cgColor
    view.accessibilityIdentifier = "id.mapView"

    let messageLongPress = UILongPressGestureRecognizer(
      target: self,
      action: #selector(longPress)
    )
    view.addGestureRecognizer(messageLongPress)

    let messageTap = UITapGestureRecognizer(target: self, action: #selector(tapMessage))
    messageTap.cancelsTouchesInView = false
    view.addGestureRecognizer(messageTap)

    view.addSubview(titleLabelLeft)
    NSLayoutConstraint.activate([
      titleLabelLeft.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
      titleLabelLeft.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
      titleLabelLeft.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
    ])

    view.addSubview(subTitleLabelLeft)
    NSLayoutConstraint.activate([
      subTitleLabelLeft.leftAnchor.constraint(equalTo: titleLabelLeft.leftAnchor),
      subTitleLabelLeft.rightAnchor.constraint(equalTo: titleLabelLeft.rightAnchor),
      subTitleLabelLeft.topAnchor.constraint(equalTo: titleLabelLeft.bottomAnchor, constant: 4),
    ])

    view.addSubview(mapImageViewLeft)
    NSLayoutConstraint.activate([
      mapImageViewLeft.leftAnchor.constraint(equalTo: view.leftAnchor),
      mapImageViewLeft.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      mapImageViewLeft.rightAnchor.constraint(equalTo: view.rightAnchor),
      mapImageViewLeft.heightAnchor.constraint(equalToConstant: 86),
    ])
    view.addSubview(emptyLabelLeft)
    NSLayoutConstraint.activate([
      emptyLabelLeft.leftAnchor.constraint(equalTo: view.leftAnchor),
      emptyLabelLeft.rightAnchor.constraint(equalTo: view.rightAnchor),
      emptyLabelLeft.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
    ])
    return view
  }()

  public lazy var mapImageViewLeft: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    imageView.addSubview(pointImageLeft)
    NSLayoutConstraint.activate([
      pointImageLeft.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
      pointImageLeft.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -30),
    ])
    return imageView
  }()

  // Right
  public lazy var titleLabelRight: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_darkText
    label.font = UIFont.systemFont(ofSize: 16.0)
    label.accessibilityIdentifier = "id.locationItemTitle"
    return label
  }()

  public lazy var subTitleLabelRight: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_lightText
    label.font = UIFont.systemFont(ofSize: 12.0)
    label.accessibilityIdentifier = "id.locationItemAddress"
    return label
  }()

  public lazy var emptyLabelRight: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 16)
    label.text = chatLocalizable("no_map_plugin")
    label.textAlignment = .center
    label.textColor = UIColor.ne_greyText
    label.isHidden = true
    return label
  }()

  public lazy var pointImageLeft: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = coreLoader.loadImage("location_point")
    return imageView
  }()

  public lazy var pointImageRight: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = coreLoader.loadImage("location_point")
    return imageView
  }()

  public lazy var backgroundViewRight: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.white
    view.translatesAutoresizingMaskIntoConstraints = false
    view.clipsToBounds = true
    view.layer.cornerRadius = 4
    view.layer.borderWidth = 1
    view.layer.borderColor = UIColor.ne_outlineColor.cgColor
    view.accessibilityIdentifier = "id.mapView"

    let messageLongPress = UILongPressGestureRecognizer(
      target: self,
      action: #selector(longPress)
    )
    view.addGestureRecognizer(messageLongPress)

    let messageTap = UITapGestureRecognizer(target: self, action: #selector(tapMessage))
    messageTap.cancelsTouchesInView = false
    view.addGestureRecognizer(messageTap)

    view.addSubview(titleLabelRight)
    NSLayoutConstraint.activate([
      titleLabelRight.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
      titleLabelRight.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
      titleLabelRight.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
    ])

    view.addSubview(subTitleLabelRight)
    NSLayoutConstraint.activate([
      subTitleLabelRight.leftAnchor.constraint(equalTo: titleLabelRight.leftAnchor),
      subTitleLabelRight.rightAnchor.constraint(equalTo: titleLabelRight.rightAnchor),
      subTitleLabelRight.topAnchor.constraint(equalTo: titleLabelRight.bottomAnchor, constant: 4),
    ])

    view.addSubview(mapImageViewRight)
    NSLayoutConstraint.activate([
      mapImageViewRight.leftAnchor.constraint(equalTo: view.leftAnchor),
      mapImageViewRight.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      mapImageViewRight.rightAnchor.constraint(equalTo: view.rightAnchor),
      mapImageViewRight.heightAnchor.constraint(equalToConstant: 86),
    ])
    view.addSubview(emptyLabelRight)
    NSLayoutConstraint.activate([
      emptyLabelRight.leftAnchor.constraint(equalTo: view.leftAnchor),
      emptyLabelRight.rightAnchor.constraint(equalTo: view.rightAnchor),
      emptyLabelRight.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
    ])
    return view
  }()

  public lazy var mapImageViewRight: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    imageView.addSubview(pointImageRight)
    NSLayoutConstraint.activate([
      pointImageRight.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
      pointImageRight.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -30),
    ])
    return imageView
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func commonUILeft() {
    super.commonUILeft()
    bubbleImageLeft.addSubview(backgroundViewLeft)
    NSLayoutConstraint.activate([
      backgroundViewLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor),
      backgroundViewLeft.topAnchor.constraint(equalTo: replyViewLeft.bottomAnchor),
      backgroundViewLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor),
      backgroundViewLeft.bottomAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor),
    ])
  }

  override open func commonUIRight() {
    super.commonUIRight()
    bubbleImageRight.addSubview(backgroundViewRight)
    NSLayoutConstraint.activate([
      backgroundViewRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor),
      backgroundViewRight.topAnchor.constraint(equalTo: replyViewRight.bottomAnchor),
      backgroundViewRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor),
      backgroundViewRight.bottomAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor),
    ])
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)
    backgroundViewLeft.isHidden = showRight
    backgroundViewRight.isHidden = !showRight
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    super.setModel(model, isSend)
    let titleLabel = isSend ? titleLabelRight : titleLabelLeft
    let subTitleLabel = isSend ? subTitleLabelRight : subTitleLabelLeft
    let mapImageView = isSend ? mapImageViewRight : mapImageViewLeft
    let emptyLabel = isSend ? emptyLabelRight : emptyLabelLeft
    let pointImage = isSend ? pointImageRight : pointImageLeft
    let bubble = isSend ? bubbleImageRight : bubbleImageLeft

    if model.isReplay {
      setBubbleImage()
    } else {
      bubble.image = nil
    }

    if let m = model as? MessageLocationModel {
      titleLabel.text = m.title
      subTitleLabel.text = m.subTitle
      if let lat = m.lat, let lng = m.lng {
        if let url = NEChatKitClient.instance.delegate?.getMapImageUrl?(lat: lat, lng: lng) {
          NEALog.infoLog(className(), desc: #function + "location image url = \(url)")
          mapImageView.sd_setImage(
            with: URL(string: url),
            placeholderImage: coreLoader.loadImage("map_placeholder_image"),
            options: .retryFailed
          )
          emptyLabel.isHidden = true
          pointImage.isHidden = false
        } else {
          mapImageView.image = UIImage.ne_imageNamed(name: "map_placeholder_image")
          emptyLabel.isHidden = false
          pointImage.isHidden = true
        }
      }
    }
  }
}
