
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NIMSDK
import UIKit

@objcMembers
open class ChatMessageFileCell: NormalChatMessageBaseCell {
  weak var weakModel: MessageFileModel?

  public lazy var imgViewLeft: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.backgroundColor = .clear
    imageView.accessibilityIdentifier = "id.fileType"
    return imageView
  }()

  public lazy var stateViewLeft: FileStateView = {
    let stateView = FileStateView()
    stateView.translatesAutoresizingMaskIntoConstraints = false
    stateView.backgroundColor = .clear
    stateView.accessibilityIdentifier = "id.fileStatus"
    return stateView
  }()

  public lazy var titleLabelLeft: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isUserInteractionEnabled = false
    label.numberOfLines = 1
    label.lineBreakMode = .byTruncatingMiddle
    label.font = DefaultTextFont(14)
    label.textAlignment = .left
    label.accessibilityIdentifier = "id.displayName"
    return label
  }()

  public lazy var sizeLabelLeft: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor(hexString: "#999999")
    label.font = NEConstant.defaultTextFont(10.0)
    label.textAlignment = .left
    label.accessibilityIdentifier = "id.displaySize"
    return label
  }()

  public lazy var labelViewLeft: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isUserInteractionEnabled = false
    view.addSubview(titleLabelLeft)
    NSLayoutConstraint.activate([
      titleLabelLeft.leftAnchor.constraint(equalTo: view.leftAnchor),
      titleLabelLeft.topAnchor.constraint(equalTo: view.topAnchor),
      titleLabelLeft.rightAnchor.constraint(equalTo: view.rightAnchor),
      titleLabelLeft.heightAnchor.constraint(equalToConstant: 18),
    ])
    view.addSubview(sizeLabelLeft)
    NSLayoutConstraint.activate([
      sizeLabelLeft.leftAnchor.constraint(equalTo: view.leftAnchor),
      sizeLabelLeft.topAnchor.constraint(equalTo: titleLabelLeft.bottomAnchor, constant: 5),
      sizeLabelLeft.rightAnchor.constraint(equalTo: view.rightAnchor),
      sizeLabelLeft.heightAnchor.constraint(equalToConstant: 10),
    ])
    return view
  }()

  public lazy var backViewLeft: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .white
    view.layer.cornerRadius = 8
    view.layer.borderColor = UIColor.ne_borderColor.cgColor
    view.layer.borderWidth = 1

    view.addSubview(imgViewLeft)
    NSLayoutConstraint.activate([
      imgViewLeft.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10),
      imgViewLeft.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      imgViewLeft.widthAnchor.constraint(equalToConstant: 32),
      imgViewLeft.heightAnchor.constraint(equalToConstant: 32),
    ])

    imgViewLeft.addSubview(stateViewLeft)
    NSLayoutConstraint.activate([
      stateViewLeft.leftAnchor.constraint(equalTo: imgViewLeft.leftAnchor, constant: 0),
      stateViewLeft.topAnchor.constraint(equalTo: imgViewLeft.topAnchor, constant: 0),
      stateViewLeft.widthAnchor.constraint(equalToConstant: 32),
      stateViewLeft.heightAnchor.constraint(equalToConstant: 32),
    ])

    view.addSubview(labelViewLeft)
    NSLayoutConstraint.activate([
      labelViewLeft.leftAnchor.constraint(equalTo: imgViewLeft.rightAnchor, constant: 15),
      labelViewLeft.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
      labelViewLeft.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10),
      labelViewLeft.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
    ])
    return view
  }()

  public lazy var imgViewRight: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.backgroundColor = .clear
    imageView.accessibilityIdentifier = "id.fileType"
    return imageView
  }()

  public lazy var stateViewRight: FileStateView = {
    let state = FileStateView()
    state.translatesAutoresizingMaskIntoConstraints = false
    state.backgroundColor = .clear
    state.accessibilityIdentifier = "id.fileStatus"
    return state
  }()

  public lazy var titleLabelRight: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isUserInteractionEnabled = false
    label.numberOfLines = 1
    label.lineBreakMode = .byTruncatingMiddle
    label.font = DefaultTextFont(14)
    label.textAlignment = .left
    label.accessibilityIdentifier = "id.displayName"
    return label
  }()

  public lazy var sizeLabelRight: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor(hexString: "#999999")
    label.font = NEConstant.defaultTextFont(10.0)
    label.textAlignment = .left
    label.accessibilityIdentifier = "id.displaySize"
    return label
  }()

  public lazy var labelViewRight: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isUserInteractionEnabled = false
    view.addSubview(titleLabelRight)
    NSLayoutConstraint.activate([
      titleLabelRight.leftAnchor.constraint(equalTo: view.leftAnchor),
      titleLabelRight.topAnchor.constraint(equalTo: view.topAnchor),
      titleLabelRight.rightAnchor.constraint(equalTo: view.rightAnchor),
      titleLabelRight.heightAnchor.constraint(equalToConstant: 18),
    ])
    view.addSubview(sizeLabelRight)
    NSLayoutConstraint.activate([
      sizeLabelRight.leftAnchor.constraint(equalTo: view.leftAnchor),
      sizeLabelRight.topAnchor.constraint(equalTo: titleLabelRight.bottomAnchor, constant: 5),
      sizeLabelRight.rightAnchor.constraint(equalTo: view.rightAnchor),
      sizeLabelRight.heightAnchor.constraint(equalToConstant: 10),
    ])
    return view
  }()

  public lazy var backViewRight: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .white
    view.layer.cornerRadius = 8
    view.layer.borderColor = UIColor.ne_borderColor.cgColor
    view.layer.borderWidth = 1

    view.addSubview(imgViewRight)
    NSLayoutConstraint.activate([
      imgViewRight.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10),
      imgViewRight.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      imgViewRight.widthAnchor.constraint(equalToConstant: 32),
      imgViewRight.heightAnchor.constraint(equalToConstant: 32),
    ])

    imgViewRight.addSubview(stateViewRight)
    NSLayoutConstraint.activate([
      stateViewRight.leftAnchor.constraint(equalTo: imgViewRight.leftAnchor, constant: 0),
      stateViewRight.topAnchor.constraint(equalTo: imgViewRight.topAnchor, constant: 0),
      stateViewRight.widthAnchor.constraint(equalToConstant: 32),
      stateViewRight.heightAnchor.constraint(equalToConstant: 32),
    ])

    view.addSubview(labelViewRight)
    NSLayoutConstraint.activate([
      labelViewRight.leftAnchor.constraint(equalTo: imgViewRight.rightAnchor, constant: 15),
      labelViewRight.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
      labelViewRight.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10),
      labelViewRight.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
    ])
    return view
  }()

  override open func commonUILeft() {
    super.commonUILeft()
    bubbleImageLeft.addSubview(backViewLeft)
    NSLayoutConstraint.activate([
      backViewLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: 0),
      backViewLeft.topAnchor.constraint(equalTo: replyViewLeft.bottomAnchor, constant: 0),
      backViewLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor, constant: 0),
      backViewLeft.bottomAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor, constant: 0),
    ])
  }

  override open func commonUIRight() {
    super.commonUIRight()
    bubbleImageRight.addSubview(backViewRight)
    NSLayoutConstraint.activate([
      backViewRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: 0),
      backViewRight.topAnchor.constraint(equalTo: replyViewRight.bottomAnchor, constant: 0),
      backViewRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: 0),
      backViewRight.bottomAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor, constant: 0),
    ])
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)
    backViewLeft.isHidden = showRight
    backViewRight.isHidden = !showRight
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    super.setModel(model, isSend)
    let stateView = isSend ? stateViewRight : stateViewLeft
    let imgView = isSend ? imgViewRight : imgViewLeft
    let titleLabel = isSend ? titleLabelRight : titleLabelLeft
    let sizeLabel = isSend ? sizeLabelRight : sizeLabelLeft
    let bubbleW = isSend ? bubbleWRight : bubbleWLeft
    let bubble = isSend ? bubbleImageRight : bubbleImageLeft

    bubbleW?.constant = kScreenWidth <= 320 ? 222 : 242 // 适配小屏幕

    if model.isReply {
      setBubbleImage()
    } else {
      bubble.image = nil
    }

    if let fileObject = model.message?.attachment as? V2NIMMessageFileAttachment {
      if let fileModel = model as? MessageFileModel {
        weakModel?.cell = nil
        weakModel = fileModel
        fileModel.cell = self
        fileModel.size = Float(fileObject.size)
        if fileModel.state == .Success {
          stateView.state = .FileOpen
        } else {
          stateView.state = .FileDownload
          stateView.setProgress(Float(fileModel.progress / 100))
          if fileModel.progress >= 100 {
            fileModel.state = .Success
          }
        }
      }
      var imageName = "file_unknown"
      var suffix = (fileObject.name as NSString).pathExtension.lowercased()
      if suffix.isEmpty, let ext = fileObject.ext {
        suffix = ext[(ext.index(after: ext.startIndex)) ..< ext.endIndex].lowercased()
      }
      switch suffix {
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
      case file_video_support:
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

      imgView.image = UIImage.ne_imageNamed(name: imageName)
      titleLabel.text = fileObject.name

      let size_B = Double(fileObject.size)
      var size_str = String(format: "%.2f B", size_B)
      if size_B > 1e3 {
        let size_KB = size_B / 1e3
        size_str = String(format: "%.2f KB", size_KB)
        if size_KB > 1e3 {
          let size_MB = size_KB / 1e3
          size_str = String(format: "%.2f MB", size_MB)
          if size_MB > 1e3 {
            let size_GB = size_KB / 1e6
            size_str = String(format: "%.2f GB", size_GB)
          }
        }
      }
      sizeLabel.text = size_str
    }
  }

  override open func uploadProgress(_ progress: UInt) {
    let stateView = stateViewLeft.isHidden ? stateViewRight : stateViewLeft
    stateView.setProgress(Float(progress) / 100)
  }
}
