import UIKit

final class OutsourceRequirementCell: UITableViewCell {

    var onSelectionChanged: ((Bool) -> Void)?

    private let container = UIView()
    private let checkbox = UIButton(type: .custom)

    private let titleLabel = UILabel()
    private let descLabel = UILabel()
    private let vendorLabel = UILabel()   // ✅ NEW
    private let budgetLabel = UILabel()   // ✅ NEW

    private let infoStack = UIStackView() // ✅ NEW

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
        vendorLabel.text = nil
        updateCheckboxUI()
    }

    private func setupUI() {

        contentView.backgroundColor = .systemGroupedBackground

        // Card
        container.backgroundColor = .white
        container.layer.cornerRadius = 14
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        // Checkbox
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.layer.cornerRadius = 13
        checkbox.layer.borderWidth = 2
        checkbox.layer.borderColor = UIColor.utsavPurple.cgColor
        checkbox.contentEdgeInsets = .zero
        checkbox.imageEdgeInsets = .zero
        checkbox.adjustsImageWhenHighlighted = false

        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        checkbox.setImage(UIImage(systemName: "checkmark", withConfiguration: config), for: .selected)
        checkbox.tintColor = .white

        checkbox.addTarget(self, action: #selector(toggle), for: .touchUpInside)
        container.addSubview(checkbox)

        // Labels Style
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .black

        descLabel.font = .systemFont(ofSize: 13)
        descLabel.textColor = .systemGray

        vendorLabel.font = .systemFont(ofSize: 14, weight: .medium)
        vendorLabel.textColor = .utsavPurple   // ✅ Purple instead of green

        budgetLabel.font = .systemFont(ofSize: 14, weight: .medium)
        budgetLabel.textColor = .utsavPurple   // ✅ Purple instead of green

        // StackView for vendor + budget (perfect spacing)
        infoStack.axis = .vertical
        infoStack.spacing = 4   // ✅ clean spacing
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        infoStack.addArrangedSubview(vendorLabel)
        infoStack.addArrangedSubview(budgetLabel)

        [titleLabel, descLabel, infoStack].forEach {
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
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: checkbox.leadingAnchor, constant: -12),

            // Description
            descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            descLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            // Stack (Vendor + Budget)
            infoStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            infoStack.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 10),
            infoStack.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            infoStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14)
        ])
    }

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

    func configure(item: CartItemRecord, isSelected: Bool) {

        titleLabel.text = item.serviceName
        descLabel.text = "Client Requirement: \(item.subserviceName ?? "")"

        let total = Int((item.rate ?? 0) * Double(item.quantity ?? 1))
        budgetLabel.text = "Client Budget: ₹\(total)"

        switch item.assignmentStatus {

        case "pending":
            checkbox.isSelected = false
            checkbox.isUserInteractionEnabled = false
            vendorLabel.text = "Request sent to vendor"

        case "accepted":
            checkbox.isSelected = true
            checkbox.isUserInteractionEnabled = false
            vendorLabel.text = "Assigned to: \(item.assignedVendorName ?? "Vendor")"

        case "rejected":
            checkbox.isSelected = false
            checkbox.isUserInteractionEnabled = true
            vendorLabel.text = "Rejected by vendor"

        default:
            checkbox.isSelected = isSelected
            checkbox.isUserInteractionEnabled = true
            vendorLabel.text = nil
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

