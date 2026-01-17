import UIKit

final class OutsourceRequirementCell: UITableViewCell {

    // MARK: - Callback
    var onSelectionChanged: ((Bool) -> Void)?

    // MARK: - UI
    private let container = UIView()
    private let checkbox = UIButton(type: .custom) // 🔴 IMPORTANT

    private let titleLabel = UILabel()
    private let descLabel = UILabel()
    private let budgetLabel = UILabel()

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        checkbox.isSelected = false
        checkbox.isEnabled = true
        onSelectionChanged = nil
        updateCheckboxUI()
    }

    // MARK: - Setup
    private func setupUI() {

        contentView.backgroundColor = .systemGroupedBackground

        // Card
        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        // Checkbox (CUSTOM BUTTON → no UIKit padding)
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.backgroundColor = .clear
        checkbox.layer.cornerRadius = 13
        checkbox.layer.borderWidth = 2
        checkbox.layer.borderColor = UIColor.utsavPurple.cgColor

        // 🔴 CRITICAL FIXES
        checkbox.contentEdgeInsets = .zero
        checkbox.imageEdgeInsets = .zero
        checkbox.adjustsImageWhenHighlighted = false

        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        checkbox.setImage(
            UIImage(systemName: "checkmark", withConfiguration: config),
            for: .selected
        )
        checkbox.tintColor = .white

        checkbox.addTarget(self, action: #selector(toggle), for: .touchUpInside)
        container.addSubview(checkbox)

        // Labels
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        descLabel.font = .systemFont(ofSize: 13)
        descLabel.textColor = .darkGray

        budgetLabel.font = .systemFont(ofSize: 14, weight: .medium)
        budgetLabel.textColor = .systemGreen

        [titleLabel, descLabel, budgetLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }

        NSLayoutConstraint.activate([

            // Card
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // Checkbox
            checkbox.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            checkbox.centerYAnchor.constraint(equalTo: container.centerYAnchor),
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
            budgetLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            budgetLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
    }

    // MARK: - Toggle
    @objc private func toggle() {
        checkbox.isSelected.toggle()
        updateCheckboxUI()
        onSelectionChanged?(checkbox.isSelected)
    }

    private func updateCheckboxUI() {
        if checkbox.isSelected {
            checkbox.backgroundColor = .utsavPurple
            checkbox.layer.borderWidth = 0
        } else {
            checkbox.backgroundColor = .clear
            checkbox.layer.borderWidth = 2
            checkbox.layer.borderColor = UIColor.utsavPurple.cgColor
        }
    }

    // MARK: - Configure
    func configure(item: CartItemRecord, isSelected: Bool) {

        titleLabel.text = item.serviceName
        descLabel.text = "Client Requirement: \(item.subserviceName ?? "")"

        let total = Int((item.rate ?? 0) * Double(item.quantity ?? 1))

        switch item.assignmentStatus {

        case "pending":
            checkbox.isSelected = false
            checkbox.isUserInteractionEnabled = false
            budgetLabel.text = "Request sent to vendor"

        case "accepted":
            checkbox.isSelected = true
            checkbox.isUserInteractionEnabled = false   // 🔴 key fix
            budgetLabel.text = "Assigned to: \(item.assignedVendorName ?? "Vendor")"

        case "rejected":
            checkbox.isSelected = false
            checkbox.isUserInteractionEnabled = true
            budgetLabel.text = "Rejected by vendor"

        default:
            checkbox.isSelected = isSelected
            checkbox.isUserInteractionEnabled = true
            budgetLabel.text = "Client Budget: ₹\(total)"
        }

        updateCheckboxUI()
    }

}

// MARK: - Color
extension UIColor {
    static let utsavPurple = UIColor(
        red: 136/255,
        green: 71/255,
        blue: 246/255,
        alpha: 1
    )
}

