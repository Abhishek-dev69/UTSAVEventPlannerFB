import UIKit

final class InventoryCheckboxCell: UITableViewCell {

    // MARK: - UI
    private let card = UIView()
    private let badgeLabel = UILabel()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let quantityLabel = UILabel()
    private let checkbox = UIButton(type: .system)

    // MARK: - Callback (no state here)
    var onChecked: (() -> Void)?

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        setupCard()
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupCard() {
        card.backgroundColor = .white
        card.layer.cornerRadius = 10
        card.layer.shadowOpacity = 0.06
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 4
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)
    }

    private func setupViews() {
        checkbox.tintColor = .systemGray
        checkbox.setImage(UIImage(systemName: "square"), for: .normal)
        checkbox.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)

        badgeLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = 18
        badgeLabel.clipsToBounds = true

        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .systemGray

        quantityLabel.font = .systemFont(ofSize: 14)
        quantityLabel.textColor = .gray

        [badgeLabel, nameLabel, subtitleLabel, quantityLabel, checkbox].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview($0)
        }
    }

    private func setupConstraints() {
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

            checkbox.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            checkbox.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            checkbox.widthAnchor.constraint(equalToConstant: 28),
            checkbox.heightAnchor.constraint(equalToConstant: 28),

            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 76)
        ])
    }

    // MARK: - Action
    @objc private func checkboxTapped() {
        // ✅ DO NOT toggle UI
        // ✅ DO NOT reload table
        // ✅ DO NOT post notifications
        onChecked?()
    }

    // MARK: - Configure
    func configure(name: String, quantity: Int, sourceType: String?) {
        nameLabel.text = name
        quantityLabel.text = "Qty: \(quantity)"

        // Always neutral checkbox state
        checkbox.tintColor = .systemGray
        checkbox.setImage(UIImage(systemName: "square"), for: .normal)

        let lower = (sourceType ?? "planner").lowercased()
        subtitleLabel.text = (lower == "vendor") ? "Vendor Inventory" : "My Inventory"

        let initials = name
            .split(separator: " ")
            .prefix(2)
            .map { String($0.prefix(1)) }
            .joined()
            .uppercased()

        badgeLabel.text = initials.isEmpty ? "?" : initials

        badgeLabel.backgroundColor = (lower == "vendor")
            ? UIColor(red: 34/255, green: 139/255, blue: 230/255, alpha: 1)
            : UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
    }
}
