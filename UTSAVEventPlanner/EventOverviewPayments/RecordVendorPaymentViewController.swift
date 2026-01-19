import UIKit

final class RecordVendorPaymentViewController: UIViewController {

    // MARK: - Inputs
    private let vendorId: String
    private let vendorName: String

    // MARK: - UI
    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private let vendorField = UITextField()
    private let amountField = UITextField()
    private let methodField = UITextField()
    private let dateField = UITextField()
    private let saveButton = UIButton(type: .system)

    private let datePicker = UIDatePicker()

    // 🔽 Payment Method Picker (SAME AS CLIENT)
    private let methodPicker = UIPickerView()
    private let paymentMethods = [
        "UPI",
        "Cash",
        "Cheque",
        "Bank Transfer",
        "Card",
        "Other"
    ]

    // MARK: - Init
    init(vendorId: String, vendorName: String) {
        self.vendorId = vendorId
        self.vendorName = vendorName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(vendorId:vendorName:)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        setupNav()
        setupViews()
        configureDefaults()
    }

    // MARK: - Nav
    private func setupNav() {
        navigationItem.title = "Pay Vendor"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    // MARK: - UI Setup
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
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -32)
        ])

        vendorField.borderStyle = .roundedRect
        vendorField.isEnabled = false
        vendorField.text = vendorName

        amountField.borderStyle = .roundedRect
        amountField.placeholder = "Amount"
        amountField.keyboardType = .decimalPad

        // 🔽 Payment Method Picker
        methodField.borderStyle = .roundedRect
        methodField.placeholder = "Payment Method"
        methodField.tintColor = .clear // hide cursor
        methodField.inputView = methodPicker

        methodPicker.dataSource = self
        methodPicker.delegate = self
        attachPickerToolbar(to: methodField)

        dateField.borderStyle = .roundedRect
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        dateField.inputView = datePicker

        saveButton.setTitle("Save Payment", for: .normal)
        saveButton.backgroundColor = UIColor(
            red: 139/255, green: 59/255, blue: 240/255, alpha: 1
        )
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 22
        saveButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        [vendorField, amountField, methodField, dateField, saveButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            stack.addArrangedSubview($0)
        }
    }

    private func configureDefaults() {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        dateField.text = df.string(from: Date())
        datePicker.date = Date()

        // ✅ Default payment method
        methodField.text = "Bank Transfer"
    }

    // MARK: - Actions
    @objc private func dateChanged() {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        dateField.text = df.string(from: datePicker.date)
    }

    @objc private func saveTapped() {
        let amount = Double(amountField.text ?? "") ?? 0
        if amount <= 0 {
            showAlert("Invalid amount")
            return
        }

        let method = methodField.text?.trimmingCharacters(in: .whitespaces) ?? "Bank Transfer"
        let date = dateField.text!

        Task {
            do {
                _ = try await PaymentSupabaseManager.shared.insertVendorPayment(
                    vendorId: vendorId,
                    amount: amount,
                    method: method,
                    receivedOn: date
                )

                NotificationCenter.default.post(
                    name: Notification.Name("ReloadPaymentsList"),
                    object: nil
                )

                await MainActor.run { self.dismiss(animated: true) }

            } catch {
                await MainActor.run { self.showAlert(error.localizedDescription) }
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

    private func showAlert(_ msg: String) {
        let a = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - Picker
extension RecordVendorPaymentViewController: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        paymentMethods.count
    }

    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        paymentMethods[row]
    }

    func pickerView(_ pickerView: UIPickerView,
                    didSelectRow row: Int,
                    inComponent component: Int) {
        methodField.text = paymentMethods[row]
    }
}

