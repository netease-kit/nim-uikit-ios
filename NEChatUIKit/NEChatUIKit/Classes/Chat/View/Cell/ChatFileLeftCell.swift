
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECommonKit
import NIMSDK

@objcMembers
public class ChatFileLeftCell: ChatBaseLeftCell {
  lazy var imgView: UIImageView = {
    let view_img = UIImageView()
    view_img.translatesAutoresizingMaskIntoConstraints = false
    view_img.backgroundColor = .clear
    return view_img
  }()

  lazy var stateView: FileStateView = {
    let state = FileStateView()
    state.translatesAutoresizingMaskIntoConstraints = false
    state.backgroundColor = .clear
    return state
  }()

  lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isUserInteractionEnabled = false
    label.numberOfLines = 1
    label.lineBreakMode = .byTruncatingMiddle
    label.font = DefaultTextFont(14)
    label.textAlignment = .left
    return label
  }()

  lazy var sizeLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor(hexString: "#999999")
    label.font = NEConstant.defaultTextFont(10.0)
    label.textAlignment = .left
    return label
  }()

  lazy var labelView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isUserInteractionEnabled = false
    view.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
      titleLabel.topAnchor.constraint(equalTo: view.topAnchor),
      titleLabel.rightAnchor.constraint(equalTo: view.rightAnchor),
      titleLabel.heightAnchor.constraint(equalToConstant: 18),
    ])
    view.addSubview(sizeLabel)
    NSLayoutConstraint.activate([
      sizeLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
      sizeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
      sizeLabel.rightAnchor.constraint(equalTo: view.rightAnchor),
      sizeLabel.heightAnchor.constraint(equalToConstant: 10),
    ])
    return view
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupUI()
    bubbleImage.image = nil
    bubbleImage.layer.cornerRadius = 8
    bubbleImage.layer.borderColor = UIColor.ne_borderColor.cgColor
    bubbleImage.layer.borderWidth = 1
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setupUI() {
    addSubview(imgView)
    NSLayoutConstraint.activate([
      imgView.leftAnchor.constraint(equalTo: bubbleImage.leftAnchor, constant: 10),
      imgView.topAnchor.constraint(equalTo: bubbleImage.topAnchor, constant: 10),
      imgView.widthAnchor.constraint(equalToConstant: 32),
      imgView.heightAnchor.constraint(equalToConstant: 32),
    ])

    addSubview(stateView)
    NSLayoutConstraint.activate([
      stateView.leftAnchor.constraint(equalTo: bubbleImage.leftAnchor, constant: 10),
      stateView.topAnchor.constraint(equalTo: bubbleImage.topAnchor, constant: 10),
      stateView.widthAnchor.constraint(equalToConstant: 32),
      stateView.heightAnchor.constraint(equalToConstant: 32),
    ])

    addSubview(labelView)
    NSLayoutConstraint.activate([
      labelView.leftAnchor.constraint(equalTo: imgView.rightAnchor, constant: 15),
      labelView.topAnchor.constraint(equalTo: bubbleImage.topAnchor, constant: 10),
      labelView.rightAnchor.constraint(equalTo: bubbleImage.rightAnchor, constant: -10),
      labelView.bottomAnchor.constraint(equalTo: bubbleImage.bottomAnchor, constant: 0),
    ])
  }

  override func setModel(_ model: MessageContentModel) {
    super.setModel(model)
    if let fileObject = model.message?.messageObject as? NIMFileObject {
      if let fileModel = model as? MessageFileModel {
        fileModel.cell = self
        fileModel.size = Float(fileObject.fileLength)
        if fileModel.state == .Success {
          stateView.state = .FileOpen
        } else {
          stateView.state = .FileDownload
          stateView.setProgress(fileModel.progress)
          if fileModel.progress >= 1 {
            fileModel.state = .Success
          }
        }
      }
      var imageName = "file_unknown"
      var displayName = "未知文件"
      if let filePath = fileObject.path as? NSString {
        displayName = filePath.lastPathComponent
        switch filePath.pathExtension.lowercased() {
        case file_doc_support:
          imageName = "file_doc"
        case file_xls_support:
          imageName = "file_xls"
        case file_img_support:
          imageName = "file_img"
        case file_ppt_support:
          imageName = "file_ppt"
        case file_txt_support:
          imageName = "file_txt"
        case file_audio_support:
          imageName = "file_audio"
        case file_vedio_support:
          imageName = "file_vedio"
        case file_zip_support:
          imageName = "file_zip"
        case file_pdf_support:
          imageName = "file_pdf"
        case file_html_support:
          imageName = "file_html"
        case "key", "keynote":
          imageName = "file_keynote"
        default:
          imageName = "file_unknown"
        }
      }
      imgView.image = UIImage.ne_imageNamed(name: imageName)
      titleLabel.text = fileObject.displayName ?? displayName
      let size_B = Double(fileObject.fileLength)
      var size_str = String(format: "%.1f B", size_B)
      if size_B > 1e3 {
        let size_KB = size_B / 1e3
        size_str = String(format: "%.1f KB", size_KB)
        if size_KB > 1e3 {
          let size_MB = size_KB / 1e3
          size_str = String(format: "%.1f MB", size_MB)
          if size_MB > 1e3 {
            let size_GB = size_KB / 1e6
            size_str = String(format: "%.1f GB", size_GB)
          }
        }
      }
      sizeLabel.text = size_str
    }
  }

  override public func uploadProgress(_ progress: Float) {
    stateView.setProgress(progress)
  }
}
