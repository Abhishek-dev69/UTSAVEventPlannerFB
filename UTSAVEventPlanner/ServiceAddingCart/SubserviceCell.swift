//
//  SubserviceCell.swift
//

import UIKit

final class SubserviceCell: UITableViewCell {

    static let reuseID = "SubserviceCellID"

    private let thumb = UIImageView()
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()

    private let addButton = UIButton(type: .system)
    private let qtyStack = UIStackView()
    private let minusBtn = UIButton(type: .system)
    private let qtyLabel = UILabel()
    private let plusBtn = UIButton(type: .system)

    // NEW REQUIRED — must pass into CartManager.addItem()
    private var parentServiceId: String = ""
    private var parentServiceName: String = ""
    private var subservice: Subservice?

    private var quantity: Int = 0 {
        didSet { updateControls() }
    }

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        addButton.removeTarget(nil, action: nil, for: .allEvents)
        minusBtn.removeTarget(nil, action: nil, for: .allEvents)
        plusBtn.removeTarget(nil, action: nil, for: .allEvents)

        addButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
        minusBtn.addTarget(self, action: #selector(didTapMinus), for: .touchUpInside)
        plusBtn.addTarget(self, action: #selector(didTapPlus), for: .touchUpInside)
    }

    // MARK: - Configure
    func configure(
        parentServiceId: String,
        parentService: String,
        sub: Subservice,
        quantity: Int
    ) {
        self.parentServiceId = parentServiceId
        self.parentServiceName = parentService
        self.subservice = sub
        self.quantity = quantity

        titleLabel.text = sub.name
        priceLabel.text = "₹\(Int(sub.rate)) / \(sub.unit)"
        qtyLabel.text = "\(quantity)"

        updateControls()
    }

    // MARK: - UI Setup
    private func setupUI() {
        selectionStyle = .none

        // Thumb
        thumb.translatesAutoresizingMaskIntoConstraints = false
        thumb.layer.cornerRadius = 8
        thumb.clipsToBounds = true
        thumb.contentMode = .scaleAspectFill
        contentView.addSubview(thumb)

        // Labels
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        priceLabel.font = .systemFont(ofSize: 13)
        priceLabel.textColor = .secondaryLabel
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(priceLabel)

        // Add button
        addButton.setTitle("+ Add", for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        addButton.layer.cornerRadius = 18
        addButton.layer.borderWidth = 1.2
        addButton.layer.borderColor = UIColor.systemPurple.cgColor
        addButton.setTitleColor(.systemPurple, for: .normal)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
        contentView.addSubview(addButton)

        // Qty controls
        minusBtn.setTitle("-", for: .normal)
        minusBtn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        minusBtn.translatesAutoresizingMaskIntoConstraints = false
        minusBtn.addTarget(self, action: #selector(didTapMinus), for: .touchUpInside)

        plusBtn.setTitle("+", for: .normal)
        plusBtn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        plusBtn.translatesAutoresizingMaskIntoConstraints = false
        plusBtn.addTarget(self, action: #selector(didTapPlus), for: .touchUpInside)

        qtyLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        qtyLabel.textAlignment = .center
        qtyLabel.translatesAutoresizingMaskIntoConstraints = false
        qtyLabel.widthAnchor.constraint(equalToConstant: 32).isActive = true

        qtyStack.axis = .horizontal
        qtyStack.spacing = 10
        qtyStack.alignment = .center
        qtyStack.translatesAutoresizingMaskIntoConstraints = false
        qtyStack.addArrangedSubview(minusBtn)
        qtyStack.addArrangedSubview(qtyLabel)
        qtyStack.addArrangedSubview(plusBtn)
        contentView.addSubview(qtyStack)

        // IMPORTANT: ensure vertical constraints anchor contentView top -> bottom
        NSLayoutConstraint.activate([
            // thumb pinned to top & bottom so contentView has a vertical intrinsic height
            thumb.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumb.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            thumb.widthAnchor.constraint(equalToConstant: 66),
            thumb.heightAnchor.constraint(equalToConstant: 46),
            thumb.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),

            // title and price anchored to top and to each other
            titleLabel.leadingAnchor.constraint(equalTo: thumb.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: addButton.leadingAnchor, constant: -12),

            priceLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            // ensure bottom spacing so contentView can determine height
            priceLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),

            // add / qty controls pinned to trailing, centered vertically
            addButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            qtyStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            qtyStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Update UI
    private func updateControls() {
        addButton.isHidden = quantity > 0
        qtyStack.isHidden = quantity == 0
    }

    // MARK: - Actions

    @objc private func didTapAdd() {
        guard let sub = subservice, let subId = sub.id else { return }

        let alert = UIAlertController(
            title: "Add \(sub.name)",
            message: "Enter quantity",
            preferredStyle: .alert
        )

        // Quantity field
        alert.addTextField {
            $0.placeholder = "Quantity"
            $0.keyboardType = .numberPad
            $0.text = "1"
        }

        // If negotiable, ask price also
        if !sub.isFixed {
            alert.addTextField {
                $0.placeholder = "Price (₹)"
                $0.keyboardType = .decimalPad
                $0.text = "\(Int(sub.rate))"
            }
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            let qty = Int(alert.textFields?[0].text ?? "1") ?? 1
            let rate = sub.isFixed
                ? sub.rate
                : Double(alert.textFields?[1].text ?? "") ?? sub.rate

            self.quantity = qty
            self.qtyLabel.text = "\(qty)"

            CartManager.shared.addItem(
                serviceId: self.parentServiceId,
                serviceName: self.parentServiceName,
                subserviceId: subId,
                subserviceName: sub.name,
                rate: rate,
                unit: sub.unit,
                quantity: qty,
                sourceType: "in_house"
            )
        })

        self.parentViewController?.present(alert, animated: true)

    }

    @objc private func didTapMinus() {
        guard let sub = subservice else { return }

        quantity = max(0, quantity - 1)

        CartManager.shared.setQuantity(
            serviceName: parentServiceName,
            subserviceName: sub.name,
            quantity: quantity
        )
    }

    @objc private func didTapPlus() {
        guard let sub = subservice else { return }

        quantity += 1

        CartManager.shared.setQuantity(
            serviceName: parentServiceName,
            subserviceName: sub.name,
            quantity: quantity
        )
    }
}


// MARK: - UIView helper to find owning view controller
fileprivate extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while let next = parentResponder?.next {
            if let vc = next as? UIViewController { return vc }
            parentResponder = next
        }
        return nil
    }
}
