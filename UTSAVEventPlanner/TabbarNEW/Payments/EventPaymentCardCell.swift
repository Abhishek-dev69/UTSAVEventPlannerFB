import UIKit

final class EventPaymentCardCell: UITableViewCell {

    // MARK: - Views

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

    // top: title + chevron
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.font = UIFont.preferredFont(forTextStyle: .headline)
        l.textColor = .label
        return l
    }()

    private let chevronView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .tertiaryLabel
        return iv
    }()

    // MARK: - Total Section
    private let totalTitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        l.textColor = .secondaryLabel
        l.text = "Total"
        return l
    }()

    private let totalAmountLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        l.textColor = .label
        return l
    }()

    // MARK: - Due Section
    private let dueTitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        l.textColor = .secondaryLabel
        l.text = "Due"
        l.textAlignment = .right
        return l
    }()

    private let dueAmountLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        l.textColor = .systemRed // ✅ Due amount in red
        l.textAlignment = .right
        return l
    }()

    // MARK: - Progress View
    private let progressView: UIProgressView = {
        let p = UIProgressView(progressViewStyle: .bar)
        p.translatesAutoresizingMaskIntoConstraints = false
        p.layer.cornerRadius = 3
        p.clipsToBounds = true

        p.progressTintColor = UIColor(
            red: 139/255,
            green: 59/255,
            blue: 240/255,
            alpha: 1
        )

        p.trackTintColor = UIColor(
            red: 139/255,
            green: 59/255,
            blue: 240/255,
            alpha: 0.15
        )
        return p
    }()

    // stacks
    private let topRow = UIStackView()
    private let totalsRow = UIStackView()
    private let mainStack = UIStackView()

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    // MARK: - Setup UI
    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none

        topRow.axis = .horizontal
        topRow.alignment = .top
        topRow.spacing = 8
        topRow.translatesAutoresizingMaskIntoConstraints = false

        totalsRow.axis = .horizontal
        totalsRow.alignment = .center
        totalsRow.spacing = 8
        totalsRow.translatesAutoresizingMaskIntoConstraints = false

        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(cardView)
        cardView.addSubview(mainStack)

        // top row
        topRow.addArrangedSubview(titleLabel)
        topRow.addArrangedSubview(chevronView)

        chevronView.setContentHuggingPriority(.required, for: .horizontal)
        chevronView.widthAnchor.constraint(equalToConstant: 18).isActive = true
        chevronView.heightAnchor.constraint(equalToConstant: 20).isActive = true

        // totals row (native iOS style)
        let totalStack = UIStackView(arrangedSubviews: [totalTitleLabel, totalAmountLabel])
        totalStack.axis = .vertical
        totalStack.spacing = 2

        let dueStack = UIStackView(arrangedSubviews: [dueTitleLabel, dueAmountLabel])
        dueStack.axis = .vertical
        dueStack.spacing = 2
        dueStack.alignment = .trailing

        totalsRow.addArrangedSubview(totalStack)
        totalsRow.addArrangedSubview(UIView())
        totalsRow.addArrangedSubview(dueStack)

        // main stack
        mainStack.addArrangedSubview(topRow)
        mainStack.addArrangedSubview(totalsRow)
        mainStack.addArrangedSubview(progressView)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            mainStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            mainStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),

            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronView.leadingAnchor, constant: -8)
        ])
    }

    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        totalAmountLabel.text = nil
        dueAmountLabel.text = nil
        progressView.setProgress(0, animated: false)
    }

    // MARK: - Configure
    func configure(with event: EventRecord, total: Double? = nil, remaining: Double? = nil) {

        let rawName = event.eventName.trimmingCharacters(in: .whitespacesAndNewlines)
        titleLabel.text = rawName.isEmpty ? "Untitled Event" : rawName

        let totalValue = total ?? 0
        let dueValue = remaining ?? 0

        totalAmountLabel.text = "₹\(formatMoney(totalValue))"
        dueAmountLabel.text = "₹\(formatMoney(dueValue))"
        dueAmountLabel.textColor = (dueValue == 0) ? .systemGreen : .systemRed

        if totalValue > 0 {
            let received = max(0, totalValue - dueValue)
            let progress = Float(min(1, received / totalValue))
            progressView.setProgress(progress, animated: true)
        } else {
            progressView.setProgress(0, animated: false)
        }
    }

    // MARK: - Helper
    private func formatMoney(_ v: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: v)) ?? "0"
    }
}

