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

    // MARK: - Init
    init(vendorId: String, vendorName: String) {
        self.vendorId = vendorId
        self.vendorName = vendorName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(vendorId:vendorName:)")
    }

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

    // MARK: - Nav
    private func setupNav() {
        setupUTSAVNavbar(title: "Record Vendor Payment")
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

    // MARK: - UI Setup
    private func setupViews() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        scroll.contentInset.top = 20

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
            
            let leftPad = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
            f.leftView = leftPad
            f.leftViewMode = .always
            
            f.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: UIColor.black.withAlphaComponent(0.4)]
            )
            
            f.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }

        styleInput(vendorField, placeholder: "Vendor Name")
        vendorField.isEnabled = false
        vendorField.alpha = 0.7
        vendorField.text = vendorName

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
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        dateField.inputView = datePicker

        setupUTSAVPrimaryButton(saveButton, title: "Save Payment")
        saveButton.heightAnchor.constraint(equalToConstant: 54).isActive = true
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
        methodField.text = "Bank Transfer"
    }

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
                    vendorId: vendorId, amount: amount, method: method, receivedOn: date
                )
                NotificationCenter.default.post(name: Notification.Name("ReloadPaymentsList"), object: nil)
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
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        paymentMethods[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        methodField.text = paymentMethods[row]
    }
}
