//
//  VendorCell.swift
//  UTSAV
//
//  Created by Abhishek on 21/11/25.
//

import UIKit

final class VendorCell: UITableViewCell {

    var onSelect: (() -> Void)?

    private let title = UILabel()
    private let ratingLabel = UILabel()
    private let selectButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        selectionStyle = .none

        title.font = .systemFont(ofSize: 16, weight: .semibold)
        ratingLabel.font = .systemFont(ofSize: 14)

        selectButton.setTitle("Select", for: .normal)
        selectButton.addAction(UIAction { _ in self.onSelect?() }, for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [title, UIView(), ratingLabel, selectButton])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    func configure(vendor: Vendor) {
        title.text = vendor.name
        ratingLabel.text = "⭐ \(vendor.rating) • \(vendor.years) yrs"
    }
}
