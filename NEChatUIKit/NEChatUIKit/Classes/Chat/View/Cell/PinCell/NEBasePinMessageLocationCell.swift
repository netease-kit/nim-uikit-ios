// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonKit
import UIKit

@objcMembers
open class NEBasePinMessageLocationCell: NEBasePinMessageCell {
  private lazy var locationTitleLabel: UILabel = {
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

  var mapView: UIView?

  override open func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override open func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func setupUI() {
    super.setupUI()

    let back = UIView()
    back.backgroundColor = UIColor.white
    contentView.addSubview(back)
    back.translatesAutoresizingMaskIntoConstraints = false
    back.clipsToBounds = true
    back.layer.cornerRadius = 4
    back.layer.borderWidth = 1
    back.layer.borderColor = UIColor.ne_outlineColor.cgColor

    backView.addSubview(back)
    contentWidth = back.widthAnchor.constraint(equalToConstant: chat_content_maxW)
    contentHeight = back.heightAnchor.constraint(equalToConstant: chat_content_maxW)
    NSLayoutConstraint.activate([
      contentWidth!,
      contentHeight!,
      back.leftAnchor.constraint(equalTo: headerView.leftAnchor),
      back.topAnchor.constraint(equalTo: line.bottomAnchor, constant: 12),
    ])

    back.addSubview(locationTitleLabel)
    NSLayoutConstraint.activate([
      locationTitleLabel.leftAnchor.constraint(equalTo: back.leftAnchor, constant: 16),
      locationTitleLabel.rightAnchor.constraint(equalTo: back.rightAnchor, constant: -16),
      locationTitleLabel.topAnchor.constraint(equalTo: back.topAnchor, constant: 10),
    ])

    back.addSubview(subTitleLabel)
    NSLayoutConstraint.activate([
      subTitleLabel.leftAnchor.constraint(equalTo: locationTitleLabel.leftAnchor),
      subTitleLabel.rightAnchor.constraint(equalTo: locationTitleLabel.rightAnchor),
      subTitleLabel.topAnchor.constraint(equalTo: locationTitleLabel.bottomAnchor, constant: 4),
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
    mapView?.isUserInteractionEnabled = false
    if let gesture = contentGesture {
      back.addGestureRecognizer(gesture)
    }
  }

  override open func configure(_ item: PinMessageModel) {
    super.configure(item)
    if let m = item.chatmodel as? MessageLocationModel {
      locationTitleLabel.text = m.title
      subTitleLabel.text = m.subTitle
      if let lat = m.lat, let lng = m.lng, let map = mapView {
        NEChatKitClient.instance.delegate?.setMapviewLocation?(lat: lat, lng: lng, mapview: map)
      }
    }
  }
}
