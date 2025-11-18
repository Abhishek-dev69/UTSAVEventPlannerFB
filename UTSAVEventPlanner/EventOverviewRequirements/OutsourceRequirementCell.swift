import UIKit

final class OutsourceRequirementCell: UITableViewCell {

    // MARK: - UI Elements
    private let container: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        v.layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 6
        v.layer.shadowOpacity = 1
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.numberOfLines = 1
        return l
    }()

    private let descLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.numberOfLines = 2
        l.textColor = .darkGray
        return l
    }()

    private let budgetLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.numberOfLines = 1
        l.textColor = .systemGreen
        return l
    }()

    private let assignButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("Assign", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        return b
    }()

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = .systemGroupedBackground
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.addSubview(container)
        container.addSubview(titleLabel)
        container.addSubview(descLabel)
        container.addSubview(budgetLabel)
        container.addSubview(assignButton)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: assignButton.leadingAnchor, constant: -8),

            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            descLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            descLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),

            budgetLabel.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 8),
            budgetLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            budgetLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),

            assignButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            assignButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            assignButton.heightAnchor.constraint(equalToConstant: 32),
            assignButton.widthAnchor.constraint(equalToConstant: 80)
        ])
    }

    // MARK: - Configure
    /// Safely configure cell from a server CartItemRecord (fields may be optional)
    func configure(item: CartItemRecord) {
        // Safely unwrap strings with default friendly placeholders
        let serviceName = item.serviceName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let subserviceName = item.subserviceName?.trimmingCharacters(in: .whitespacesAndNewlines)

        titleLabel.text = serviceName?.isEmpty == false ? serviceName : "Service"
        descLabel.text = "Client Requirement: " + (subserviceName?.isEmpty == false ? subserviceName! : "—")

        // Safely unwrap numeric values; default to 0
        let rateValue: Double = item.rate ?? 0.0
        let qtyValue: Int = item.quantity ?? 0

        // Compute total (as integer rupees)
        let total = Int(rateValue * Double(qtyValue))
        // Format with rupee symbol; you can localize as needed
        budgetLabel.text = "Clients Budget: ₹\(total)"
    }

    // Optional: expose assign button action
    func setAssignAction(_ target: Any?, action: Selector) {
        assignButton.addTarget(target, action: action, for: .touchUpInside)
    }
}
