import UIKit

final class ServiceCardHeaderCell: UIView {

    static let reuseID = "ServiceCardHeaderCell"

    var onToggle: (() -> Void)?

    private let container = UIView()
    private let titleLabel = UILabel()
    private let arrow = UIImageView(image: UIImage(systemName: "chevron.down"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .clear

        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.06
        container.layer.shadowRadius = 5
        container.layer.shadowOffset = CGSize(width: 0, height: 3)
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        arrow.tintColor = .gray
        arrow.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(arrow)

        let tap = UITapGestureRecognizer(target: self, action: #selector(toggle))
        container.addGestureRecognizer(tap)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            container.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),

            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            arrow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            arrow.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
    }

    @objc private func toggle() {
        onToggle?()
    }

    func configure(with title: String, expanded: Bool) {
        titleLabel.text = title
        arrow.transform = expanded ? CGAffineTransform(rotationAngle: .pi/2) : .identity
    }
}

