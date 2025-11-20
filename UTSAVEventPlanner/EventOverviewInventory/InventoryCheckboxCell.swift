import UIKit

final class InventoryCheckboxCell: UITableViewCell {

    private let card = UIView()
    private let nameLabel = UILabel()
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
        card.layer.shadowOpacity = 0.08
        card.layer.shadowOffset = .init(width: 0, height: 2)
        card.layer.shadowRadius = 4
        card.translatesAutoresizingMaskIntoConstraints = false

        checkbox.tintColor = .systemGray
        checkbox.addTarget(self, action: #selector(toggle), for: .touchUpInside)

        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        quantityLabel.font = .systemFont(ofSize: 14)
        quantityLabel.textColor = .gray

        contentView.addSubview(card)
        [nameLabel, quantityLabel, checkbox].forEach { card.addSubview($0) }

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        quantityLabel.translatesAutoresizingMaskIntoConstraints = false
        checkbox.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),

            quantityLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            quantityLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),

            checkbox.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            checkbox.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            checkbox.widthAnchor.constraint(equalToConstant: 28),
            checkbox.heightAnchor.constraint(equalToConstant: 28),

            card.heightAnchor.constraint(equalToConstant: 64)
        ])
    }

    @objc private func toggle() {
        isChecked.toggle()
    }

    func configure(name: String, quantity: Int) {
        nameLabel.text = name
        quantityLabel.text = "Quantity: \(quantity)"
        isChecked = false
    }

    required init?(coder: NSCoder) { fatalError() }
}

