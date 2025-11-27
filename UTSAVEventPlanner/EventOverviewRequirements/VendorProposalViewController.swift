//
//  VendorProposalViewController.swift
//  Updated to match Figma-style UI
//

import UIKit

final class VendorProposalViewController: UIViewController {

    private let vendor: Vendor
    private let requirement: CartItemRecord

    // Top card
    private let card = UIView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()

    // Form fields
    private let vendorField = UITextField()
    private let budgetField = UITextField()
    private let dateField = UITextField()
    private let notesText = UITextView()
    private let sendButton = UIButton(type: .system)

    // Date picker
    private let datePicker = UIDatePicker()

    init(vendor: Vendor, requirement: CartItemRecord) {
        self.vendor = vendor
        self.requirement = requirement
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        navigationItem.title = "Send Proposal to Vendor"

        setupUI()
        configureDatePicker()
        fillData()
    }

    // MARK: - UI Helpers
    private func makeField(_ placeholder: String) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.borderStyle = .roundedRect
        tf.layer.cornerRadius = 10
        tf.layer.masksToBounds = true
        tf.heightAnchor.constraint(equalToConstant: 50).isActive = true
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }

    private func makeLabel(title: String, font: UIFont = .systemFont(ofSize: 14)) -> UILabel {
        let l = UILabel()
        l.text = title
        l.font = font
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    private func setupUI() {
        // Container stack
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 18
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        // Card
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .white
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.layer.shadowRadius = 8
        card.layer.shadowOpacity = 1
        card.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        stack.addArrangedSubview(card)

        // Title & description in card
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        descriptionLabel.font = .systemFont(ofSize: 13)
        descriptionLabel.numberOfLines = 4
        descriptionLabel.textColor = UIColor(white: 0.45, alpha: 1)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(titleLabel)
        card.addSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.layoutMarginsGuide.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: card.layoutMarginsGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: card.layoutMarginsGuide.trailingAnchor),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: card.layoutMarginsGuide.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: card.layoutMarginsGuide.trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: card.layoutMarginsGuide.bottomAnchor)
        ])

        // Vendor field label + field
        stack.addArrangedSubview(makeLabel(title: "Vendor Name"))
        vendorField.placeholder = "approved vendors..."
        vendorField.borderStyle = .roundedRect
        vendorField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        vendorField.translatesAutoresizingMaskIntoConstraints = false
        vendorField.text = vendor.name
        stack.addArrangedSubview(vendorField)

        // Budget
        stack.addArrangedSubview(makeLabel(title: "Proposed Budget to Vendor"))
        budgetField.placeholder = "Enter budget"
        budgetField.borderStyle = .roundedRect
        budgetField.keyboardType = .decimalPad
        budgetField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        budgetField.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(budgetField)

        // Date with calendar icon
        stack.addArrangedSubview(makeLabel(title: "Required Completion Date"))
        dateField.placeholder = "Select date"
        dateField.borderStyle = .roundedRect
        dateField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        dateField.translatesAutoresizingMaskIntoConstraints = false

        // Add trailing calendar button inside the date field
        let calendarButton = UIButton(type: .system)
        calendarButton.setImage(UIImage(systemName: "calendar"), for: .normal)
        calendarButton.tintColor = .darkGray
        calendarButton.addTarget(self, action: #selector(openDatePicker), for: .touchUpInside)
        calendarButton.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        dateField.rightView = calendarButton
        dateField.rightViewMode = .always

        // Make dateField use inputView as date picker as well
        dateField.addTarget(self, action: #selector(dateFieldTapped), for: .editingDidBegin)
        stack.addArrangedSubview(dateField)

        // Notes label + text view
        stack.addArrangedSubview(makeLabel(title: "Notes to Vendor"))
        notesText.layer.cornerRadius = 10
        notesText.layer.borderWidth = 0.6
        notesText.layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
        notesText.font = .systemFont(ofSize: 14)
        notesText.isScrollEnabled = true
        notesText.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        notesText.heightAnchor.constraint(equalToConstant: 140).isActive = true
        notesText.translatesAutoresizingMaskIntoConstraints = false
        notesText.text = "" // empty by default
        stack.addArrangedSubview(notesText)

        // Spacer
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: 8).isActive = true
        stack.addArrangedSubview(spacer)

        // Send button
        sendButton.setTitle("Send Proposal", for: .normal)
        sendButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        sendButton.backgroundColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.layer.cornerRadius = 24
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        stack.addArrangedSubview(sendButton)

        // Make stack fill width
        stack.setCustomSpacing(8, after: card)
    }

    // MARK: - Date picker setup
    private func configureDatePicker() {
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.datePickerMode = .date
        if #available(iOS 14.0, *) {
            datePicker.locale = Locale.current
        }
        // toolbar for Done
        let tb = UIToolbar()
        tb.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dateDoneTapped))
        tb.items = [flex, done]
        dateField.inputAccessoryView = tb
        dateField.inputView = datePicker
    }

    @objc private func openDatePicker() {
        dateField.becomeFirstResponder()
    }

    @objc private func dateFieldTapped() {
        // ensure date picker is visible when field is tapped
        if dateField.isFirstResponder == false {
            dateField.becomeFirstResponder()
        }
    }

    @objc private func dateDoneTapped() {
        let df = DateFormatter()
        df.dateStyle = .medium
        dateField.text = df.string(from: datePicker.date)
        dateField.resignFirstResponder()
    }

    // MARK: - Fill values
    private func fillData() {
        // Title should be service/material name
        titleLabel.text = requirement.serviceName?.isEmpty == false ? requirement.serviceName : "Service"

        // Description should be the detailed requirements (subservice_name)
        descriptionLabel.text = requirement.subserviceName ?? ""

        // Default vendor is passed, budget default uses rate * qty
        vendorField.text = vendor.name
        let rate = requirement.rate ?? 0
        let qty = requirement.quantity ?? 1
        let total = Int(rate * Double(qty))
        budgetField.text = "\(total)"
    }

    // MARK: - SEND TO SUPABASE
    @objc private func sendTapped() {
        // Validate inputs
        guard
            let budgetText = budgetField.text,
            let budget = Double(budgetText),
            let eventId = requirement.eventId
        else {
            let a = UIAlertController(title: "Missing info", message: "Please fill required fields.", preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            present(a, animated: true)
            return
        }

        let completionDate = dateField.text ?? ""
        let notes = notesText.text ?? ""

        Task {
            do {
                try await VendorProposalSupabaseManager.shared.sendProposal(
                    eventId: eventId,
                    vendorId: vendor.id,
                    serviceName: requirement.serviceName ?? "",
                    description: requirement.subserviceName ?? "",
                    budget: budget,
                    completionDate: completionDate,
                    notes: notes
                )

                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Success",
                        message: "Proposal Sent Successfully!",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.navigationController?.popViewController(animated: true)
                    })
                    self.present(alert, animated: true)
                }
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}
