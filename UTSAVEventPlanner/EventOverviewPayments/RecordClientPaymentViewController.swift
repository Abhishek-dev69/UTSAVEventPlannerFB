//
// RecordClientPaymentViewController.swift
// Simple form to record a client payment for an event
//

import UIKit

final class RecordClientPaymentViewController: UIViewController {

    private let event: EventRecord

    // UI
    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private let clientField = UITextField()
    private let amountField = UITextField()
    private let methodField = UITextField()
    private let dateField = UITextField()
    private let saveButton = UIButton(type: .system)

    private let datePicker = UIDatePicker()

    // 🔽 Payment Method Picker
    private let methodPicker = UIPickerView()
    private let paymentMethods = [
        "UPI",
        "Cash",
        "Cheque",
        "Bank Transfer",
        "Card",
        "Other"
    ]

    // MARK: Init
    init(event: EventRecord) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("Use init(event:)") }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientFrame()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyBrandGradient()
        view.backgroundColor = .clear
        
        setupNav()
        setupViews()
        configureDefaults()
    }

    private func setupNav() {
        setupUTSAVNavbar(title: "Record Client Payment")
        let close = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        navigationItem.leftBarButtonItem = close
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    private func setupViews() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        scroll.contentInset.top = 20 // Reduced gap

        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -36)
        ])

        func styleInput(_ f: UITextField, placeholder: String) {
            f.borderStyle = .none
            f.backgroundColor = .white.withAlphaComponent(0.18)
            f.layer.cornerRadius = 14
            f.textColor = .black
            f.font = .systemFont(ofSize: 16, weight: .medium)
            
            // Native Padding (Apple Style)
            let leftPad = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
            f.leftView = leftPad
            f.leftViewMode = .always
            
            // Aesthetic Placeholder
            f.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: UIColor.black.withAlphaComponent(0.4)]
            )
            
            f.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }

        styleInput(clientField, placeholder: "Client Name")
        clientField.isEnabled = false
        clientField.alpha = 0.7

        styleInput(amountField, placeholder: "Enter Amount")
        amountField.keyboardType = .decimalPad

        styleInput(methodField, placeholder: "Select Method")
        methodField.tintColor = .clear
        methodField.inputView = methodPicker
        methodPicker.dataSource = self
        methodPicker.delegate = self
        attachPickerToolbar(to: methodField)

        styleInput(dateField, placeholder: "Select Date")
        datePicker.datePickerMode = .date
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        dateField.inputView = datePicker

        setupUTSAVPrimaryButton(saveButton, title: "Save Payment")
        saveButton.heightAnchor.constraint(equalToConstant: 54).isActive = true
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        stack.addArrangedSubview(clientField)
        stack.addArrangedSubview(amountField)
        stack.addArrangedSubview(methodField)
        stack.addArrangedSubview(dateField)
        stack.addArrangedSubview(saveButton)
    }

    private func configureDefaults() {
        clientField.text = event.clientName
        methodField.text = "Cash"
        let out = DateFormatter()
        out.dateFormat = "yyyy-MM-dd"
        dateField.text = out.string(from: Date())
        datePicker.date = Date()
    }

    @objc private func dateChanged(_ p: UIDatePicker) {
        let out = DateFormatter()
        out.dateFormat = "yyyy-MM-dd"
        dateField.text = out.string(from: p.date)
    }

    @objc private func saveTapped() {
        let amount = Double(amountField.text ?? "") ?? 0
        if amount <= 0 {
            presentAlert(title: "Invalid amount", message: "Please enter a valid amount")
            return
        }

        let method = methodField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "Cash"

        let date = dateField.text ?? {
            let out = DateFormatter()
            out.dateFormat = "yyyy-MM-dd"
            return out.string(from: Date())
        }()

        saveButton.isEnabled = false

        Task {
            do {
                _ = try await EventDataManager.shared.addPayment(
                    eventId: event.id,
                    amount: amount,
                    method: method,
                    date: date
                )
                
                PaymentsEventStore.shared.clear()
                NotificationCenter.default.post(name: Notification.Name("ReloadEventOverview"), object: nil)
                NotificationCenter.default.post(name: Notification.Name("ReloadPaymentsList"), object: nil)

                await MainActor.run {
                    saveButton.isEnabled = true
                    self.dismiss(animated: true)
                }

            } catch {
                await MainActor.run {
                    saveButton.isEnabled = true
                    presentAlert(title: "Save failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func attachPickerToolbar(to field: UITextField) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(donePickingMethod))
        toolbar.setItems([spacer, done], animated: false)
        field.inputAccessoryView = toolbar
    }

    @objc private func donePickingMethod() {
        methodField.resignFirstResponder()
    }

    private func presentAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - Picker Delegates
extension RecordClientPaymentViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        paymentMethods.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        paymentMethods[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        methodField.text = paymentMethods[row]
    }
}
