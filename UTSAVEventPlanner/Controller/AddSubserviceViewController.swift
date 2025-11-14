//
//  AddSubserviceViewController.swift
//  UTSAVEventPlanner
//
//  Created by Abhishek on 2025-11-12.
//  Updated: removed Service Name from UI (keeps Subcategory, Rate, Unit, Image, Save).
//

import UIKit
import PhotosUI

final class AddSubserviceViewController: UIViewController {

    // MARK: - Callback
    var onSave: ((Subservice) -> Void)?

    // MARK: - Internal state
    private var selectedImage: UIImage?
    private var selectedUnit = "Per event"
    private let units = ["Per event", "Per hour", "Per person", "Per item"]

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        b.tintColor = .secondaryLabel
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Add Subservice"
        l.font = .boldSystemFont(ofSize: 22)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // NOTE: Service Name removed per request

    private let subcategoryLabel = makeLabel("Subcategory Name")
    private let subcategoryField = makeTextField(placeholder: "e.g. Photography")

    private let rateLabel = makeLabel("Rate")
    private let rateField = makeTextField(placeholder: "₹750", keyboard: .decimalPad)

    private let unitLabel = makeLabel("Unit")
    private let unitButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.baseBackgroundColor = .systemGray6
        cfg.background.cornerRadius = 10
        cfg.title = "Per event"
        cfg.baseForegroundColor = .label
        cfg.image = UIImage(systemName: "chevron.down")
        cfg.imagePlacement = .trailing
        cfg.imagePadding = 6
        let b = UIButton(configuration: cfg)
        b.layer.borderWidth = 0.6
        b.layer.borderColor = UIColor.systemGray4.cgColor
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
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
        let l = UILabel()
        l.text = "Tap to upload image"
        l.font = .systemFont(ofSize: 14)
        l.textColor = .systemGray
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let saveButton: UIButton = {
        // purple pill like Edit screen
        let color = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        var cfg = UIButton.Configuration.filled()
        cfg.title = "Save"
        cfg.baseBackgroundColor = color
        cfg.cornerStyle = .large
        let b = UIButton(configuration: cfg)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 52).isActive = true
        b.layer.cornerRadius = 26
        return b
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupHierarchy()
        setupConstraints()
        setupActions()
    }

    // MARK: - Setup
    private func setupHierarchy() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        // header
        let headerContainer = UIView()
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(titleLabel)
        headerContainer.addSubview(closeButton)
        headerContainer.heightAnchor.constraint(equalToConstant: 50).isActive = true

        // upload stack inside uploadBox
        let uploadStack = UIStackView(arrangedSubviews: [imageIcon, uploadHintLabel])
        uploadStack.axis = .vertical
        uploadStack.alignment = .center
        uploadStack.spacing = 8
        uploadStack.translatesAutoresizingMaskIntoConstraints = false
        uploadBox.addSubview(uploadStack)

        // main stack (service name removed)
        let mainStack = UIStackView(arrangedSubviews: [
            headerContainer,
            subcategoryLabel, subcategoryField,
            rateLabel, rateField,
            unitLabel, unitButton,
            imageLabel, uploadBox,
            saveButton
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(mainStack)

        // constraints for header internal items
        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
            closeButton.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),

            titleLabel.centerXAnchor.constraint(equalTo: headerContainer.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor)
        ])

        // uploadStack constraints
        NSLayoutConstraint.activate([
            uploadStack.centerXAnchor.constraint(equalTo: uploadBox.centerXAnchor),
            uploadStack.centerYAnchor.constraint(equalTo: uploadBox.centerYAnchor),
            uploadBox.heightAnchor.constraint(equalToConstant: 160),
            imageIcon.widthAnchor.constraint(equalToConstant: 100),
            imageIcon.heightAnchor.constraint(equalToConstant: 100)
        ])

        // content constraints handled in setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // scroll & content fill
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

        // main stack (single stack inside content)
        if let mainStack = contentView.subviews.first(where: { $0 is UIStackView }) as? UIStackView {
            NSLayoutConstraint.activate([
                mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
                mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                mainStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -40)
            ])
        }

        // make textfields have consistent heights and unit button width
        subcategoryField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        rateField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        unitButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        unitButton.widthAnchor.constraint(equalToConstant: 120).isActive = true
    }

    private func setupActions() {
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapAddImage))
        uploadBox.addGestureRecognizer(tap)

        unitButton.menu = UIMenu(children: units.map { title in
            UIAction(title: title, state: title == selectedUnit ? .on : .off) { [weak self] _ in
                guard let self = self else { return }
                self.selectedUnit = title
                if var cfg = self.unitButton.configuration {
                    cfg.title = title
                    self.unitButton.configuration = cfg
                } else {
                    self.unitButton.setTitle(title, for: .normal)
                }
            }
        })
        unitButton.showsMenuAsPrimaryAction = true
    }

    // MARK: - Actions
    @objc private func didTapClose() {
        dismiss(animated: true)
    }

    @objc private func didTapAddImage() {
        var conf = PHPickerConfiguration(photoLibrary: .shared())
        conf.filter = .images
        conf.selectionLimit = 1
        let picker = PHPickerViewController(configuration: conf)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func didTapSave() {
        guard let name = subcategoryField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty,
              let rateText = rateField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !rateText.isEmpty,
              let rate = Double(rateText) else {
            // simple validation
            let alert = UIAlertController(title: "Missing fields", message: "Please enter name and valid rate.", preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Provide a stable temporary id so cart additions can reference an ID even before we persist the service to DB.
        // Use a "local-" prefix so it's obvious in logs that this is not a DB id.
        let tempId = "local-\(UUID().uuidString)"
        let sub = Subservice(id: tempId, name: name, rate: rate, unit: selectedUnit, image: selectedImage)
        onSave?(sub)
        dismiss(animated: true)
    }

}

// MARK: - PHPicker Delegate
extension AddSubserviceViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let item = results.first?.itemProvider, item.canLoadObject(ofClass: UIImage.self) else { return }
        item.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
            guard let img = obj as? UIImage else { return }
            DispatchQueue.main.async {
                self?.selectedImage = img
                self?.imageIcon.image = img
                self?.imageIcon.contentMode = .scaleAspectFill
                self?.imageIcon.layer.cornerRadius = 12
                self?.imageIcon.clipsToBounds = true
                self?.uploadHintLabel.isHidden = true
            }
        }
    }
}

// MARK: - File-local helpers (match EditSubservice style)

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
    var cfg = UIButton.Configuration.filled()
    cfg.title = title
    cfg.baseBackgroundColor = color
    cfg.cornerStyle = .large
    let btn = UIButton(configuration: cfg)
    btn.translatesAutoresizingMaskIntoConstraints = false
    return btn
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

        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        leftView = padding
        leftViewMode = .always

        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor.systemGray,
                .font: UIFont.systemFont(ofSize: 15)
            ]
        )
    }
}

