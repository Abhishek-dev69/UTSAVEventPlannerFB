//
//  EditSubserviceViewController.swift
//  UTSAVEventPlanner
//
//  Created by Abhishek on 2025-11-12.
//  Updated: removed Service Name from UI (keeps only subcategory, rate, unit, image, save).
//

import UIKit
import PhotosUI

final class EditSubserviceViewController: UIViewController {

    // MARK: - Data & Callbacks
    var onSave: ((Subservice) -> Void)?
    var subserviceToEdit: Subservice?
    var parentServiceName: String?

    private var selectedUnit = "Per event"
    private var selectedImage: UIImage?
    private let units = ["Per event","Per day"]

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .secondaryLabel
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Edit Sub-Service"
        label.font = .boldSystemFont(ofSize: 22)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Service name UI removed (keeps the variable if you need it for logic, but not shown in UI)
    private let serviceLabel = makeLabel("Service Name")
    private let serviceField = makeTextField(placeholder: "Main Service Name") // not added to stack

    private let subcategoryLabel = makeLabel("Subcategory Name")
    private let subcategoryField = makeTextField(placeholder: "e.g. Photography")

    private let rateLabel = makeLabel("Rate")
    private let rateField = makeTextField(placeholder: "₹750", keyboard: .decimalPad)

    private let unitLabel = makeLabel("Unit")

    private let unitButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .systemGray6
        config.background.cornerRadius = 10
        config.title = "Per event"
        config.baseForegroundColor = .label
        config.image = UIImage(systemName: "chevron.down")
        config.imagePlacement = .trailing
        config.imagePadding = 6
        button.configuration = config
        button.layer.borderWidth = 0.6
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let imageLabel = makeLabel("Upload Image")
    private let uploadBox: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGray6
        v.layer.cornerRadius = 10
        v.layer.borderWidth = 0.8
        v.layer.borderColor = UIColor.systemGray4.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let imageIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "photo"))
        iv.tintColor = .systemGray3
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.cornerRadius = 12
        iv.clipsToBounds = true
        return iv
    }()
    private let uploadHintLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap to upload image"
        label.textColor = .systemGray3
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let saveButton = makeActionButton(title: "Save Changes",
                                              color: UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1))

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        populateData()
        setupKeyboardHandling()
    }

    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // Header
        let headerContainer = UIView()
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(titleLabel)
        headerContainer.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 20),
            closeButton.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),

            titleLabel.centerXAnchor.constraint(equalTo: headerContainer.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor)
        ])

        headerContainer.heightAnchor.constraint(equalToConstant: 50).isActive = true

        // Upload Box
        let uploadStack = UIStackView(arrangedSubviews: [imageIcon, uploadHintLabel])
        uploadStack.axis = .vertical
        uploadStack.alignment = .center
        uploadStack.spacing = 8
        uploadStack.translatesAutoresizingMaskIntoConstraints = false
        uploadBox.addSubview(uploadStack)

        NSLayoutConstraint.activate([
            uploadStack.centerXAnchor.constraint(equalTo: uploadBox.centerXAnchor),
            uploadStack.centerYAnchor.constraint(equalTo: uploadBox.centerYAnchor),
            uploadBox.heightAnchor.constraint(equalToConstant: 160),
            imageIcon.widthAnchor.constraint(equalToConstant: 100),
            imageIcon.heightAnchor.constraint(equalToConstant: 100)
        ])

        // Stack — service name removed from UI
        let mainStack = UIStackView(arrangedSubviews: [
            headerContainer,
            subcategoryLabel, subcategoryField,
            rateLabel, rateField,
            unitLabel, unitButton,
            imageLabel, uploadBox,
            saveButton
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 18
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    // MARK: - Actions
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapAddImage))
        uploadBox.addGestureRecognizer(tap)

        unitButton.menu = UIMenu(children: units.map { title in
            UIAction(title: title, state: title == selectedUnit ? .on : .off) { [weak self] _ in
                self?.selectedUnit = title
                if var cfg = self?.unitButton.configuration {
                    cfg.title = title
                    self?.unitButton.configuration = cfg
                } else {
                    self?.unitButton.setTitle(title, for: .normal)
                }
            }
        })
        unitButton.showsMenuAsPrimaryAction = true
    }

    private func populateData() {
        guard let s = subserviceToEdit else { return }
        // serviceField.text = parentServiceName // removed from visible UI
        subcategoryField.text = s.name
        rateField.text = "\(s.rate)"
        selectedUnit = s.unit
        if var cfg = unitButton.configuration { cfg.title = s.unit; unitButton.configuration = cfg } else { unitButton.setTitle(s.unit, for: .normal) }
        selectedImage = s.image
        if let img = s.image {
            imageIcon.image = img
            imageIcon.contentMode = .scaleAspectFill
            imageIcon.layer.cornerRadius = 10
            imageIcon.clipsToBounds = true
            uploadHintLabel.isHidden = true
        }
    }

    @objc private func didTapClose() { dismiss(animated: true) }

    @objc private func didTapAddImage() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func didTapSave() {
        guard let name = subcategoryField.text, !name.isEmpty,
              let rateText = rateField.text, let rate = Double(rateText) else {
            print("⚠️ Missing fields")
            return
        }

        // Preserve existing isFixed value if present; default to true for safety
        let isFixedValue = subserviceToEdit?.isFixed ?? true

        let updated = Subservice(
            id: subserviceToEdit?.id,
            name: name,
            rate: rate,
            unit: selectedUnit,
            image: selectedImage,
            isFixed: isFixedValue
        )
        onSave?(updated)
        dismiss(animated: true)
    }

    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let info = notification.userInfo,
              let frame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom = frame.height + 20
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
    }
}

// MARK: - PHPicker Delegate
extension EditSubserviceViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
            guard let image = obj as? UIImage else { return }
            DispatchQueue.main.async {
                self?.selectedImage = image
                self?.imageIcon.image = image
                self?.imageIcon.contentMode = .scaleAspectFill
                self?.imageIcon.layer.cornerRadius = 10
                self?.imageIcon.clipsToBounds = true
                self?.uploadHintLabel.isHidden = true
            }
        }
    }
}

// MARK: - Helpers (file-local)
fileprivate func makeLabel(_ text: String) -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = text
    label.font = .systemFont(ofSize: 15, weight: .semibold)
    label.textColor = .secondaryLabel
    return label
}

fileprivate func makeTextField(placeholder: String, keyboard: UIKeyboardType = .default) -> UITextField {
    let tf = UITextField()
    tf.translatesAutoresizingMaskIntoConstraints = false
    tf.keyboardType = keyboard
    tf.applyModernStyle(withPlaceholder: placeholder)
    tf.heightAnchor.constraint(equalToConstant: 44).isActive = true
    return tf
}

fileprivate func makeActionButton(title: String, color: UIColor) -> UIButton {
    let button = UIButton(type: .system)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(title, for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.backgroundColor = color
    button.titleLabel?.font = .boldSystemFont(ofSize: 17)
    button.layer.cornerRadius = 25
    button.heightAnchor.constraint(equalToConstant: 50).isActive = true
    return button
}

fileprivate extension UITextField {
    func applyModernStyle(withPlaceholder placeholder: String) {
        translatesAutoresizingMaskIntoConstraints = false
        borderStyle = .none
        backgroundColor = UIColor(white: 0.97, alpha: 1)
        layer.cornerRadius = 10
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        font = .systemFont(ofSize: 15)
        clearButtonMode = .whileEditing

        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        leftView = padding
        leftViewMode = .always

        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.systemGray, .font: UIFont.systemFont(ofSize: 15)]
        )
    }
}

