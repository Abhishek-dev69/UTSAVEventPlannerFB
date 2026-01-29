import UIKit

final class InventoryCardCell: UITableViewCell {

    private let cardView = UIView()
    private let titleLabel = UILabel()

    // MARK: - Labels
    private let allocatedTitleLabel = UILabel()
    private let receivedTitleLabel = UILabel()
    private let pendingTitleLabel = UILabel()
    private let lostTitleLabel = UILabel()

    private let allocatedValueLabel = UILabel()
    private let receivedValueLabel = UILabel()
    private let pendingValueLabel = UILabel()
    private let lostValueLabel = UILabel()

    // MARK: - Stacks
    private let mainStack = UIStackView()
    private let row1Stack = UIStackView()
    private let row2Stack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        // Card style
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 14
        cardView.layer.shadowOpacity = 0.06
        cardView.layer.shadowRadius = 8
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardView.translatesAutoresizingMaskIntoConstraints = false

        // Title
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label

        // Title labels style
        [allocatedTitleLabel, receivedTitleLabel, pendingTitleLabel, lostTitleLabel].forEach {
            $0.font = .systemFont(ofSize: 13, weight: .medium)
            $0.textColor = .secondaryLabel
        }

        allocatedTitleLabel.text = "Allocated"
        receivedTitleLabel.text = "Received"
        pendingTitleLabel.text = "Pending"
        lostTitleLabel.text = "Lost/Damaged"

        // Value labels style
        [allocatedValueLabel, receivedValueLabel, pendingValueLabel, lostValueLabel].forEach {
            $0.font = .systemFont(ofSize: 18, weight: .semibold)
            $0.textColor = .label
        }

        // Column stacks
        let allocatedStack = makeColumn(title: allocatedTitleLabel, value: allocatedValueLabel, alignment: .leading)
        let receivedStack = makeColumn(title: receivedTitleLabel, value: receivedValueLabel, alignment: .trailing)

        let pendingStack = makeColumn(title: pendingTitleLabel, value: pendingValueLabel, alignment: .leading)
        let lostStack = makeColumn(title: lostTitleLabel, value: lostValueLabel, alignment: .trailing)

        // Row stacks
        row1Stack.axis = .horizontal
        row1Stack.distribution = .fillEqually
        row1Stack.spacing = 20
        row1Stack.addArrangedSubview(allocatedStack)
        row1Stack.addArrangedSubview(receivedStack)

        row2Stack.axis = .horizontal
        row2Stack.distribution = .fillEqually
        row2Stack.spacing = 20
        row2Stack.addArrangedSubview(pendingStack)
        row2Stack.addArrangedSubview(lostStack)

        // Main stack
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        mainStack.addArrangedSubview(titleLabel)
        mainStack.addArrangedSubview(row1Stack)
        mainStack.addArrangedSubview(row2Stack)

        contentView.addSubview(cardView)
        cardView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            mainStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            mainStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),
            mainStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            mainStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
        ])
    }

    private func makeColumn(title: UILabel, value: UILabel, alignment: UIStackView.Alignment) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [title, value])
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = alignment
        return stack
    }

    // ✅ Updated configure method
    func configure(event: EventRecord, allocated: Int, received: Int, notReceived: Int, lost: Int) {
        titleLabel.text = event.eventName
        allocatedValueLabel.text = "\(allocated)"
        receivedValueLabel.text = "\(received)"
        pendingValueLabel.text = "\(notReceived)"   // Pending = Not Received
        lostValueLabel.text = "\(lost)"
    }
}

