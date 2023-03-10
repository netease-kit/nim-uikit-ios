// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEChatKit

@objcMembers
class ChatLocationRightCell: ChatBaseRightCell {
  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_darkText
    label.font = UIFont.systemFont(ofSize: 16.0)
    return label
  }()

  private lazy var subTitleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_lightText
    label.font = UIFont.systemFont(ofSize: 12.0)
    return label
  }()

  private lazy var emptyLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 16)
    label.text = chatLocalizable("no_map_plugin")
    label.textAlignment = .center
    label.textColor = UIColor.ne_greyText
    return label
  }()

  private var mapView: UIView?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func commonUI() {
    let back = UIView()
    back.backgroundColor = UIColor.white
    contentView.addSubview(back)
    bubbleImage.isHidden = true
    back.translatesAutoresizingMaskIntoConstraints = false
    back.clipsToBounds = true
    back.layer.cornerRadius = 4
    back.layer.borderWidth = 1
    back.layer.borderColor = UIColor.ne_outlineColor.cgColor
    let messageLongPress = UILongPressGestureRecognizer(
      target: self,
      action: #selector(longPress)
    )

    back.addGestureRecognizer(messageLongPress)
    NSLayoutConstraint.activate([
      back.leftAnchor.constraint(equalTo: bubbleImage.leftAnchor),
      back.topAnchor.constraint(equalTo: bubbleImage.topAnchor),
      back.rightAnchor.constraint(equalTo: bubbleImage.rightAnchor),
      back.bottomAnchor.constraint(equalTo: bubbleImage.bottomAnchor),
    ])
    let messageTap = UITapGestureRecognizer(target: self, action: #selector(tapMessage))
    back.addGestureRecognizer(messageTap)

    back.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: back.leftAnchor, constant: 16),
      titleLabel.rightAnchor.constraint(equalTo: back.rightAnchor, constant: -16),
      titleLabel.topAnchor.constraint(equalTo: back.topAnchor, constant: 10),
    ])

    back.addSubview(subTitleLabel)
    NSLayoutConstraint.activate([
      subTitleLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
      subTitleLabel.rightAnchor.constraint(equalTo: titleLabel.rightAnchor),
      subTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
    ])

    if let map = NEChatKitClient.instance.delegate?.getCellMapView?() as? UIView {
      mapView = map
      back.addSubview(map)
      map.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        map.leftAnchor.constraint(equalTo: back.leftAnchor),
        map.bottomAnchor.constraint(equalTo: back.bottomAnchor),
        map.rightAnchor.constraint(equalTo: back.rightAnchor),
        map.topAnchor.constraint(equalTo: subTitleLabel.bottomAnchor, constant: 4),
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
      back.addSubview(emptyLabel)
      NSLayoutConstraint.activate([
        emptyLabel.leftAnchor.constraint(equalTo: back.leftAnchor),
        emptyLabel.rightAnchor.constraint(equalTo: back.rightAnchor),
        emptyLabel.bottomAnchor.constraint(equalTo: back.bottomAnchor, constant: -40),
      ])
    }
  }

  override func setModel(_ model: MessageContentModel) {
    super.setModel(model)
    if let m = model as? MessageLocationModel {
      titleLabel.text = m.title
      subTitleLabel.text = m.subTitle
      if let lat = m.lat, let lng = m.lng, let map = mapView {
        NEChatKitClient.instance.delegate?.setMapviewLocation?(lat: lat, lng: lng, mapview: map)
      }
    }
  }
}
