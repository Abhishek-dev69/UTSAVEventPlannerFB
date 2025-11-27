//
//  AddBudgetViewController.swift
//  UTSAV
//
//  Created by Abhishek on 25/11/25.
//

//
// AddBudgetViewController.swift
// Form to add an expense (static UI, local validation). Push or present as needed.
//

import UIKit
import PhotosUI

final class AddBudgetViewController: UIViewController {

    private let vendorName: String?

    init(vendorName: String?) {
        self.vendorName = vendorName
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // UI
    private let stack = UIStackView()
    private let amountField = UITextField()
    private let vendorField = UITextField()
    private let categoryField = UITextField()
    private let dateField = UITextField()
    private let attachButton = UIButton(type: .system)
    private let addButton = UIButton(type: .system)

    private let datePicker = UIDatePicker()
    private var attachedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Add Expenses"
        setupNav()
        setupUI()
        configureDatePicker()
    }

    private func setupNav() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain, target: self, action: #selector(closeTapped)
        )
    }

    @objc private func closeTapped() { navigationController?.popViewController(animated: true) }

    private func setupUI() {
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        amountField.placeholder = "Amount"
        amountField.borderStyle = .roundedRect
        amountField.keyboardType = .decimalPad
        amountField.heightAnchor.constraint(equalToConstant: 48).isActive = true

        vendorField.placeholder = "Vendor"
        vendorField.borderStyle = .roundedRect
        vendorField.heightAnchor.constraint(equalToConstant: 48).isActive = true
        vendorField.text = vendorName

        categoryField.placeholder = "Category"
        categoryField.borderStyle = .roundedRect
        categoryField.heightAnchor.constraint(equalToConstant: 48).isActive = true

        dateField.placeholder = "Date"
        dateField.borderStyle = .roundedRect
        dateField.heightAnchor.constraint(equalToConstant: 48).isActive = true
        dateField.addTarget(self, action: #selector(dateFieldTapped), for: .editingDidBegin)

        attachButton.setTitle("Attach Receipt / Document", for: .normal)
        attachButton.setTitleColor(.systemBlue, for: .normal)
        attachButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        attachButton.addTarget(self, action: #selector(attachTapped), for: .touchUpInside)
        attachButton.contentHorizontalAlignment = .left

        addButton.setTitle("Add Expense", for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        addButton.backgroundColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        addButton.setTitleColor(.white, for: .normal)
        addButton.layer.cornerRadius = 26
        addButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        addButton.addTarget(self, action: #selector(addExpenseTapped), for: .touchUpInside)

        [amountField, vendorField, categoryField, dateField, attachButton].forEach { stack.addArrangedSubview($0) }
        stack.setCustomSpacing(28, after: attachButton)
        stack.addArrangedSubview(addButton)

        // dismiss keyboard tap
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dateFieldTapped() {
        if !dateField.isFirstResponder { dateField.becomeFirstResponder() }
    }

    private func configureDatePicker() {
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.datePickerMode = .date
        dateField.inputView = datePicker

        let tb = UIToolbar(); tb.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dateDone))
        tb.items = [flex, done]
        dateField.inputAccessoryView = tb
    }

    @objc private func dateDone() {
        let df = DateFormatter(); df.dateStyle = .medium
        dateField.text = df.string(from: datePicker.date)
        dateField.resignFirstResponder()
    }

    @objc private func attachTapped() {
        var picker = PHPickerViewController(configuration: PHPickerConfiguration(photoLibrary: .shared()))
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func addExpenseTapped() {
        view.endEditing(true)
        let amount = Double(amountField.text ?? "") ?? 0
        let vendor = vendorField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let category = categoryField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let date = dateField.text ?? ""

        guard amount > 0, !vendor.isEmpty else {
            let a = UIAlertController(title: "Missing info", message: "Please enter amount and vendor.", preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            present(a, animated: true)
            return
        }

        // TODO: persist using your EventPayments manager / Supabase manager
        // For now show success and pop
        let alert = UIAlertController(title: nil, message: "Expense added", preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            alert.dismiss(animated: true) {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }
}
extension AddBudgetViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let item = results.first else { return }
        item.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] obj, err in
            if let img = obj as? UIImage {
                self?.attachedImage = img
            }
        }
    }
}
