import UIKit

final class InventoryListCell: UITableViewCell {

    private let card = UIView()
    private let nameLabel = UILabel()
    private let quantityLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        card.layer.cornerRadius = 10
        card.backgroundColor = .white
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 4
        card.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        quantityLabel.font = .systemFont(ofSize: 14)
        quantityLabel.textColor = .gray

        contentView.addSubview(card)
        card.addSubview(nameLabel)
        card.addSubview(quantityLabel)

        card.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        quantityLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),

            quantityLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            quantityLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),

            card.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(name: String, quantity: Int) {
        nameLabel.text = name
        quantityLabel.text = "Quantity: \(quantity)"
    }
}

