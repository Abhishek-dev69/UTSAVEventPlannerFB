import UIKit

final class ServiceCell: UITableViewCell {
    static let reuseID = "ServiceCell"

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset = CGSize(width: 0, height: 6)
        v.layer.shadowRadius = 8
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .regular)
        l.textColor = UIColor(white: 0.1, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let chevron = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.tintColor = .systemGray3
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

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
        cardView.addSubview(chevron)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),

            chevron.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: cardView.centerYAnchor)
        ])
    }

    func configure(with service: Service) {
        titleLabel.text = service.name
    }
}

