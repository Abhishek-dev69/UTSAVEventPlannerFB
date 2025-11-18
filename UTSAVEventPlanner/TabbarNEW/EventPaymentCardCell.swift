import UIKit

final class EventPaymentCardCell: UITableViewCell {

    private let container = UIView()
    private let titleLabel = UILabel()
    private let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {

        backgroundColor = .clear
        selectionStyle = .none

        // Card container
        container.backgroundColor = .white
        container.layer.cornerRadius = 14
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.08
        container.layer.shadowRadius = 5
        container.layer.shadowOffset = CGSize(width: 0, height: 3)
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        // Event Title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Arrow
        arrow.tintColor = .lightGray
        arrow.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(arrow)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            arrow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            arrow.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
    }

    func configure(with event: EventRecord) {
        titleLabel.text = event.eventName
    }
}

