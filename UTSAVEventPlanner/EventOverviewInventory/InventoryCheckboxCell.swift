// InventoryCheckboxCell.swift
// Checkbox row for Post-Event with source subtitle label (planner/vendor)

import UIKit

final class InventoryCheckboxCell: UITableViewCell {

    private let card = UIView()
    private let badgeLabel = UILabel()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel() // shows "My Inventory" / "Vendor Inventory"
    private let quantityLabel = UILabel()
    private let checkbox = UIButton(type: .system)

    var onChecked: ((Bool) -> Void)?

    private var isChecked = false {
        didSet {
            checkbox.tintColor = isChecked ? .systemPurple : .systemGray
            checkbox.setImage(UIImage(systemName: isChecked ? "checkmark.square.fill" : "square"), for: .normal)
            onChecked?(isChecked)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        card.backgroundColor = .white
        card.layer.cornerRadius = 10
        card.layer.shadowOpacity = 0.06
        card.layer.shadowOffset = .init(width: 0, height: 2)
        card.layer.shadowRadius = 4
        card.translatesAutoresizingMaskIntoConstraints = false

        checkbox.tintColor = .systemGray
        checkbox.addTarget(self, action: #selector(toggle), for: .touchUpInside)

        badgeLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = 18
        badgeLabel.clipsToBounds = true
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = .systemGray
        quantityLabel.font = .systemFont(ofSize: 14)
        quantityLabel.textColor = .gray

        contentView.addSubview(card)
        [badgeLabel, nameLabel, subtitleLabel, quantityLabel, checkbox].forEach { card.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            badgeLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            badgeLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            badgeLabel.widthAnchor.constraint(equalToConstant: 36),
            badgeLabel.heightAnchor.constraint(equalToConstant: 36),

            nameLabel.leadingAnchor.constraint(equalTo: badgeLabel.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),

            subtitleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),

            quantityLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            quantityLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 6),

            checkbox.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            checkbox.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            checkbox.widthAnchor.constraint(equalToConstant: 28),
            checkbox.heightAnchor.constraint(equalToConstant: 28),

            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 76)
        ])
    }

    @objc private func toggle() {
        isChecked.toggle()
    }

    /// Configure cell with sourceType included.
    func configure(name: String, quantity: Int, sourceType: String?) {
        nameLabel.text = name
        quantityLabel.text = "Qty: \(quantity)"
        isChecked = false

        let lower = (sourceType ?? "planner").lowercased()
        subtitleLabel.text = (lower == "vendor") ? "Vendor Inventory" : "My Inventory"

        // initials
        let short = name
            .split(separator: " ")
            .prefix(2)
            .map { String($0.prefix(1)) }
            .joined()
            .uppercased()
        badgeLabel.text = short.isEmpty ? "?" : short

        // badge color
        if lower == "vendor" {
            badgeLabel.backgroundColor = UIColor(red: 34/255, green: 139/255, blue: 230/255, alpha: 1)
        } else {
            badgeLabel.backgroundColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
