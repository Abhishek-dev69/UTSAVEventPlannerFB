import UIKit
import PhotosUI

final class AddBudgetViewController: UIViewController {

    // MARK: - Init
    private let vendorName: String?
    
    var onExpenseAdded: (() -> Void)?

    init(vendorName: String?) {
        self.vendorName = vendorName
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - UI
    private let stack = UIStackView()
    private let amountField = UITextField()
    private let vendorField = UITextField()
    private let categoryField = UITextField()
    private let dateField = UITextField()
    private let attachButton = UIButton(type: .system)
    private let addButton = UIButton(type: .system)

    private let datePicker = UIDatePicker()
    private var attachedImage: UIImage?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // ✅ Bottom Sheet Style
        view.layer.cornerRadius = 20
        view.clipsToBounds = true

        navigationItem.title = "Add Expense"
        setupNav()
        setupUI()
        configureDatePicker()
    }

    // MARK: - Navigation
    private func setupNav() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak self] _ in
                self?.dismiss(animated: true)
            }
        )
    }

    // MARK: - UI Setup
    private func setupUI() {
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -20)
        ])

        configureField(amountField, placeholder: "Amount (₹)")
        amountField.keyboardType = .decimalPad

        configureField(vendorField, placeholder: "Expense Title")
        vendorField.text = vendorName

        configureField(categoryField, placeholder: "Category (optional)")

        configureField(dateField, placeholder: "Date")
        dateField.addTarget(self, action: #selector(dateFieldTapped), for: .editingDidBegin)

        attachButton.setTitle("📎 Attach Receipt (optional)", for: .normal)
        attachButton.contentHorizontalAlignment = .left
        attachButton.addTarget(self, action: #selector(attachTapped), for: .touchUpInside)

        // ✅ Premium Add Button
        addButton.setTitle("Add Expense", for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        addButton.backgroundColor = UIColor.utsavPurple
        addButton.setTitleColor(.white, for: .normal)
        addButton.layer.cornerRadius = 14
        addButton.heightAnchor.constraint(equalToConstant: 54).isActive = true
        addButton.addTarget(self, action: #selector(addExpenseTapped), for: .touchUpInside)

        // Shadow
        addButton.layer.shadowColor = UIColor.black.cgColor
        addButton.layer.shadowOpacity = 0.15
        addButton.layer.shadowRadius = 8
        addButton.layer.shadowOffset = CGSize(width: 0, height: 4)

        [
            amountField,
            vendorField,
            categoryField,
            dateField,
            attachButton,
            addButton
        ].forEach { stack.addArrangedSubview($0) }

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func configureField(_ field: UITextField, placeholder: String) {
        field.placeholder = placeholder
        field.borderStyle = .none
        field.backgroundColor = UIColor.systemGray6
        field.layer.cornerRadius = 12
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        field.leftViewMode = .always
        field.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }

    // MARK: - Date Picker
    @objc private func dateFieldTapped() {
        dateField.becomeFirstResponder()
    }

    private func configureDatePicker() {
        datePicker.datePickerMode = .date
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        dateField.inputView = datePicker

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dateDone))
        ]
        dateField.inputAccessoryView = toolbar
    }

    @objc private func dateDone() {
        let df = DateFormatter()
        df.dateStyle = .medium
        dateField.text = df.string(from: datePicker.date)
        dateField.resignFirstResponder()
    }

    // MARK: - Actions
    @objc private func attachTapped() {
        let picker = PHPickerViewController(configuration: PHPickerConfiguration(photoLibrary: .shared()))
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func addExpenseTapped() {
        view.endEditing(true)

        let amount = Double(amountField.text ?? "") ?? 0
        let title = vendorField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let category = categoryField.text?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard amount > 0, !title.isEmpty else {
            showAlert("Missing Info", "Please enter amount and vendor.")
            return
        }

        guard let eventId = EventDataManager.shared.currentEventId else {
            showAlert("Error", "No active event found.")
            return
        }

        addButton.isEnabled = false
        addButton.alpha = 0.6

        Task {
            do {
                _ = try await EventDataManager.shared.addBudgetEntry(
                    eventId: eventId,
                    title: title,
                    amount: amount,
                    category: category
                )

                await MainActor.run {
                    // ✅ Close Bottom Sheet
                    self.onExpenseAdded?()
                    self.dismiss(animated: true)
                }
            } catch {
                await MainActor.run {
                    self.addButton.isEnabled = true
                    self.addButton.alpha = 1
                    self.showAlert("Failed", "Could not save expense.")
                }
            }
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func showAlert(_ title: String, _ message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - Image Picker
extension AddBudgetViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let item = results.first else { return }
        item.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
            if let img = obj as? UIImage {
                self?.attachedImage = img
            }
        }
    }
}
