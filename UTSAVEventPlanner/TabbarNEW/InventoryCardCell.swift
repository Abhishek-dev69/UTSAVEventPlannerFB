import UIKit

final class InventoryCardCell: UITableViewCell {

    private let cardView = UIView()
    private let titleLabel = UILabel()

    private let allocatedLabel = UILabel()
    private let receivedLabel = UILabel()
    private let lostLabel = UILabel()

    private let vStack = UIStackView()
    private let bottomRow = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = .clear
        selectionStyle = .none

        // Card
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 14
        cardView.layer.shadowOpacity = 0.06
        cardView.layer.shadowRadius = 8
        cardView.translatesAutoresizingMaskIntoConstraints = false

        // Title
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 1

        // Labels
        [allocatedLabel, receivedLabel, lostLabel].forEach {
            $0.font = .preferredFont(forTextStyle: .subheadline)
            $0.numberOfLines = 1
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }

        // Bottom row: Received | Lost
        bottomRow.axis = .horizontal
        bottomRow.distribution = .equalSpacing
        bottomRow.alignment = .center

        bottomRow.addArrangedSubview(receivedLabel)
        bottomRow.addArrangedSubview(lostLabel)

        // Main stack
        vStack.axis = .vertical
        vStack.spacing = 8
        vStack.translatesAutoresizingMaskIntoConstraints = false

        vStack.addArrangedSubview(titleLabel)
        vStack.addArrangedSubview(allocatedLabel)
        vStack.addArrangedSubview(bottomRow)

        contentView.addSubview(cardView)
        cardView.addSubview(vStack)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            vStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            vStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            vStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            vStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14)
        ])
    }

    func configure(event: EventRecord, allocated: Int, received: Int, lost: Int) {
        titleLabel.text = event.eventName ?? "Untitled Event"
        allocatedLabel.text = "Allocated: \(allocated)"
        receivedLabel.text = "Received: \(received)"
        lostLabel.text = "Lost/Damaged: \(lost)"
    }
}


