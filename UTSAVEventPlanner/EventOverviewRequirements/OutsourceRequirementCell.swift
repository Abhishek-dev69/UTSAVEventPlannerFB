import UIKit

final class OutsourceRequirementCell: UITableViewCell {

    // MARK: - Callbacks
    var onSelectionChanged: ((Bool) -> Void)?

    // MARK: - UI
    private let container = UIView()
    private let checkbox = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let descLabel = UILabel()
    private let budgetLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        checkbox.isSelected = false
        onSelectionChanged = nil
    }

    private func setup() {

        contentView.backgroundColor = .systemGroupedBackground

        // Card container
        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        // Checkbox (clean, no background)
        checkbox.setImage(UIImage(systemName: "circle"), for: .normal)
        checkbox.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        checkbox.tintColor = .utsavPurple
        checkbox.backgroundColor = .clear
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.addTarget(self, action: #selector(toggle), for: .touchUpInside)

        // Labels
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        descLabel.font = .systemFont(ofSize: 13)
        descLabel.textColor = .darkGray

        budgetLabel.font = .systemFont(ofSize: 14, weight: .medium)
        budgetLabel.textColor = .systemGreen

        [titleLabel, descLabel, budgetLabel, checkbox].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }

        NSLayoutConstraint.activate([
            // Card
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // Checkbox (RIGHT, clean)
            checkbox.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            checkbox.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            checkbox.widthAnchor.constraint(equalToConstant: 26),
            checkbox.heightAnchor.constraint(equalToConstant: 26),

            // Title
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: checkbox.leadingAnchor, constant: -12),

            // Description
            descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            descLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            // Budget
            budgetLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            budgetLabel.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 8),
            budgetLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            budgetLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        ])
    }

    @objc private func toggle() {
        checkbox.isSelected.toggle()
        onSelectionChanged?(checkbox.isSelected)
    }

    func configure(item: CartItemRecord, isSelected: Bool) {
        checkbox.isSelected = isSelected
        titleLabel.text = item.serviceName ?? "Service"
        descLabel.text = "Client Requirement: \(item.subserviceName ?? "—")"

        let total = Int((item.rate ?? 0) * Double(item.quantity ?? 1))
        budgetLabel.text = "Clients Budget: ₹\(total)"
    }
}

extension UIColor {
    static let utsavPurple = UIColor(
        red: 136/255,
        green: 71/255,
        blue: 246/255,
        alpha: 1
    )
}
