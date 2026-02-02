import UIKit

final class VendorPaymentCardCell: UITableViewCell {

    // MARK: - UI

    private let cardView = UIView()
    private let nameLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))

    // Titles
    private let totalTitle = UILabel()
    private let paidTitle = UILabel()
    private let dueTitle = UILabel()

    // Values
    private let totalValue = UILabel()
    private let paidValue = UILabel()
    private let dueValue = UILabel()

    private let progressView = UIProgressView(progressViewStyle: .bar)

    private let utsavPurple = UIColor(
        red: 139/255,
        green: 59/255,
        blue: 240/255,
        alpha: 1
    )

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
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // Card
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 14
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.06
        cardView.layer.shadowRadius = 8
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)

        // Vendor name
        nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)

        // Titles
        [totalTitle, paidTitle, dueTitle].forEach {
            $0.font = .systemFont(ofSize: 13)
            $0.textColor = .secondaryLabel
            $0.textAlignment = .left
        }

        totalTitle.text = "Total Payable"
        paidTitle.text = "Paid"
        dueTitle.text = "Due"

        // Values
        totalValue.font = .systemFont(ofSize: 16, weight: .semibold)
        paidValue.font = .systemFont(ofSize: 15)
        dueValue.font = .systemFont(ofSize: 16, weight: .semibold)
        dueValue.textColor = .systemRed

        // Progress
        progressView.progressTintColor = utsavPurple
        progressView.trackTintColor = utsavPurple.withAlphaComponent(0.15)
        progressView.layer.cornerRadius = 3
        progressView.clipsToBounds = true

        chevron.tintColor = .tertiaryLabel

        let views = [
            cardView, nameLabel, chevron,
            totalTitle, paidTitle, dueTitle,
            totalValue, paidValue, dueValue,
            progressView
        ]

        views.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        contentView.addSubview(cardView)
        views.dropFirst().forEach { cardView.addSubview($0) }

        NSLayoutConstraint.activate([
            // Card
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            // Name
            nameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),

            chevron.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            // Titles row
            totalTitle.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 14),
            totalTitle.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            paidTitle.topAnchor.constraint(equalTo: totalTitle.topAnchor),
            paidTitle.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),

            dueTitle.topAnchor.constraint(equalTo: totalTitle.topAnchor),
            dueTitle.trailingAnchor.constraint(equalTo: chevron.trailingAnchor),

            // Values row
            totalValue.topAnchor.constraint(equalTo: totalTitle.bottomAnchor, constant: 2),
            totalValue.leadingAnchor.constraint(equalTo: totalTitle.leadingAnchor),

            paidValue.topAnchor.constraint(equalTo: paidTitle.bottomAnchor, constant: 2),
            paidValue.centerXAnchor.constraint(equalTo: paidTitle.centerXAnchor),

            dueValue.topAnchor.constraint(equalTo: dueTitle.bottomAnchor, constant: 2),
            dueValue.trailingAnchor.constraint(equalTo: dueTitle.trailingAnchor),

            // Progress
            progressView.topAnchor.constraint(equalTo: totalValue.bottomAnchor, constant: 14),
            progressView.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: chevron.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 6),
            progressView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14)
        ])
    }

    // MARK: - Configure

    func configure(vendorName: String, total: Double, paid: Double) {
        let due = max(0, total - paid)

        nameLabel.text = vendorName
        totalValue.text = "₹\(fmt(total))"
        paidValue.text = "₹\(fmt(paid))"
        dueValue.text = "₹\(fmt(due))"

        let progress = total > 0 ? Float(paid / total) : 0
        progressView.setProgress(min(progress, 1), animated: false)
    }

    // MARK: - Helpers

    private func fmt(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: v)) ?? "0"
    }
}

