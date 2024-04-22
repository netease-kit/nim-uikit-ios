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
    label.isHidden = true
    return label
  }()

  let pointImageView = UIImageView()

  public lazy var mapImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
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

    let contentBackView = UIView()
    contentBackView.backgroundColor = UIColor.white
    contentView.addSubview(contentBackView)
    contentBackView.translatesAutoresizingMaskIntoConstraints = false
    contentBackView.clipsToBounds = true
    contentBackView.layer.cornerRadius = 4
    contentBackView.layer.borderWidth = 1
    contentBackView.layer.borderColor = UIColor.ne_outlineColor.cgColor

    backView.addSubview(contentBackView)
    contentWidth = contentBackView.widthAnchor.constraint(equalToConstant: chat_content_maxW)
    contentHeight = contentBackView.heightAnchor.constraint(equalToConstant: chat_content_maxW)
    NSLayoutConstraint.activate([
      contentWidth!,
      contentHeight!,
      contentBackView.leftAnchor.constraint(equalTo: headerView.leftAnchor),
      contentBackView.topAnchor.constraint(equalTo: line.bottomAnchor, constant: 12),
    ])

    contentBackView.addSubview(locationTitleLabel)
    NSLayoutConstraint.activate([
      locationTitleLabel.leftAnchor.constraint(equalTo: contentBackView.leftAnchor, constant: 16),
      locationTitleLabel.rightAnchor.constraint(equalTo: contentBackView.rightAnchor, constant: -16),
      locationTitleLabel.topAnchor.constraint(equalTo: contentBackView.topAnchor, constant: 10),
    ])

    contentBackView.addSubview(subTitleLabel)
    NSLayoutConstraint.activate([
      subTitleLabel.leftAnchor.constraint(equalTo: locationTitleLabel.leftAnchor),
      subTitleLabel.rightAnchor.constraint(equalTo: locationTitleLabel.rightAnchor),
      subTitleLabel.topAnchor.constraint(equalTo: locationTitleLabel.bottomAnchor, constant: 4),
    ])

    contentBackView.addSubview(mapImageView)
    NSLayoutConstraint.activate([
      mapImageView.leftAnchor.constraint(equalTo: contentBackView.leftAnchor),
      mapImageView.bottomAnchor.constraint(equalTo: contentBackView.bottomAnchor),
      mapImageView.rightAnchor.constraint(equalTo: contentBackView.rightAnchor),
      mapImageView.topAnchor.constraint(equalTo: subTitleLabel.bottomAnchor, constant: 4),
    ])

    pointImageView.translatesAutoresizingMaskIntoConstraints = false
    pointImageView.image = coreLoader.loadImage("location_point")
    mapImageView.addSubview(pointImageView)
    NSLayoutConstraint.activate([
      pointImageView.centerXAnchor.constraint(equalTo: mapImageView.centerXAnchor),
      pointImageView.bottomAnchor.constraint(equalTo: mapImageView.bottomAnchor, constant: -30),
    ])

    contentBackView.addSubview(emptyLabel)
    NSLayoutConstraint.activate([
      emptyLabel.leftAnchor.constraint(equalTo: contentBackView.leftAnchor),
      emptyLabel.rightAnchor.constraint(equalTo: contentBackView.rightAnchor),
      emptyLabel.bottomAnchor.constraint(equalTo: contentBackView.bottomAnchor, constant: -40),
    ])

    if let gesture = contentGesture {
      contentBackView.addGestureRecognizer(gesture)
    }
  }

  override open func configure(_ item: NEPinMessageModel) {
    super.configure(item)
    if let m = item.chatmodel as? MessageLocationModel {
      locationTitleLabel.text = m.title
      subTitleLabel.text = m.subTitle
      if let lat = m.lat, let lng = m.lng {
        if let url = NEChatKitClient.instance.delegate?.getMapImageUrl?(lat: lat, lng: lng) {
          NEALog.infoLog(className(), desc: #function + "location image url = \(url)")
          mapImageView.sd_setImage(with: URL(string: url))
          emptyLabel.isHidden = true
          pointImageView.isHidden = false
        } else {
          emptyLabel.isHidden = false
          pointImageView.isHidden = true
        }
      }
    }
  }
}
