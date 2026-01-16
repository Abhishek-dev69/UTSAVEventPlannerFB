import UIKit

final class OutsourceRequirementDetailViewController: UIViewController {

    private let item: CartItemRecord

    init(item: CartItemRecord) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    private let scroll = UIScrollView()
    private let nameLabel = UILabel()
    private let descLabel = UILabel()
    private let budgetLabel = UILabel()
    private let assignButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        title = "Outsource Requirement"

        setupUI()
        fillData()
    }

    private func setupUI() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -16),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -32),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -20)
        ])

        nameLabel.font = .systemFont(ofSize: 22, weight: .bold)
        descLabel.numberOfLines = 0
        descLabel.font = .systemFont(ofSize: 15)
        budgetLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        budgetLabel.textColor = .systemGreen

        assignButton.setTitle("Assign Vendor", for: .normal)
        assignButton.backgroundColor = UIColor.systemPurple
        assignButton.setTitleColor(.white, for: .normal)
        assignButton.layer.cornerRadius = 22
        assignButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        assignButton.addTarget(self, action: #selector(assignTapped), for: .touchUpInside)

        stack.addArrangedSubview(nameLabel)
        stack.addArrangedSubview(descLabel)
        stack.addArrangedSubview(budgetLabel)
        stack.addArrangedSubview(assignButton)
    }

    private func fillData() {
        nameLabel.text = item.serviceName
        descLabel.text = item.subserviceName
        let total = (item.rate ?? 0) * Double(item.quantity ?? 1)
        budgetLabel.text = "Budget: ₹\(Int(total))"
    }

    @objc private func assignTapped() {
        let vc = VendorSelectionViewController(requirement: item)
        navigationController?.pushViewController(vc, animated: true)
    }
}
