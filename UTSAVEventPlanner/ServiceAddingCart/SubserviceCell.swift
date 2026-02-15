//
//  SubserviceCell.swift
//

import UIKit

final class SubserviceCell: UITableViewCell {

    static let reuseID = "SubserviceCellID"

    private let titleLabel = UILabel()
    private let priceLabel = UILabel()

    private let addButton = UIButton(type: .system)
    private let qtyStack = UIStackView()
    private let minusBtn = UIButton(type: .system)
    private let qtyLabel = UILabel()
    private let plusBtn = UIButton(type: .system)

    private let utsavPurple = UIColor(
        red: 136/255,
        green: 71/255,
        blue: 246/255,
        alpha: 1
    )

    private var parentServiceId = ""
    private var parentServiceName = ""
    private var subservice: Subservice?
    private var quantity: Int = 0 {
        didSet { updateControls() }
    }

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        updateControls()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        quantity = 0
        updateControls()
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
        priceLabel.text = "₹\(Int(sub.rate))"   // 🔥 removed `/ unit`
    }

    // MARK: - UI
    private func setupUI() {
        selectionStyle = .none
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16

        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        priceLabel.font = .systemFont(ofSize: 13)
        priceLabel.textColor = .secondaryLabel

        // + ADD button
        addButton.setTitle("+ Add", for: .normal)
        addButton.setTitleColor(utsavPurple, for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        addButton.layer.borderColor = utsavPurple.cgColor
        addButton.layer.borderWidth = 1
        addButton.layer.cornerRadius = 14
        addButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)

        // Qty controls
        minusBtn.setTitle("-", for: .normal)
        minusBtn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        minusBtn.addTarget(self, action: #selector(didTapMinus), for: .touchUpInside)

        plusBtn.setTitle("+", for: .normal)
        plusBtn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        plusBtn.addTarget(self, action: #selector(didTapPlus), for: .touchUpInside)

        qtyLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        qtyLabel.textAlignment = .center
        qtyLabel.widthAnchor.constraint(equalToConstant: 28).isActive = true

        qtyStack.axis = .horizontal
        qtyStack.spacing = 8
        qtyStack.alignment = .center
        qtyStack.addArrangedSubview(minusBtn)
        qtyStack.addArrangedSubview(qtyLabel)
        qtyStack.addArrangedSubview(plusBtn)

        [titleLabel, priceLabel, addButton, qtyStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: addButton.leadingAnchor, constant: -12),

            priceLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            priceLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),

            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            addButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 56),
            addButton.heightAnchor.constraint(equalToConstant: 28),

            qtyStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            qtyStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    private func updateControls() {
        qtyLabel.text = "\(quantity)"
        addButton.isHidden = quantity > 0
        qtyStack.isHidden = quantity == 0
    }

    // MARK: - Actions
    @objc private func didTapAdd() {
        guard let sub = subservice,
              let vc = parentViewController else { return }

        let alert = UIAlertController(
            title: "Add \(sub.name)",
            message: "Enter required quantity",
            preferredStyle: .alert
        )

        // Quantity field
        alert.addTextField {
            $0.placeholder = "Quantity"
            $0.keyboardType = .numberPad
            $0.text = "1"
        }

        // Rate field (only if not fixed)
        if !sub.isFixed {
            alert.addTextField {
                $0.placeholder = "Price (₹)"
                $0.keyboardType = .decimalPad
                $0.text = "\(Int(sub.rate))"
            }
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self else { return }

            let qty = Int(alert.textFields?[0].text ?? "1") ?? 1
            let rate = sub.isFixed
                ? sub.rate
                : Double(alert.textFields?[1].text ?? "") ?? sub.rate

            self.quantity = qty

            CartManager.shared.addItem(
                serviceId: self.parentServiceId,
                serviceName: self.parentServiceName,
                subserviceId: sub.id ?? "",
                subserviceName: sub.name,
                rate: rate,
                unit: sub.unit,
                quantity: qty
            )
        })

        vc.present(alert, animated: true)
    }

    @objc private func didTapMinus() {
        quantity = max(0, quantity - 1)
        CartManager.shared.setQuantity(
            serviceName: parentServiceName,
            subserviceName: subservice?.name ?? "",
            quantity: quantity
        )
    }

    @objc private func didTapPlus() {
        quantity += 1
        CartManager.shared.setQuantity(
            serviceName: parentServiceName,
            subserviceName: subservice?.name ?? "",
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
