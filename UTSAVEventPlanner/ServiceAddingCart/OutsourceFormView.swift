//
//  OutsourceFormView.swift
//

import UIKit

// Simple model returned on submit
struct OutsourceItem {
    // Original fields (kept for backwards compatibility)
    var name: String
    var details: String
    var vendor: String?
    var estimatedBudget: Double?

    // Computed properties that map to DB/cart naming expected elsewhere
    var serviceName: String { return name }          // maps to service_name
    var subserviceName: String { return details }    // maps to subservice_name

    // Helper to build a payload dictionary matching backend field names
    func payload() -> [String: Any] {
        var p: [String: Any] = [
            "service_name": serviceName,
            "subservice_name": subserviceName
        ]

        if let v = vendor, !v.isEmpty { p["vendor"] = v }
        if let b = estimatedBudget { p["estimated_budget"] = b }

        return p
    }
}

final class OutsourceFormView: UIView {

    // MARK: - Callback
    var onSubmit: ((OutsourceItem) -> Void)?

    // MARK: - UI
    private let card = UIView()

    private let nameLabel = UILabel()
    private let nameField = UITextField()

    private let descLabel = UILabel()
    private let descText = UITextView()

    private let vendorLabel = UILabel()
    private let vendorField = UITextField()

    private let budgetLabel = UILabel()
    private let budgetField = UITextField()

    private let addButton = UIButton(type: .system)

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupKeyboardDismissal()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .clear

        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .white
        card.layer.cornerRadius = 14
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        addSubview(card)

        // Name
        nameLabel.text = "Service/Material Name"
        nameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        nameField.placeholder = "e.g. AV Equipment Rental"
        nameField.font = .systemFont(ofSize: 15)
        nameField.layer.cornerRadius = 10
        nameField.layer.borderWidth = 0.5
        nameField.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
        nameField.setLeftPaddingPoints(12)
        nameField.translatesAutoresizingMaskIntoConstraints = false

        // Description
        descLabel.text = "Detailed Description of Requirement"
        descLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        descLabel.translatesAutoresizingMaskIntoConstraints = false

        descText.font = .systemFont(ofSize: 15)
        descText.layer.cornerRadius = 10
        descText.layer.borderWidth = 0.5
        descText.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
        descText.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        descText.translatesAutoresizingMaskIntoConstraints = false
        descText.isScrollEnabled = false

        // Vendor
        vendorLabel.text = "Vendor Preferences (Optional)"
        vendorLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        vendorLabel.translatesAutoresizingMaskIntoConstraints = false

        vendorField.placeholder = "e.g. ABC Tech Services"
        vendorField.font = .systemFont(ofSize: 15)
        vendorField.layer.cornerRadius = 10
        vendorField.layer.borderWidth = 0.5
        vendorField.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
        vendorField.setLeftPaddingPoints(12)
        vendorField.translatesAutoresizingMaskIntoConstraints = false

        // Budget
        budgetLabel.text = "Estimated Budget (₹)"
        budgetLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        budgetLabel.translatesAutoresizingMaskIntoConstraints = false

        budgetField.placeholder = "e.g. ₹50,000"
        budgetField.font = .systemFont(ofSize: 15)
        budgetField.layer.cornerRadius = 10
        budgetField.layer.borderWidth = 0.5
        budgetField.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
        budgetField.keyboardType = .numbersAndPunctuation
        budgetField.setLeftPaddingPoints(12)
        budgetField.translatesAutoresizingMaskIntoConstraints = false

        // Add Button
        addButton.setTitle("Add", for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        addButton.backgroundColor = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)
        addButton.setTitleColor(.white, for: .normal)
        addButton.layer.cornerRadius = 22
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        // Add subviews
        [nameLabel, nameField,
         descLabel, descText,
         vendorLabel, vendorField,
         budgetLabel, budgetField,
         addButton].forEach { card.addSubview($0) }

        // Layout
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            card.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            card.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            nameLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            nameLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),

            nameField.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            nameField.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            nameField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            nameField.heightAnchor.constraint(equalToConstant: 44),

            descLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            descLabel.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 12),

            descText.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            descText.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            descText.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 8),
            descText.heightAnchor.constraint(equalToConstant: 88),

            vendorLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            vendorLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            vendorLabel.topAnchor.constraint(equalTo: descText.bottomAnchor, constant: 12),

            vendorField.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            vendorField.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            vendorField.topAnchor.constraint(equalTo: vendorLabel.bottomAnchor, constant: 8),
            vendorField.heightAnchor.constraint(equalToConstant: 44),

            budgetLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            budgetLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            budgetLabel.topAnchor.constraint(equalTo: vendorField.bottomAnchor, constant: 12),

            budgetField.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            budgetField.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            budgetField.topAnchor.constraint(equalTo: budgetLabel.bottomAnchor, constant: 8),
            budgetField.heightAnchor.constraint(equalToConstant: 44),

            addButton.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            addButton.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            addButton.topAnchor.constraint(equalTo: budgetField.bottomAnchor, constant: 18),
            addButton.heightAnchor.constraint(equalToConstant: 44),
            addButton.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])

        // Add toolbars
        addDoneToolbar(to: nameField)
        addDoneToolbar(to: vendorField)
        addDoneToolbar(to: budgetField)
        descText.inputAccessoryView = createDoneToolbar()
    }

    // MARK: - Keyboard Dismiss System
    private func setupKeyboardDismissal() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingForce))
        tap.cancelsTouchesInView = false
        addGestureRecognizer(tap)
    }

    @objc private func endEditingForce() {
        endEditing(true)
    }

    private func addDoneToolbar(to textField: UITextField) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(endEditingForce))
        toolbar.items = [flex, done]
        textField.inputAccessoryView = toolbar
    }

    private func createDoneToolbar() -> UIToolbar {
        let tb = UIToolbar()
        tb.sizeToFit()
        tb.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(endEditingForce))
        ]
        return tb
    }

    // MARK: - Reset Form After Submit
    private func resetForm() {
        nameField.text = ""
        descText.text = ""
        vendorField.text = ""
        budgetField.text = ""
    }

    // MARK: - Success Popup
    private func showSuccessPopup(_ message: String) {
        guard let vc = findViewController() else { return }

        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        vc.present(alert, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            alert.dismiss(animated: true)
        }
    }

    // MARK: - Submit
    @objc private func addTapped() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let details = descText.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let vendor = vendorField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let budgetRaw = budgetField.text?
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let budget = Double(budgetRaw) ?? 0

        guard !name.isEmpty, !details.isEmpty else {
            showValidationError("Please enter service name and description.")
            return
        }

        let item = OutsourceItem(
            name: name,
            details: details,
            vendor: vendor.isEmpty ? nil : vendor,
            estimatedBudget: budget > 0 ? budget : nil
        )

        onSubmit?(item)

        resetForm()
        showSuccessPopup("Item added to cart")
    }

    private func showValidationError(_ msg: String) {
        if let vc = findViewController() {
            let a = UIAlertController(title: "Missing info", message: msg, preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            vc.present(a, animated: true)
        }
    }

    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            if let vc = responder as? UIViewController { return vc }
            responder = responder?.next
        }
        return nil
    }
}

private extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: frame.height))
        leftViewMode = .always
    }
}

