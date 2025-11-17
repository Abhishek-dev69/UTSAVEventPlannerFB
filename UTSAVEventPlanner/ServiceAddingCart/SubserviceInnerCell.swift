//
//  SubserviceInnerCell.swift
//

import UIKit

final class SubserviceInnerCell: UITableViewCell {

    static let reuseID = "SubserviceInnerCell"

    private let thumb = UIImageView()
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()

    private let minusBtn = UIButton(type: .system)
    private let plusBtn = UIButton(type: .system)
    private let qtyLabel = UILabel()
    private let addBtn = UIButton(type: .system)

    // --- NEW: store serviceId so we can send it to CartManager
    private var parentServiceId: String?

    private var parentService = ""
    private var subservice: Subservice?
    private var quantity = 0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        selectionStyle = .none

        thumb.layer.cornerRadius = 10
        thumb.clipsToBounds = true
        thumb.translatesAutoresizingMaskIntoConstraints = false
        thumb.contentMode = .scaleAspectFill
        contentView.addSubview(thumb)

        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        priceLabel.font = .systemFont(ofSize: 13)
        priceLabel.textColor = .secondaryLabel
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(priceLabel)

        // Add button
        addBtn.setTitle("+ Add", for: .normal)
        addBtn.setTitleColor(UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1), for: .normal)
        addBtn.layer.cornerRadius = 18
        addBtn.layer.borderWidth = 1.2
        addBtn.layer.borderColor = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1).cgColor
        addBtn.translatesAutoresizingMaskIntoConstraints = false
        addBtn.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        contentView.addSubview(addBtn)

        minusBtn.setTitle("-", for: .normal)
        minusBtn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        minusBtn.translatesAutoresizingMaskIntoConstraints = false
        minusBtn.addTarget(self, action: #selector(minusTapped), for: .touchUpInside)

        plusBtn.setTitle("+", for: .normal)
        plusBtn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        plusBtn.translatesAutoresizingMaskIntoConstraints = false
        plusBtn.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)

        qtyLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        qtyLabel.textAlignment = .center
        qtyLabel.translatesAutoresizingMaskIntoConstraints = false
        qtyLabel.widthAnchor.constraint(equalToConstant: 30).isActive = true

        let qtyStack = UIStackView(arrangedSubviews: [minusBtn, qtyLabel, plusBtn])
        qtyStack.axis = .horizontal
        qtyStack.spacing = 10
        qtyStack.alignment = .center
        qtyStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(qtyStack)

        qtyStack.isHidden = true

        NSLayoutConstraint.activate([
            // Thumb pinned top + fixed height and bottom margin to contentView (so cell gets vertical size)
            thumb.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            thumb.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            thumb.widthAnchor.constraint(equalToConstant: 58),
            thumb.heightAnchor.constraint(equalToConstant: 58),
            thumb.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),

            // Title anchored to thumb top and price below it
            titleLabel.leadingAnchor.constraint(equalTo: thumb.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: thumb.topAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: addBtn.leadingAnchor, constant: -8),

            priceLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            priceLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),

            // Add / qty controls pinned right & centered vertically
            addBtn.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            addBtn.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            addBtn.widthAnchor.constraint(equalToConstant: 70),
            addBtn.heightAnchor.constraint(equalToConstant: 34),

            qtyStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            qtyStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24)
        ])

        self.qtyStack = qtyStack
    }

    private weak var qtyStack: UIStackView?

    // NOTE: updated configure signature to accept serviceId
    func configure(parentServiceId: String, parentService: String, sub: Subservice, quantity: Int) {
        self.parentServiceId = parentServiceId
        self.parentService = parentService
        self.subservice = sub
        self.quantity = quantity

        thumb.image = sub.image ?? UIImage(systemName: "photo")
        titleLabel.text = sub.name
        priceLabel.text = "₹\(Int(sub.rate))"

        updateUI()
    }

    private func updateUI() {
        qtyLabel.text = "\(quantity)"
        addBtn.isHidden = quantity > 0
        qtyStack?.isHidden = quantity == 0
    }

    @objc private func addTapped() {
        quantity = 1

        // Safely unwrap required values
        guard let serviceId = parentServiceId else { return }
        guard let sub = subservice else { return }
        guard let subId = sub.id else { return }         // ensure DB UUID available
        let subName = sub.name                          // assume non-optional name in model

        CartManager.shared.addItem(
            serviceId: serviceId,               // NEW required parameter
            serviceName: parentService,
            subserviceId: subId,                // DB UUID (unwrapped)
            subserviceName: subName,
            rate: sub.rate,
            unit: sub.unit,
            quantity: 1, sourceType: "in_house"
            
        )
        updateUI()
    }

    @objc private func minusTapped() {
        quantity = max(0, quantity - 1)

        guard let sub = subservice else { return }
        let subName = sub.name

        CartManager.shared.setQuantity(
            serviceName: parentService,
            subserviceName: subName,
            quantity: quantity
        )

        updateUI()
    }

    @objc private func plusTapped() {
        quantity += 1

        guard let sub = subservice else { return }
        let subName = sub.name

        CartManager.shared.setQuantity(
            serviceName: parentService,
            subserviceName: subName,
            quantity: quantity
        )

        updateUI()
    }
}

