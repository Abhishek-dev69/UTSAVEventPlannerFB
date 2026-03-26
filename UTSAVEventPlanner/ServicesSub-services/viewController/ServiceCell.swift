import UIKit

final class ServiceCell: UITableViewCell {
    static let reuseID = "ServiceCell"

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1.0, alpha: 0.85)
        v.layer.cornerRadius = 18
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset = CGSize(width: 0, height: 3)
        v.layer.shadowRadius = 5
        v.translatesAutoresizingMaskIntoConstraints = false
        // Prevent content from leaking outside corner radius
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

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let chevron: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.tintColor = .tertiaryLabel
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
        
        // Use a stack for title & subtitle
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        
        cardView.addSubview(textStack)
        cardView.addSubview(chevron)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            // Text Stack
            textStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            textStack.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -8),
            
            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),

            // Chevron
            chevron.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: cardView.centerYAnchor)
        ])
    }

    func configure(with service: Service) {
        titleLabel.text = service.name
        
        let count = service.subservices.count
        if count == 0 {
            subtitleLabel.text = "No sub-services set"
        } else if count == 1 {
            subtitleLabel.text = "1 sub-service"
        } else {
            subtitleLabel.text = "\(count) sub-services"
        }
    }
}

