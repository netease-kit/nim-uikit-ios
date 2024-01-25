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
    return label
  }()

  public var mapViewLeft: UIView?
  let backgroundViewLeft = UIView()

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

  public var mapViewRight: UIView?
  let backgroundViewRight = UIView()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open func commonUI() {
    commonUIRight()
    commonUILeft()
  }

  open func commonUILeft() {
    backgroundViewLeft.backgroundColor = UIColor.white
    contentView.addSubview(backgroundViewLeft)
    bubbleImageLeft.isHidden = true
    backgroundViewLeft.translatesAutoresizingMaskIntoConstraints = false
    backgroundViewLeft.clipsToBounds = true
    backgroundViewLeft.layer.cornerRadius = 4
    backgroundViewLeft.layer.borderWidth = 1
    backgroundViewLeft.layer.borderColor = UIColor.ne_outlineColor.cgColor
    backgroundViewLeft.accessibilityIdentifier = "id.mapView"

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

    if let map = NEChatKitClient.instance.delegate?.getCellMapView?() as? UIView {
      mapViewLeft = map
      backgroundViewLeft.addSubview(map)
      map.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        map.leftAnchor.constraint(equalTo: backgroundViewLeft.leftAnchor),
        map.bottomAnchor.constraint(equalTo: backgroundViewLeft.bottomAnchor),
        map.rightAnchor.constraint(equalTo: backgroundViewLeft.rightAnchor),
        map.topAnchor.constraint(equalTo: subTitleLabelLeft.bottomAnchor, constant: 4),
      ])

      let pointImage = UIImageView()
      pointImage.translatesAutoresizingMaskIntoConstraints = false
      pointImage.image = coreLoader.loadImage("location_point")
      map.addSubview(pointImage)
      NSLayoutConstraint.activate([
        pointImage.centerXAnchor.constraint(equalTo: map.centerXAnchor),
        pointImage.bottomAnchor.constraint(equalTo: map.bottomAnchor, constant: -30),
      ])
    } else {
      backgroundViewLeft.addSubview(emptyLabelLeft)
      NSLayoutConstraint.activate([
        emptyLabelLeft.leftAnchor.constraint(equalTo: backgroundViewLeft.leftAnchor),
        emptyLabelLeft.rightAnchor.constraint(equalTo: backgroundViewLeft.rightAnchor),
        emptyLabelLeft.bottomAnchor.constraint(equalTo: backgroundViewLeft.bottomAnchor, constant: -40),
      ])
    }
  }

  open func commonUIRight() {
    backgroundViewRight.backgroundColor = UIColor.white
    contentView.addSubview(backgroundViewRight)
    bubbleImageRight.isHidden = true
    backgroundViewRight.translatesAutoresizingMaskIntoConstraints = false
    backgroundViewRight.clipsToBounds = true
    backgroundViewRight.layer.cornerRadius = 4
    backgroundViewRight.layer.borderWidth = 1
    backgroundViewRight.layer.borderColor = UIColor.ne_outlineColor.cgColor
    backgroundViewRight.accessibilityIdentifier = "id.mapView"

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

    if let map = NEChatKitClient.instance.delegate?.getCellMapView?() as? UIView {
      mapViewRight = map
      backgroundViewRight.addSubview(map)
      map.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        map.leftAnchor.constraint(equalTo: backgroundViewRight.leftAnchor),
        map.bottomAnchor.constraint(equalTo: backgroundViewRight.bottomAnchor),
        map.rightAnchor.constraint(equalTo: backgroundViewRight.rightAnchor),
        map.topAnchor.constraint(equalTo: subTitleLabelRight.bottomAnchor, constant: 4),
      ])

      let pointImage = UIImageView()
      pointImage.translatesAutoresizingMaskIntoConstraints = false
      pointImage.image = coreLoader.loadImage("location_point")
      map.addSubview(pointImage)
      NSLayoutConstraint.activate([
        pointImage.centerXAnchor.constraint(equalTo: map.centerXAnchor),
        pointImage.bottomAnchor.constraint(equalTo: map.bottomAnchor, constant: -30),
      ])
    } else {
      backgroundViewRight.addSubview(emptyLabelRight)
      NSLayoutConstraint.activate([
        emptyLabelRight.leftAnchor.constraint(equalTo: backgroundViewRight.leftAnchor),
        emptyLabelRight.rightAnchor.constraint(equalTo: backgroundViewRight.rightAnchor),
        emptyLabelRight.bottomAnchor.constraint(equalTo: backgroundViewRight.bottomAnchor, constant: -40),
      ])
    }
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
    let mapView = isSend ? mapViewRight : mapViewLeft
    let bubbleW = isSend ? bubbleWRight : bubbleWLeft

    bubbleW?.constant = kScreenWidth <= 320 ? 222 : 242 // 适配小屏幕

    if let m = model as? MessageLocationModel {
      titleLabel.text = m.title
      subTitleLabel.text = m.subTitle
      if let lat = m.lat, let lng = m.lng, let map = mapView {
        NEChatKitClient.instance.delegate?.setMapviewLocation?(lat: lat, lng: lng, mapview: map)
      }
    }
  }
}
