//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public class NERefreshHasNoMoreView: UIView {
  public lazy var tipLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = chatLocalizable("search_message_has_no_more")
    label.textColor = .ne_emptyTitleColor
    label.font = .systemFont(ofSize: 14)
    label.textAlignment = .center
    return label
  }()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func setupUI() {
    addSubview(tipLabel)
    NSLayoutConstraint.activate([
      tipLabel.topAnchor.constraint(equalTo: topAnchor),
      tipLabel.leftAnchor.constraint(equalTo: leftAnchor),
      tipLabel.rightAnchor.constraint(equalTo: rightAnchor),
      tipLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }
}
