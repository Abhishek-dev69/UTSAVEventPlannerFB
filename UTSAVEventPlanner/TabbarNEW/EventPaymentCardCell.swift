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

    // middle: total & due
    private let totalLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.preferredFont(forTextStyle: .subheadline)
        l.textColor = .label
        return l
    }()

    private let remainingLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.preferredFont(forTextStyle: .subheadline)
        l.textColor = .label
        l.textAlignment = .right
        return l
    }()

    // MARK: - Progress View (FIXED COLOR)
    private let progressView: UIProgressView = {
        let p = UIProgressView(progressViewStyle: .bar)
        p.translatesAutoresizingMaskIntoConstraints = false
        p.layer.cornerRadius = 3
        p.clipsToBounds = true

        // ✅ UTSAV PURPLE
        p.progressTintColor = UIColor(
            red: 139/255,
            green: 59/255,
            blue: 240/255,
            alpha: 1
        )

        // subtle track
        p.trackTintColor = UIColor(
            red: 139/255,
            green: 59/255,
            blue: 240/255,
            alpha: 0.15
        )

        return p
    }()

    // inside stacks
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

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none

        // build stacks
        topRow.axis = .horizontal
        topRow.alignment = .top
        topRow.distribution = .fill
        topRow.spacing = 8
        topRow.translatesAutoresizingMaskIntoConstraints = false

        totalsRow.axis = .horizontal
        totalsRow.alignment = .center
        totalsRow.distribution = .fill
        totalsRow.spacing = 8
        totalsRow.translatesAutoresizingMaskIntoConstraints = false

        mainStack.axis = .vertical
        mainStack.alignment = .fill
        mainStack.distribution = .fill
        mainStack.spacing = 10
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(cardView)
        cardView.addSubview(mainStack)

        // topRow
        topRow.addArrangedSubview(titleLabel)
        topRow.addArrangedSubview(chevronView)
        chevronView.setContentHuggingPriority(.required, for: .horizontal)
        chevronView.setContentCompressionResistancePriority(.required, for: .horizontal)
        chevronView.widthAnchor.constraint(equalToConstant: 18).isActive = true
        chevronView.heightAnchor.constraint(equalToConstant: 20).isActive = true

        // totals row
        let spacer = UIView()
        totalsRow.addArrangedSubview(totalLabel)
        totalsRow.addArrangedSubview(spacer)
        totalsRow.addArrangedSubview(remainingLabel)

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

        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        titleLabel.adjustsFontForContentSizeCategory = true
        totalLabel.adjustsFontForContentSizeCategory = true
        remainingLabel.adjustsFontForContentSizeCategory = true
    }

    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        totalLabel.text = nil
        remainingLabel.text = nil
        progressView.setProgress(0, animated: false)
    }

    // MARK: - Configure
    func configure(with event: EventRecord, total: Double? = nil, remaining: Double? = nil) {

        let rawName = event.eventName.trimmingCharacters(in: .whitespacesAndNewlines)
        titleLabel.text = rawName.isEmpty ? "Untitled Event" : rawName

        totalLabel.text = "Total: ₹\(formatMoney(total ?? 0))"
        remainingLabel.text = "Due: ₹\(formatMoney(remaining ?? 0))"

        if let t = total, let r = remaining, t > 0 {
            let received = max(0, t - r)
            let progress = Float(min(1, received / t))
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

