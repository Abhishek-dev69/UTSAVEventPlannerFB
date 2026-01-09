//
// AddInventoryItemViewController.swift
// Radio-style source selection: either "My Inventory" (planner) OR "Vendor Inventory" (vendor)
//

import UIKit

final class AddInventoryItemViewController: UIViewController {

    var onItemAdded: ((InventoryItemRecord) -> Void)?
    private let eventId: String

    private let nameField = UITextField()
    private let qtyField = UITextField()
    var preselectedSource: String?

    // Radio-style buttons (only one can be selected)
    private let plannerRadio = UIButton(type: .system)
    private let vendorRadio = UIButton(type: .system)

    private let saveBtn = UIButton(type: .system)
    private let cancelBtn = UIButton(type: .system)

    // state (single selection)
    private var selectedSource: String = "planner" {
        didSet { updateRadioUI() }
    }

    init(eventId: String) {
        self.eventId = eventId
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Add Item"

        setupUI()

        // 👇 auto-select from dropdown
        if let src = preselectedSource {
            selectedSource = src
        } else {
            selectedSource = "planner"
        }
    }

    private func setupUI() {
        [nameField, qtyField, plannerRadio, vendorRadio, saveBtn, cancelBtn].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        nameField.placeholder = "Item Name"
        qtyField.placeholder = "Quantity"
        qtyField.keyboardType = .numberPad

        nameField.borderStyle = .roundedRect
        qtyField.borderStyle = .roundedRect

        // planner radio
        plannerRadio.setTitle(" My Inventory", for: .normal)
        plannerRadio.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        plannerRadio.contentHorizontalAlignment = .left
        plannerRadio.addTarget(self, action: #selector(plannerTapped), for: .touchUpInside)

        // vendor radio
        vendorRadio.setTitle(" Vendor Inventory", for: .normal)
        vendorRadio.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        vendorRadio.contentHorizontalAlignment = .left
        vendorRadio.addTarget(self, action: #selector(vendorTapped), for: .touchUpInside)

        saveBtn.setTitle("Save Item", for: .normal)
        saveBtn.backgroundColor = UIColor.systemPurple
        saveBtn.layer.cornerRadius = 10
        saveBtn.setTitleColor(.white, for: .normal)
        saveBtn.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        cancelBtn.setTitle("Cancel", for: .normal)
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

            plannerRadio.topAnchor.constraint(equalTo: qtyField.bottomAnchor, constant: 12),
            plannerRadio.leadingAnchor.constraint(equalTo: nameField.leadingAnchor, constant: 6),
            plannerRadio.trailingAnchor.constraint(equalTo: nameField.trailingAnchor),
            plannerRadio.heightAnchor.constraint(equalToConstant: 36),

            vendorRadio.topAnchor.constraint(equalTo: plannerRadio.bottomAnchor, constant: 8),
            vendorRadio.leadingAnchor.constraint(equalTo: nameField.leadingAnchor, constant: 6),
            vendorRadio.trailingAnchor.constraint(equalTo: nameField.trailingAnchor),
            vendorRadio.heightAnchor.constraint(equalToConstant: 36),

            saveBtn.topAnchor.constraint(equalTo: vendorRadio.bottomAnchor, constant: 20),
            saveBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            saveBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            saveBtn.heightAnchor.constraint(equalToConstant: 50),

            cancelBtn.topAnchor.constraint(equalTo: saveBtn.bottomAnchor, constant: 12),
            cancelBtn.leadingAnchor.constraint(equalTo: saveBtn.leadingAnchor),
            cancelBtn.trailingAnchor.constraint(equalTo: saveBtn.trailingAnchor),
            cancelBtn.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func updateRadioUI() {
        func image(forSelected selected: Bool) -> UIImage? {
            UIImage(systemName: selected ? "largecircle.fill.circle" : "circle")
        }
        plannerRadio.setImage(image(forSelected: selectedSource == "planner"), for: .normal)
        vendorRadio.setImage(image(forSelected: selectedSource == "vendor"), for: .normal)

        plannerRadio.tintColor = selectedSource == "planner" ? .systemPurple : .systemGray
        vendorRadio.tintColor = selectedSource == "vendor" ? .systemPurple : .systemGray
    }

    @objc private func plannerTapped() {
        selectedSource = "planner"
    }

    @objc private func vendorTapped() {
        selectedSource = "vendor"
    }

    @objc private func saveTapped() {
        guard let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty,
              let qtyText = qtyField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let qty = Int(qtyText) else {
            let alert = UIAlertController(title: "Missing data", message: "Please enter a valid name and quantity.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let source = selectedSource // "planner" or "vendor"

        Task {
            do {
                // 1) create inventory item with correct quantity
                let item = try await InventoryDataManager.shared.addInventoryItem(
                    eventId: eventId,
                    name: name,
                    quantity: qty,
                    unit: nil,
                    sourceType: source
                )

                // 2) create corresponding post-event pending row with the same qty as item
                //    (previously this passed qty:1 always)
                do {
                    try await InventoryDataManager.shared.createPostEventRow(
                        inventoryItemId: item.id,
                        eventId: eventId,
                        qty: qty            // <--- pass real item quantity
                    )
                } catch {
                    print("Warning: failed to create post-event row for item \(item.id):", error)
                }

                // 3) callback and pop
                onItemAdded?(item)
                navigationController?.popViewController(animated: true)
            } catch {
                print("Failed to add inventory item:", error)
                let alert = UIAlertController(title: "Error", message: "Failed to save item. Try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }

    @objc private func cancelTapped() {
        navigationController?.popViewController(animated: true)
    }
}
