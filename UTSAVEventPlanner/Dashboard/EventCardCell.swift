import UIKit

final class EventCardCell: UITableViewCell {

    private let statusDot = UIView()
    private let statusLabel = UILabel()
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private let locationLabel = UILabel()
    private let thumb = UIImageView()
    private let container = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        backgroundColor = .clear
        selectionStyle = .none

        // Container card style
        container.backgroundColor = .white
        container.layer.cornerRadius = 18
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.08
        container.layer.shadowOffset = CGSize(width: 0, height: 3)
        container.layer.shadowRadius = 5
        container.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])

        // Thumbnail
        thumb.layer.cornerRadius = 12
        thumb.clipsToBounds = true
        thumb.backgroundColor = UIColor(white: 0.93, alpha: 1)
        thumb.translatesAutoresizingMaskIntoConstraints = false

        // Status
        statusDot.layer.cornerRadius = 5
        statusLabel.font = .systemFont(ofSize: 13, weight: .medium)
        statusLabel.textColor = .darkGray

        let statusStack = UIStackView(arrangedSubviews: [statusDot, statusLabel])
        statusStack.axis = .horizontal
        statusStack.spacing = 6
        statusStack.alignment = .center
        statusStack.translatesAutoresizingMaskIntoConstraints = false

        let statusContainer = UIView()
        statusContainer.translatesAutoresizingMaskIntoConstraints = false
        statusContainer.addSubview(statusStack)

        NSLayoutConstraint.activate([
            statusStack.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor),
            statusStack.topAnchor.constraint(equalTo: statusContainer.topAnchor),
            statusStack.bottomAnchor.constraint(equalTo: statusContainer.bottomAnchor)
        ])

        // Labels
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.numberOfLines = 2

        dateLabel.font = .systemFont(ofSize: 14)
        dateLabel.textColor = .secondaryLabel

        locationLabel.font = .systemFont(ofSize: 13)
        locationLabel.textColor = .tertiaryLabel

        let mainStack = UIStackView(arrangedSubviews: [
            statusContainer,
            titleLabel,
            dateLabel,
            locationLabel
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 6
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(mainStack)
        container.addSubview(thumb)

        NSLayoutConstraint.activate([
            thumb.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            thumb.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            thumb.widthAnchor.constraint(equalToConstant: 86),
            thumb.heightAnchor.constraint(equalToConstant: 60),

            mainStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            mainStack.trailingAnchor.constraint(equalTo: thumb.leadingAnchor, constant: -14),
            mainStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            mainStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14)
        ])
    }

    // MARK: - Configure
    func configure(with record: EventRecord) {

        titleLabel.text = record.eventName
        dateLabel.text = formatDate(record.startDate)
        locationLabel.text = record.location

        // Status
        statusLabel.text = "Upcoming"
        statusDot.backgroundColor = UIColor.systemBlue

        // 🔥 Load event type image from metadata
        // Load event type image
        if let metadata = record.metadata,
           let imgName = metadata["eventTypeImage"],
           let img = UIImage(named: imgName) {
            thumb.image = img
        } else {
            thumb.image = UIImage(named: "placeholder")
        }
    }

    // MARK: - Date Formatter
    private func formatDate(_ input: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"

        if let date = inputFormatter.date(from: input) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "dd-MM-yyyy"
            return outputFormatter.string(from: date)
        }

        return input
    }
}

