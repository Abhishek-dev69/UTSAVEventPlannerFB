import UIKit

final class InhouseRequirementCell: UITableViewCell {

    private let titleLabel = UILabel()
    private let qtyLabel = UILabel()
    private let container = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        backgroundColor = .clear
        selectionStyle = .none

        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.layer.shadowOpacity = 0.1
        container.layer.shadowRadius = 4
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])

        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        qtyLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        qtyLabel.textColor = .gray

        let stack = UIStackView(arrangedSubviews: [titleLabel, qtyLabel])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
    }

    func configure(item: CartItemRecord) {

        // Always show sub-service name for in-house items
        if let sub = item.subserviceName, !sub.isEmpty {
            titleLabel.text = sub
        } else if let srv = item.serviceName, !srv.isEmpty {
            titleLabel.text = srv   // fallback
        } else {
            titleLabel.text = "Service"
        }

        qtyLabel.text = "\(item.quantity ?? 0)"
    }
}

