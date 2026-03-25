import UIKit

final class InhouseRequirementCell: UITableViewCell {

    private let titleLabel = UILabel()
    private let qtyLabel = UILabel()
    private let statusLabel = UILabel()
    private let container = UIView()

    // ✅ Checkbox button
    private let checkboxButton = UIButton(type: .system)

    // ✅ Callback to VC
    var onCheckboxToggle: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {

        backgroundColor = .clear
        selectionStyle = .none

        container.backgroundColor = .white.withAlphaComponent(0.85)
        container.layer.cornerRadius = 16
        container.layer.shadowOpacity = 0.08
        container.layer.shadowRadius = 4
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])

        // Checkbox
        checkboxButton.setImage(UIImage(systemName: "square"), for: .normal)
        checkboxButton.tintColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        checkboxButton.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)
        checkboxButton.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        qtyLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        qtyLabel.textColor = .gray

        statusLabel.font = .systemFont(ofSize: 13, weight: .medium)
        statusLabel.numberOfLines = 1

        let topRow = UIStackView(arrangedSubviews: [
            checkboxButton,
            titleLabel,
            UIView(),
            qtyLabel
        ])
        topRow.axis = .horizontal
        topRow.spacing = 8
        topRow.alignment = .center

        let stack = UIStackView(arrangedSubviews: [topRow, statusLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
    }

    @objc private func checkboxTapped() {
        onCheckboxToggle?()
    }

    func configure(item: CartItemRecord, isSelected: Bool, isSelectable: Bool) {

        // Title
        if let sub = item.subserviceName, !sub.isEmpty {
            titleLabel.text = sub
        } else if let srv = item.serviceName, !srv.isEmpty {
            titleLabel.text = srv
        } else {
            titleLabel.text = "Service"
        }

        qtyLabel.text = "Qty: \(item.quantity ?? 0)"

        // Checkbox state
        if isSelected {
            checkboxButton.setImage(UIImage(systemName: "checkmark.square.fill"), for: .normal)
        } else {
            checkboxButton.setImage(UIImage(systemName: "square"), for: .normal)
        }

        checkboxButton.isHidden = !isSelectable

        // Status label
        if let status = item.assignmentStatus,
           let vendor = item.assignedVendorName,
           !vendor.isEmpty {

            switch status {
            case "accepted":
                statusLabel.text = "Assigned to: \(vendor)"
                statusLabel.textColor = .systemGreen

            case "pending":
                statusLabel.text = "Request sent to: \(vendor)"
                statusLabel.textColor = .systemOrange

            case "rejected":
                statusLabel.text = "Rejected by: \(vendor)"
                statusLabel.textColor = .systemRed

            default:
                statusLabel.text = nil
            }

        } else {
            statusLabel.text = nil
        }
    }
}

