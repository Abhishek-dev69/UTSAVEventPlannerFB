//
//  VendorPaymentCardCell.swift
//  UTSAV
//
//  Created by Abhishek on 18/01/26.
//

import UIKit

final class VendorPaymentCardCell: UITableViewCell {

    // MARK: - UI

    private let cardView = UIView()
    private let nameLabel = UILabel()
    private let totalLabel = UILabel()
    private let paidLabel = UILabel()
    private let remainingLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .bar)
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))

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
        // 🔑 VERY IMPORTANT FOR SHADOW + AUTO HEIGHT
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        clipsToBounds = false
        contentView.clipsToBounds = false

        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 14
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.06
        cardView.layer.shadowRadius = 8
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardView.clipsToBounds = false

        nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        nameLabel.numberOfLines = 1

        totalLabel.font = .systemFont(ofSize: 14)
        paidLabel.font = .systemFont(ofSize: 14)
        remainingLabel.font = .systemFont(ofSize: 14)
        remainingLabel.textColor = .secondaryLabel

        progressView.progressTintColor = utsavPurple
        progressView.trackTintColor = utsavPurple.withAlphaComponent(0.15)
        progressView.layer.cornerRadius = 3
        progressView.clipsToBounds = true

        chevron.tintColor = .tertiaryLabel

        [cardView, nameLabel, totalLabel, paidLabel, remainingLabel, progressView, chevron].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        contentView.addSubview(cardView)
        cardView.addSubview(nameLabel)
        cardView.addSubview(chevron)
        cardView.addSubview(totalLabel)
        cardView.addSubview(paidLabel)
        cardView.addSubview(remainingLabel)
        cardView.addSubview(progressView)

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

            // Amounts
            totalLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            totalLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            paidLabel.topAnchor.constraint(equalTo: totalLabel.bottomAnchor, constant: 4),
            paidLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            remainingLabel.topAnchor.constraint(equalTo: paidLabel.bottomAnchor, constant: 4),
            remainingLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            // Progress
            progressView.topAnchor.constraint(equalTo: remainingLabel.bottomAnchor, constant: 10),
            progressView.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: chevron.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 6),
            progressView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14)
        ])
    }

    // MARK: - Configure

    func configure(
        vendorName: String,
        total: Double,
        paid: Double
    ) {
        let remaining = max(0, total - paid)

        nameLabel.text = vendorName
        totalLabel.text = "Total Payable: ₹\(fmt(total))"
        paidLabel.text = "Paid: ₹\(fmt(paid))"
        remainingLabel.text = "Remaining: ₹\(fmt(remaining))"

        let progress = total > 0 ? Float(paid / total) : 0
        progressView.setProgress(min(progress, 1), animated: true)
    }

    // MARK: - Helpers

    private func fmt(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: v)) ?? "0"
    }
}

