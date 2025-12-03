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

    // middle: total & remaining
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

    // progress
    private let progressView: UIProgressView = {
        let p = UIProgressView(progressViewStyle: .bar)
        p.translatesAutoresizingMaskIntoConstraints = false
        p.layer.cornerRadius = 3
        p.clipsToBounds = true
        if #available(iOS 13.0, *) {
            p.trackTintColor = UIColor.systemGray5
            p.progressTintColor = UIColor.systemBlue
        }
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

        // totals row
        totalsRow.axis = .horizontal
        totalsRow.alignment = .center
        totalsRow.distribution = .fill
        totalsRow.spacing = 8
        totalsRow.translatesAutoresizingMaskIntoConstraints = false

        // main vertical stack
        mainStack.axis = .vertical
        mainStack.alignment = .fill
        mainStack.distribution = .fill
        mainStack.spacing = 10
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(cardView)
        cardView.addSubview(mainStack)

        // topRow content: title + chevron
        topRow.addArrangedSubview(titleLabel)
        topRow.addArrangedSubview(chevronView)
        // keep chevron small
        chevronView.setContentHuggingPriority(.required, for: .horizontal)
        chevronView.setContentCompressionResistancePriority(.required, for: .horizontal)
        chevronView.widthAnchor.constraint(equalToConstant: 18).isActive = true
        chevronView.heightAnchor.constraint(equalToConstant: 20).isActive = true

        // totals row content: total, spacer, remaining
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        totalsRow.addArrangedSubview(totalLabel)
        totalsRow.addArrangedSubview(spacer)
        totalsRow.addArrangedSubview(remainingLabel)

        // build mainStack: topRow, totalsRow, progressView
        mainStack.addArrangedSubview(topRow)
        mainStack.addArrangedSubview(totalsRow)
        mainStack.addArrangedSubview(progressView)

        // Auto Layout
        NSLayoutConstraint.activate([
            // card inside cell
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            // mainStack inside card with padding
            mainStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            mainStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),

            // ensure title has room and chevron doesn't overlap
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronView.leadingAnchor, constant: -8)
        ])

        // small priority tweaks to ensure title expands vertically instead of being compressed
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        // Dynamic type support
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
        // If EventRecord.eventName is optional in your model, unwrap safely.
        let rawName: String
        if let n = (event.eventName as String?) {
            rawName = n.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            rawName = ""
        }
        titleLabel.text = rawName.isEmpty ? "Untitled Event" : rawName

        if let t = total {
            totalLabel.text = "Total: ₹\(formatMoney(t))"
        } else {
            totalLabel.text = "Total: ₹0"
        }

        if let r = remaining {
            remainingLabel.text = "Remaining: ₹\(formatMoney(r))"
        } else {
            remainingLabel.text = "Remaining: ₹0"
        }

        if let t = total, t > 0, let r = remaining {
            let received = max(0.0, t - r)
            let prog = Float(min(1.0, received / t))
            progressView.setProgress(prog, animated: true)
        } else {
            progressView.setProgress(0.0, animated: false)
        }
    }

    // MARK: - Helpers
    private func formatMoney(_ v: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: v)) ?? String(format: "%.2f", v)
    }
}

