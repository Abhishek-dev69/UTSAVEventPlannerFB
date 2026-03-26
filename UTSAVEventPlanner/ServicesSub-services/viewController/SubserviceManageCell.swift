import UIKit

final class SubserviceManageCell: UITableViewCell {
    static let reuseID = "SubserviceManageCell"

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1.0, alpha: 0.85)
        v.layer.cornerRadius = 18
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset = CGSize(width: 0, height: 3)
        v.layer.shadowRadius = 5
        v.translatesAutoresizingMaskIntoConstraints = false
        v.clipsToBounds = false 
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let rateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let editButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        b.setImage(UIImage(systemName: "pencil"), for: .normal)
        b.tintColor = UIColor(red: 138.0/255.0, green: 73.0/255.0, blue: 246.0/255.0, alpha: 1.0)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    var onEditTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    private func setup() {
        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(rateLabel)
        cardView.addSubview(editButton)

        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: editButton.leadingAnchor, constant: -8),

            rateLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            rateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            rateLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            rateLabel.trailingAnchor.constraint(equalTo: editButton.leadingAnchor, constant: -8),

            editButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            editButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            editButton.widthAnchor.constraint(equalToConstant: 32),
            editButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    @objc private func editTapped() {
        onEditTapped?()
    }

    func configure(with sub: Subservice) {
        titleLabel.text = sub.name
        rateLabel.text = "₹\(Int(sub.rate)) per unit"
    }
}
