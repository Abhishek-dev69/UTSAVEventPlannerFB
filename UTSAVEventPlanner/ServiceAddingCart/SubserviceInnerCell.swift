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
            thumb.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            thumb.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            thumb.widthAnchor.constraint(equalToConstant: 58),
            thumb.heightAnchor.constraint(equalToConstant: 58),

            titleLabel.leadingAnchor.constraint(equalTo: thumb.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: thumb.topAnchor),

            priceLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),

            addBtn.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            addBtn.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            addBtn.widthAnchor.constraint(equalToConstant: 70),
            addBtn.heightAnchor.constraint(equalToConstant: 34),

            qtyStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            qtyStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            contentView.bottomAnchor.constraint(equalTo: thumb.bottomAnchor, constant: 12)
        ])

        self.qtyStack = qtyStack
    }

    private weak var qtyStack: UIStackView?

    func configure(parentService: String, sub: Subservice, quantity: Int) {
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
        CartManager.shared.addItem(
            serviceName: parentService,
            subserviceId: subservice?.id,
            subserviceName: subservice?.name ?? "",
            rate: subservice?.rate ?? 0,
            unit: subservice?.unit ?? "",
            quantity: 1
        )
        updateUI()
    }

    @objc private func minusTapped() {
        quantity = max(0, quantity - 1)
        CartManager.shared.setQuantity(
            serviceName: parentService,
            subserviceName: subservice?.name ?? "",
            quantity: quantity
        )
        updateUI()
    }

    @objc private func plusTapped() {
        quantity += 1
        CartManager.shared.setQuantity(
            serviceName: parentService,
            subserviceName: subservice?.name ?? "",
            quantity: quantity
        )
        updateUI()
    }
}

