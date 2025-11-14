//
// SubserviceCell.swift
//

import UIKit

final class SubserviceCell: UITableViewCell {
    static let reuseID = "SubserviceCellID"

    private let thumb = UIImageView()
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    private let actionContainer = UIView()
    private let addButton = UIButton(type: .system)
    private let qtyStack = UIStackView()
    private let minusBtn = UIButton(type: .system)
    private let qtyLabel = UILabel()
    private let plusBtn = UIButton(type: .system)

    private var parentServiceName: String = ""
    private var subservice: Subservice?
    private var quantity: Int = 0 {
        didSet {
            qtyLabel.text = "\(quantity)"
            updateControls()
        }
    }

    // Callbacks if viewController wants them
    var onAddTapped: (() -> Void)?
    var onQuantityChanged: ((Int) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        // Reset and reattach actions (important for reused cells)
        addButton.removeTarget(nil, action: nil, for: .allEvents)
        minusBtn.removeTarget(nil, action: nil, for: .allEvents)
        plusBtn.removeTarget(nil, action: nil, for: .allEvents)

        addButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
        minusBtn.addTarget(self, action: #selector(didTapMinus), for: .touchUpInside)
        plusBtn.addTarget(self, action: #selector(didTapPlus), for: .touchUpInside)
    }

    private func setupUI() {
        selectionStyle = .none
        contentView.isUserInteractionEnabled = true

        // Thumb
        thumb.translatesAutoresizingMaskIntoConstraints = false
        thumb.layer.cornerRadius = 8
        thumb.clipsToBounds = true
        thumb.contentMode = .scaleAspectFill
        contentView.addSubview(thumb)

        // Title
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        // Price
        priceLabel.font = .systemFont(ofSize: 13)
        priceLabel.textColor = .secondaryLabel
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(priceLabel)

        // Action container
        actionContainer.translatesAutoresizingMaskIntoConstraints = false
        actionContainer.isUserInteractionEnabled = true
        contentView.addSubview(actionContainer)

        // ---------------- ADD BUTTON ----------------
        addButton.setTitle("+ Add", for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        addButton.layer.cornerRadius = 18
        addButton.layer.borderWidth = 1.2
        addButton.layer.borderColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1).cgColor
        addButton.setTitleColor(UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1), for: .normal)
        addButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.isExclusiveTouch = true
        addButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
        actionContainer.addSubview(addButton)

        // ---------------- QTY BUTTONS ----------------
        minusBtn.setTitle("-", for: .normal)
        minusBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        minusBtn.translatesAutoresizingMaskIntoConstraints = false
        minusBtn.addTarget(self, action: #selector(didTapMinus), for: .touchUpInside)

        plusBtn.setTitle("+", for: .normal)
        plusBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        plusBtn.translatesAutoresizingMaskIntoConstraints = false
        plusBtn.addTarget(self, action: #selector(didTapPlus), for: .touchUpInside)

        qtyLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        qtyLabel.textAlignment = .center
        qtyLabel.widthAnchor.constraint(equalToConstant: 32).isActive = true

        qtyStack.axis = .horizontal
        qtyStack.spacing = 8
        qtyStack.alignment = .center
        qtyStack.translatesAutoresizingMaskIntoConstraints = false
        qtyStack.addArrangedSubview(minusBtn)
        qtyStack.addArrangedSubview(qtyLabel)
        qtyStack.addArrangedSubview(plusBtn)
        actionContainer.addSubview(qtyStack)

        // ---------------- LAYOUT ----------------
        NSLayoutConstraint.activate([
            thumb.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumb.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumb.widthAnchor.constraint(equalToConstant: 66),
            thumb.heightAnchor.constraint(equalToConstant: 46),

            titleLabel.leadingAnchor.constraint(equalTo: thumb.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),

            priceLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),

            // actionContainer: explicit top/bottom/width so it receives touches reliably
            actionContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            actionContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            actionContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            actionContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 88),

            addButton.topAnchor.constraint(equalTo: actionContainer.topAnchor),
            addButton.bottomAnchor.constraint(equalTo: actionContainer.bottomAnchor),
            addButton.trailingAnchor.constraint(equalTo: actionContainer.trailingAnchor),

            qtyStack.topAnchor.constraint(equalTo: actionContainer.topAnchor),
            qtyStack.trailingAnchor.constraint(equalTo: actionContainer.trailingAnchor)
        ])

        // ensure content bottom is defined (for dynamic height)
        let bottom = qtyStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16)
        bottom.priority = .defaultHigh
        bottom.isActive = true

        qtyStack.isHidden = true
    }

    func configure(parentService: String, sub: Subservice, initialQuantity: Int) {
        self.parentServiceName = parentService
        self.subservice = sub

        titleLabel.text = sub.name
        priceLabel.text = "₹\(Int(sub.rate)) / \(sub.unit.lowercased())"

        thumb.image = sub.image ?? UIImage(systemName: "photo")

        quantity = initialQuantity
    }

    private func updateControls() {
        addButton.isHidden = quantity > 0
        qtyStack.isHidden = quantity == 0
    }

    // ---------------- BUTTON ACTIONS ----------------

    @objc private func didTapAdd() {
        print("🔵 SubserviceCell → Add pressed for \(subservice?.name ?? "nil")")

        quantity = 1
        onAddTapped?()

        // Pass correct subserviceId (do NOT generate a random id here)
        if let sub = subservice {
            CartManager.shared.addItem(
                serviceName: parentServiceName,
                subserviceId: sub.id,
                subserviceName: sub.name,
                rate: sub.rate,
                unit: sub.unit,
                quantity: 1
            )
        }

        onQuantityChanged?(quantity)
    }

    @objc private func didTapMinus() {
        quantity = max(0, quantity - 1)

        if let sub = subservice {
            CartManager.shared.setQuantity(
                serviceName: parentServiceName,
                subserviceName: sub.name,
                quantity: quantity
            )
        }

        onQuantityChanged?(quantity)
    }

    @objc private func didTapPlus() {
        quantity += 1

        if let sub = subservice {
            CartManager.shared.setQuantity(
                serviceName: parentServiceName,
                subserviceName: sub.name,
                quantity: quantity
            )
        }

        onQuantityChanged?(quantity)
    }
}

