// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

@objcMembers
open class FunChatMessageLocationCell: FunChatMessageBaseCell {
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
    return label
  }()

  public var mapImageViewLeft: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    return imageView
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
    return view
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
    return label
  }()

  public var mapImageViewRight: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
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
    return view
  }()

  public lazy var pointImageRight: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = coreLoader.loadImage("location_point")
    return imageView
  }()

  public lazy var pointImageLeft: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = coreLoader.loadImage("location_point")
    return imageView
  }()

  override open func commonUILeft() {
    super.commonUILeft()
    bubbleImageLeft.isHidden = true
    contentView.addSubview(backgroundViewLeft)

    let messageLongPress = UILongPressGestureRecognizer(
      target: self,
      action: #selector(longPress)
    )

    backgroundViewLeft.addGestureRecognizer(messageLongPress)
    NSLayoutConstraint.activate([
      backgroundViewLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor),
      backgroundViewLeft.topAnchor.constraint(equalTo: bubbleImageLeft.topAnchor),
      backgroundViewLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor),
      backgroundViewLeft.bottomAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor),
    ])

    let messageTap = UITapGestureRecognizer(target: self, action: #selector(tapMessage))
    messageTap.cancelsTouchesInView = false
    backgroundViewLeft.addGestureRecognizer(messageTap)

    backgroundViewLeft.addSubview(titleLabelLeft)
    NSLayoutConstraint.activate([
      titleLabelLeft.leftAnchor.constraint(equalTo: backgroundViewLeft.leftAnchor, constant: 16),
      titleLabelLeft.rightAnchor.constraint(equalTo: backgroundViewLeft.rightAnchor, constant: -16),
      titleLabelLeft.topAnchor.constraint(equalTo: backgroundViewLeft.topAnchor, constant: 10),
    ])

    backgroundViewLeft.addSubview(subTitleLabelLeft)
    NSLayoutConstraint.activate([
      subTitleLabelLeft.leftAnchor.constraint(equalTo: titleLabelLeft.leftAnchor),
      subTitleLabelLeft.rightAnchor.constraint(equalTo: titleLabelLeft.rightAnchor),
      subTitleLabelLeft.topAnchor.constraint(equalTo: titleLabelLeft.bottomAnchor, constant: 4),
    ])

    backgroundViewLeft.addSubview(mapImageViewLeft)
    NSLayoutConstraint.activate([
      mapImageViewLeft.leftAnchor.constraint(equalTo: backgroundViewLeft.leftAnchor),
      mapImageViewLeft.bottomAnchor.constraint(equalTo: backgroundViewLeft.bottomAnchor),
      mapImageViewLeft.rightAnchor.constraint(equalTo: backgroundViewLeft.rightAnchor),
      mapImageViewLeft.heightAnchor.constraint(equalToConstant: 86),
    ])

    mapImageViewLeft.addSubview(pointImageLeft)
    NSLayoutConstraint.activate([
      pointImageLeft.centerXAnchor.constraint(equalTo: mapImageViewLeft.centerXAnchor),
      pointImageLeft.bottomAnchor.constraint(equalTo: mapImageViewLeft.bottomAnchor, constant: -30),
    ])

    backgroundViewLeft.addSubview(emptyLabelLeft)
    NSLayoutConstraint.activate([
      emptyLabelLeft.leftAnchor.constraint(equalTo: backgroundViewLeft.leftAnchor),
      emptyLabelLeft.rightAnchor.constraint(equalTo: backgroundViewLeft.rightAnchor),
      emptyLabelLeft.bottomAnchor.constraint(equalTo: backgroundViewLeft.bottomAnchor, constant: -40),
    ])
  }

  override open func commonUIRight() {
    super.commonUIRight()
    bubbleImageRight.isHidden = true
    contentView.addSubview(backgroundViewRight)

    let messageLongPress = UILongPressGestureRecognizer(
      target: self,
      action: #selector(longPress)
    )

    backgroundViewRight.addGestureRecognizer(messageLongPress)
    NSLayoutConstraint.activate([
      backgroundViewRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor),
      backgroundViewRight.topAnchor.constraint(equalTo: bubbleImageRight.topAnchor),
      backgroundViewRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor),
      backgroundViewRight.bottomAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor),
    ])
    let messageTap = UITapGestureRecognizer(target: self, action: #selector(tapMessage))
    messageTap.cancelsTouchesInView = false
    backgroundViewRight.addGestureRecognizer(messageTap)

    backgroundViewRight.addSubview(titleLabelRight)
    NSLayoutConstraint.activate([
      titleLabelRight.leftAnchor.constraint(equalTo: backgroundViewRight.leftAnchor, constant: 16),
      titleLabelRight.rightAnchor.constraint(equalTo: backgroundViewRight.rightAnchor, constant: -16),
      titleLabelRight.topAnchor.constraint(equalTo: backgroundViewRight.topAnchor, constant: 10),
    ])

    backgroundViewRight.addSubview(subTitleLabelRight)
    NSLayoutConstraint.activate([
      subTitleLabelRight.leftAnchor.constraint(equalTo: titleLabelRight.leftAnchor),
      subTitleLabelRight.rightAnchor.constraint(equalTo: titleLabelRight.rightAnchor),
      subTitleLabelRight.topAnchor.constraint(equalTo: titleLabelRight.bottomAnchor, constant: 4),
    ])

    backgroundViewRight.addSubview(mapImageViewRight)
    NSLayoutConstraint.activate([
      mapImageViewRight.leftAnchor.constraint(equalTo: backgroundViewRight.leftAnchor),
      mapImageViewRight.bottomAnchor.constraint(equalTo: backgroundViewRight.bottomAnchor),
      mapImageViewRight.rightAnchor.constraint(equalTo: backgroundViewRight.rightAnchor),
      mapImageViewRight.heightAnchor.constraint(equalToConstant: 86),
    ])

    mapImageViewRight.addSubview(pointImageRight)
    NSLayoutConstraint.activate([
      pointImageRight.centerXAnchor.constraint(equalTo: mapImageViewRight.centerXAnchor),
      pointImageRight.bottomAnchor.constraint(equalTo: mapImageViewRight.bottomAnchor, constant: -30),
    ])

    backgroundViewRight.addSubview(emptyLabelRight)
    NSLayoutConstraint.activate([
      emptyLabelRight.leftAnchor.constraint(equalTo: backgroundViewRight.leftAnchor),
      emptyLabelRight.rightAnchor.constraint(equalTo: backgroundViewRight.rightAnchor),
      emptyLabelRight.bottomAnchor.constraint(equalTo: backgroundViewRight.bottomAnchor, constant: -40),
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

    if let m = model as? MessageLocationModel {
      titleLabel.text = m.title
      subTitleLabel.text = m.subTitle
      if let lat = m.lat, let lng = m.lng {
        if let url = NEChatKitClient.instance.delegate?.getMapImageUrl?(lat: lat, lng: lng) {
          NEALog.infoLog(className(), desc: #function + "location image url = \(url)")
          mapImageView.sd_setImage(with: URL(string: url),
                                   placeholderImage: coreLoader.loadImage("map_placeholder_image"),
                                   options: .retryFailed)
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
