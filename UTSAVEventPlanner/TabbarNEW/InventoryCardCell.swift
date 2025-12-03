import UIKit

final class InventoryCardCell: UITableViewCell {

    // MARK: - UI
    private let cardView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 14
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowRadius = 8
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.font = UIFont.preferredFont(forTextStyle: .headline)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let chevronView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .tertiaryLabel
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    // NEW: Sent / Received labels
    private let sentLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.preferredFont(forTextStyle: .subheadline)
        l.textColor = .label
        return l
    }()

    private let receivedLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.preferredFont(forTextStyle: .subheadline)
        l.textColor = .label
        l.textAlignment = .right
        return l
    }()

    // layout stacks
    private let topRow = UIStackView()
    private let middleRow = UIStackView()
    private let vstack = UIStackView()

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup
    private func setup() {
        backgroundColor = .clear
        selectionStyle = .none

        // stack configs
        topRow.axis = .horizontal
        topRow.alignment = .top
        topRow.distribution = .fill
        topRow.spacing = 8

        middleRow.axis = .horizontal
        middleRow.alignment = .center
        middleRow.distribution = .fill
        middleRow.spacing = 8

        vstack.axis = .vertical
        vstack.alignment = .fill
        vstack.distribution = .fill
        vstack.spacing = 8
        vstack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(cardView)
        cardView.addSubview(vstack)

        topRow.addArrangedSubview(titleLabel)
        topRow.addArrangedSubview(chevronView)
        chevronView.setContentHuggingPriority(.required, for: .horizontal)
        chevronView.widthAnchor.constraint(equalToConstant: 18).isActive = true
        chevronView.heightAnchor.constraint(equalToConstant: 20).isActive = true

        // middleRow: Sent (left) | spacer | Received (right)
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        middleRow.addArrangedSubview(sentLabel)
        middleRow.addArrangedSubview(spacer)
        middleRow.addArrangedSubview(receivedLabel)

        vstack.addArrangedSubview(topRow)
        vstack.addArrangedSubview(middleRow)

        // constraints
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            vstack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            vstack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            vstack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            vstack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),

            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronView.leadingAnchor, constant: -8)
        ])

        // dynamic type
        titleLabel.adjustsFontForContentSizeCategory = true
        sentLabel.adjustsFontForContentSizeCategory = true
        receivedLabel.adjustsFontForContentSizeCategory = true
    }

    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        sentLabel.text = nil
        receivedLabel.text = nil
    }

    // MARK: - Configure
    /// - Parameters:
    ///   - event: EventRecord
    ///   - sentQuantity: total quantity sent (planner) — show placeholder if nil
    ///   - receivedQuantity: total quantity received (vendor) — show placeholder if nil
    func configure(with event: EventRecord, sentQuantity: Int? = nil, receivedQuantity: Int? = nil) {
        let name: String
        if let n = (event.eventName as String?) {
            name = n.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            name = ""
        }
        titleLabel.text = name.isEmpty ? "Untitled Event" : name

        if let s = sentQuantity {
            sentLabel.text = "Sent: \(s)"
        } else {
            sentLabel.text = "Sent: —"
        }

        if let r = receivedQuantity {
            receivedLabel.text = "Received: \(r)"
        } else {
            receivedLabel.text = "Received: —"
        }
    }
}

