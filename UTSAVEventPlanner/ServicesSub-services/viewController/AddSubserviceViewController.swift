//
//  AddSubserviceViewController.swift
//  UTSAVEventPlanner
//
//  Clean version:
//  - No Image upload
//  - No Unit
//  - Rate Type as radio buttons (Fixed / Negotiable)
//  - Keyboard safe & tap to dismiss
//

import UIKit

final class AddSubserviceViewController: UIViewController {

    // MARK: - Callback
    var onSave: ((Subservice) -> Void)?

    // MARK: - State
    private var isFixedRate: Bool = true {
        didSet { updateRateTypeButtons() }
    }

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var scrollBottomConstraint: NSLayoutConstraint!

    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        b.tintColor = .secondaryLabel
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Add Sub-Service"
        l.font = .boldSystemFont(ofSize: 22)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let nameLabel = makeLabel("Sub-Service Name")
    private let nameField = makeTextField(placeholder: "e.g. Photography")

    private let rateLabel = makeLabel("Rate")
    private let rateField = makeTextField(
        placeholder: "₹750",
        keyboard: .decimalPad
    )

    private let rateTypeLabel = makeLabel("Rate Type")

    private let fixedButton = makeRadioButton(title: "Fixed")
    private let negotiableButton = makeRadioButton(title: "Negotiable")

    private let saveButton: UIButton = {
        let purple = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        var cfg = UIButton.Configuration.filled()
        cfg.title = "Save"
        cfg.baseBackgroundColor = purple
        cfg.cornerStyle = .large
        let b = UIButton(configuration: cfg)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return b
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground

        setupUI()
        setupActions()
        setupKeyboardObservers()
        setupTapToDismiss()
        updateRateTypeButtons()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.heightAnchor.constraint(equalToConstant: 50).isActive = true
        header.addSubview(titleLabel)
        header.addSubview(closeButton)

        let rateStack = UIStackView(arrangedSubviews: [fixedButton, negotiableButton])
        rateStack.axis = .vertical
        rateStack.spacing = 10

        let mainStack = UIStackView(arrangedSubviews: [
            header,
            nameLabel, nameField,
            rateLabel, rateField,
            rateTypeLabel, rateStack,
            saveButton
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 18
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(mainStack)

        scrollBottomConstraint =
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollBottomConstraint,

            // Content
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Main Stack
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -40),

            // Header
            closeButton.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            closeButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor)
        ])
    }

    // MARK: - Actions
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        fixedButton.addTarget(self, action: #selector(selectFixed), for: .touchUpInside)
        negotiableButton.addTarget(self, action: #selector(selectNegotiable), for: .touchUpInside)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func selectFixed() {
        isFixedRate = true
    }

    @objc private func selectNegotiable() {
        isFixedRate = false
    }

    private func updateRateTypeButtons() {
        let selected = UIImage(systemName: "largecircle.fill.circle")
        let unselected = UIImage(systemName: "circle")

        fixedButton.setImage(isFixedRate ? selected : unselected, for: .normal)
        negotiableButton.setImage(isFixedRate ? unselected : selected, for: .normal)

        let purple = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        fixedButton.tintColor = purple
        negotiableButton.tintColor = purple

        fixedButton.imageEdgeInsets = .init(top: 0, left: -6, bottom: 0, right: 6)
        negotiableButton.imageEdgeInsets = .init(top: 0, left: -6, bottom: 0, right: 6)
    }

    @objc private func saveTapped() {
        guard
            let name = nameField.text?.trimmingCharacters(in: .whitespaces),
            !name.isEmpty,
            let rateText = rateField.text,
            let rate = Double(rateText)
        else {
            let alert = UIAlertController(
                title: "Missing fields",
                message: "Please enter a valid name and rate.",
                preferredStyle: .alert
            )
            alert.addAction(.init(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let sub = Subservice(
            id: "local-\(UUID().uuidString)",
            name: name,
            rate: rate,
            unit: "",       // intentionally empty
            isFixed: isFixedRate
        )

        onSave?(sub)
        dismiss(animated: true)
    }

    // MARK: - Keyboard Handling
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(_ note: Notification) {
        guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollBottomConstraint.constant = -frame.height + 20
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    @objc private func keyboardWillHide(_ note: Notification) {
        scrollBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    private func setupTapToDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingNow))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func endEditingNow() {
        view.endEditing(true)
    }
}

//
// MARK: - Helpers
//

fileprivate func makeLabel(_ text: String) -> UILabel {
    let l = UILabel()
    l.text = text
    l.font = .systemFont(ofSize: 15, weight: .semibold)
    l.textColor = .secondaryLabel
    l.translatesAutoresizingMaskIntoConstraints = false
    return l
}

fileprivate func makeTextField(
    placeholder: String,
    keyboard: UIKeyboardType = .default
) -> UITextField {
    let tf = UITextField()
    tf.keyboardType = keyboard
    tf.translatesAutoresizingMaskIntoConstraints = false
    tf.heightAnchor.constraint(equalToConstant: 44).isActive = true
    tf.applyModernStyle(withPlaceholder: placeholder)
    return tf
}

fileprivate func makeRadioButton(title: String) -> UIButton {
    let b = UIButton(type: .system)
    b.setTitle(title, for: .normal)
    b.contentHorizontalAlignment = .leading
    b.titleLabel?.font = .systemFont(ofSize: 15)
    b.translatesAutoresizingMaskIntoConstraints = false
    b.heightAnchor.constraint(equalToConstant: 40).isActive = true
    return b
}

fileprivate extension UITextField {
    func applyModernStyle(withPlaceholder placeholder: String) {
        backgroundColor = UIColor(white: 0.97, alpha: 1)
        layer.cornerRadius = 10
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        font = .systemFont(ofSize: 15)
        clearButtonMode = .whileEditing

        let pad = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        leftView = pad
        leftViewMode = .always

        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.systemGray]
        )
    }
}

