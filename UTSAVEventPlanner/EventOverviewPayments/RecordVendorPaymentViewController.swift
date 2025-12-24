//
// RecordVendorPaymentViewController.swift
// Same layout as RecordClientPayment but intended for vendor payments.
// When saved, you may want to mark payer_type = 'vendor' in DB (requires DB + manager support).
//

import UIKit

final class RecordVendorPaymentViewController: UIViewController {

    private let event: EventRecord

    // UI
    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private let vendorField = UITextField()
    private let amountField = UITextField()
    private let methodField = UITextField()
    private let dateField = UITextField()
    private let saveButton = UIButton(type: .system)

    private let datePicker = UIDatePicker()

    init(event: EventRecord) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("Use init(event:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        setupNav()
        setupViews()
        configureDefaults()
    }

    private func setupNav() {
        navigationItem.title = "Record Vendor Payment"
        let close = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(closePressed))
        close.tintColor = .black
        navigationItem.leftBarButtonItem = close
    }
    @objc private func closePressed() { navigationController?.popViewController(animated: true) }

    private func setupViews() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: scroll.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -32)
        ])

        [vendorField, amountField, methodField, dateField, saveButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        vendorField.borderStyle = .roundedRect
        vendorField.placeholder = "Vendor / Payee Name"

        amountField.borderStyle = .roundedRect
        amountField.placeholder = "Amount"
        amountField.keyboardType = .decimalPad

        methodField.borderStyle = .roundedRect
        methodField.placeholder = "Payment Method"

        dateField.borderStyle = .roundedRect
        dateField.placeholder = "Date"

        datePicker.datePickerMode = .date
        if #available(iOS 14.0, *) { datePicker.preferredDatePickerStyle = .wheels }
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        dateField.inputView = datePicker

        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = UIColor(red: 140/255, green: 75/255, blue: 245/255, alpha: 1)
        saveButton.layer.cornerRadius = 22
        saveButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        stack.addArrangedSubview(vendorField)
        stack.addArrangedSubview(amountField)
        stack.addArrangedSubview(methodField)
        stack.addArrangedSubview(dateField)
        stack.addArrangedSubview(UIView())
        stack.addArrangedSubview(saveButton)
    }

    private func configureDefaults() {
        // Vendor default blank — user picks vendor
        let out = DateFormatter()
        out.dateFormat = "yyyy-MM-dd"
        dateField.text = out.string(from: Date())
        datePicker.date = Date()
    }

    @objc private func dateChanged(_ p: UIDatePicker) {
        let out = DateFormatter(); out.dateFormat = "yyyy-MM-dd"; dateField.text = out.string(from: p.date)
    }

    @objc private func saveTapped() {
        let amount = Double(amountField.text ?? "") ?? 0
        if amount <= 0 {
            presentAlert(title: "Invalid amount", message: "Please enter a valid amount")
            return
        }
        let method = methodField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Bank Transfer"
        let date = dateField.text ?? {
            let out = DateFormatter(); out.dateFormat = "yyyy-MM-dd"; return out.string(from: Date())
        }()

        saveButton.isEnabled = false

        Task {
            do {
                // NOTE: The DB schema initially shared doesn't have payer_type — if you added payer_type earlier,
                // extend PaymentSupabaseManager.insertPayment to accept payerType and persist vendor payments correctly.
                _ = try await PaymentSupabaseManager.shared.insertPayment(
                    eventId: event.id,
                    amount: amount,
                    method: method,
                    receivedOn: date,
                    payerType: "vendor"
                )


                NotificationCenter.default.post(name: Notification.Name("ReloadEventOverview"), object: nil)
                NotificationCenter.default.post(name: Notification.Name("ReloadPaymentsList"), object: nil)

                await MainActor.run {
                    saveButton.isEnabled = true
                    navigationController?.popViewController(animated: true)
                }
            } catch {
                await MainActor.run {
                    saveButton.isEnabled = true
                    presentAlert(title: "Save failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func presentAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

