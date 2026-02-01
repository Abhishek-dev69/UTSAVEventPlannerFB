import UIKit

final class SubserviceInnerCell: UITableViewCell {

    static let reuseID = "SubserviceInnerCell"

    private let titleLabel = UILabel()
    private let priceLabel = UILabel()

    private let minusBtn = UIButton(type: .system)
    private let plusBtn = UIButton(type: .system)
    private let qtyLabel = UILabel()
    private let addBtn = UIButton(type: .system)

    private weak var qtyStack: UIStackView?
    private let utsavPurple = UIColor(
            red: 136/255,
            green: 71/255,
            blue: 246/255,
            alpha: 1
        )

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

        // Title
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        // Price
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

        // Quantity controls
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
        qtyStack.isHidden = true
        contentView.addSubview(qtyStack)

        self.qtyStack = qtyStack

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: addBtn.leadingAnchor, constant: -12),

            priceLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            priceLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            addBtn.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            addBtn.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            addBtn.widthAnchor.constraint(equalToConstant: 70),
            addBtn.heightAnchor.constraint(equalToConstant: 34),

            qtyStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            qtyStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24)
        ])
    }

    func configure(parentServiceId: String, parentService: String, sub: Subservice, quantity: Int) {
        self.parentServiceId = parentServiceId
        self.parentService = parentService
        self.subservice = sub
        self.quantity = quantity

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
        guard let serviceId = parentServiceId,
              let sub = subservice,
              let subId = sub.id else { return }

        let alert = UIAlertController(
            title: "Add \(sub.name)",
            message: "Enter required quantity",
            preferredStyle: .alert
        )

        alert.addTextField {
            $0.placeholder = "Quantity"
            $0.keyboardType = .numberPad
            $0.text = "1"
        }

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
            self.updateUI()

            CartManager.shared.addItem(
                serviceId: serviceId,
                serviceName: self.parentService,
                subserviceId: subId,
                subserviceName: sub.name,
                rate: rate,
                unit: sub.unit,
                quantity: qty,
                sourceType: "in_house"
            )
        })

        parentViewController?.present(alert, animated: true)
    }

    @objc private func minusTapped() {
        quantity = max(0, quantity - 1)

        guard let sub = subservice else { return }

        CartManager.shared.setQuantity(
            serviceName: parentService,
            subserviceName: sub.name,
            quantity: quantity
        )

        updateUI()
    }

    @objc private func plusTapped() {
        quantity += 1

        guard let sub = subservice else { return }

        CartManager.shared.setQuantity(
            serviceName: parentService,
            subserviceName: sub.name,
            quantity: quantity
        )

        updateUI()
    }
}

// MARK: - Helper to find ViewController
fileprivate extension UIView {
    var parentViewController: UIViewController? {
        var parent: UIResponder? = self
        while let next = parent?.next {
            if let vc = next as? UIViewController { return vc }
            parent = next
        }
        return nil
    }
}
