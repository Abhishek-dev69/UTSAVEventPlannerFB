import UIKit

final class AddInventoryItemViewController: UIViewController {

    var onItemAdded: ((InventoryItemRecord) -> Void)?
    private let eventId: String

    private let nameField = UITextField()
    private let qtyField = UITextField()
    private let sourceSegment = UISegmentedControl(items: ["Planner", "Vendor"])
    private let saveBtn = UIButton(type: .system)
    private let cancelBtn = UIButton(type: .system)

    init(eventId: String) {
        self.eventId = eventId
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Add Item"
        setupUI()
    }

    private func setupUI() {
        [nameField, qtyField, sourceSegment, saveBtn, cancelBtn].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        nameField.placeholder = "Item Name"
        qtyField.placeholder = "Quantity"
        qtyField.keyboardType = .numberPad

        nameField.borderStyle = .roundedRect
        qtyField.borderStyle = .roundedRect

        sourceSegment.selectedSegmentIndex = 0

        saveBtn.setTitle("Save Item", for: .normal)
        saveBtn.backgroundColor = UIColor.systemPurple
        saveBtn.layer.cornerRadius = 10
        saveBtn.setTitleColor(.white, for: .normal)
        saveBtn.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        cancelBtn.setTitle("Cancel Item", for: .normal)
        cancelBtn.backgroundColor = UIColor.systemRed
        cancelBtn.layer.cornerRadius = 10
        cancelBtn.setTitleColor(.white, for: .normal)
        cancelBtn.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            nameField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            nameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            nameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            nameField.heightAnchor.constraint(equalToConstant: 54),

            qtyField.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 16),
            qtyField.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),
            qtyField.trailingAnchor.constraint(equalTo: nameField.trailingAnchor),
            qtyField.heightAnchor.constraint(equalToConstant: 54),

            sourceSegment.topAnchor.constraint(equalTo: qtyField.bottomAnchor, constant: 12),
            sourceSegment.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),
            sourceSegment.trailingAnchor.constraint(equalTo: nameField.trailingAnchor),
            sourceSegment.heightAnchor.constraint(equalToConstant: 36),

            saveBtn.topAnchor.constraint(equalTo: sourceSegment.bottomAnchor, constant: 28),
            saveBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            saveBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            saveBtn.heightAnchor.constraint(equalToConstant: 50),

            cancelBtn.topAnchor.constraint(equalTo: saveBtn.bottomAnchor, constant: 12),
            cancelBtn.leadingAnchor.constraint(equalTo: saveBtn.leadingAnchor),
            cancelBtn.trailingAnchor.constraint(equalTo: saveBtn.trailingAnchor),
            cancelBtn.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    @objc private func saveTapped() {
        guard let name = nameField.text, !name.isEmpty,
              let qtyText = qtyField.text, let qty = Int(qtyText) else { return }

        let source = sourceSegment.selectedSegmentIndex == 1 ? "vendor" : "planner"

        Task {
            do {
                let item = try await InventoryDataManager.shared.addInventoryItem(
                    eventId: eventId,
                    name: name,
                    quantity: qty,
                    unit: nil,
                    sourceType: source
                )
                onItemAdded?(item)
                navigationController?.popViewController(animated: true)
            } catch {
                print("Failed to add inventory item:", error)
            }
        }
    }

    @objc private func cancelTapped() {
        navigationController?.popViewController(animated: true)
    }
}

