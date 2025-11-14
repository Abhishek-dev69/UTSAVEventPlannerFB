//
//  ServiceAddingViewController.swift
//  UTSAVEventPlanner
//
//  Created by Abhishek on 2025-11-12.
//  Updated: Title bigger, service field rounded pill-style, save button auto-styled.
//  Added: originTabIndex + improved close behavior to return to origin tab
//

import UIKit
import Supabase

final class ServiceAddingViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var purpleCardView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var serviceTextField: UITextField!
    @IBOutlet weak var subServicesLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Data
    var subServices: [Subservice] = [] {
        didSet { tableView.reloadData(); updateEmptyState() }
    }

    private var emptyStateLabel: UILabel!
    var onServiceSave: ((Service) -> Void)?

    /// Index of the tab from where this VC was opened. Caller should set this (e.g. addVC.originTabIndex = tabBarController?.selectedIndex)
    var originTabIndex: Int?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTable()
        updateEmptyState()
        serviceTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        addButton.isEnabled = false
        addButton.alpha = 0.4
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // hide nav bar so "Back" top bar won't show
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // restore nav bar for next screens
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    @objc private func textFieldChanged() {
        let hasText = !(serviceTextField.text ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        addButton.isEnabled = hasText
        addButton.alpha = hasText ? 1.0 : 0.4
    }

    // MARK: - UI Setup
    private func setupUI() {
        // purple card appearance
        purpleCardView.layer.cornerRadius = 18
        purpleCardView.layer.shadowColor = UIColor.black.cgColor
        purpleCardView.layer.shadowOpacity = 0.12
        purpleCardView.layer.shadowOffset = CGSize(width: 0, height: 6)
        purpleCardView.layer.shadowRadius = 10
        purpleCardView.backgroundColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)

        // Title — bigger & bolder
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 26, weight: .semibold)
        titleLabel.textAlignment = .center

        // Service TextField — pill style
        serviceTextField.backgroundColor = .white
        serviceTextField.layer.cornerRadius = 28
        serviceTextField.placeholder = "Enter Service Name"
        serviceTextField.textAlignment = .center
        serviceTextField.font = .systemFont(ofSize: 18, weight: .medium)
        serviceTextField.layer.masksToBounds = true

        if let h = serviceTextField.constraints.first(where: { $0.firstAttribute == .height }) {
            h.constant = 56
        } else {
            serviceTextField.heightAnchor.constraint(equalToConstant: 56).isActive = true
        }

        // Close & add buttons
        closeButton.tintColor = .black
        addButton.tintColor = .black
        addButton.layer.cornerRadius = 18

        // Subservices label
        subServicesLabel.font = .boldSystemFont(ofSize: 20)
        subServicesLabel.textColor = UIColor(red: 32/255, green: 42/255, blue: 52/255, alpha: 1)

        // Style Save button if present
        styleSaveButtonIfFound(root: view)
    }

    // Traverse view tree and style any UIButton whose title contains "Save".
    private func styleSaveButtonIfFound(root: UIView) {
        for sub in root.subviews {
            if let btn = sub as? UIButton, let title = btn.currentTitle?.lowercased(), title.contains("save") {
                btn.layer.cornerRadius = 28
                btn.clipsToBounds = true
                btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
                btn.setTitleColor(.white, for: .normal)
                btn.backgroundColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
                if let h = btn.constraints.first(where: { $0.firstAttribute == .height }) {
                    h.constant = 56
                } else {
                    btn.heightAnchor.constraint(equalToConstant: 56).isActive = true
                }
            } else {
                styleSaveButtonIfFound(root: sub)
            }
        }
    }

    private func setupTable() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
        tableView.tableFooterView = UIView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        emptyStateLabel = UILabel()
        emptyStateLabel.text = "No Sub-Services found"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.font = .systemFont(ofSize: 18)
        emptyStateLabel.textColor = UIColor(white: 0.45, alpha: 1)
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

        let containerView = UIView(frame: tableView.bounds)
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(emptyStateLabel)
        tableView.backgroundView = containerView

        NSLayoutConstraint.activate([
            emptyStateLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }

    private func updateEmptyState() {
        emptyStateLabel?.isHidden = !subServices.isEmpty
    }

    // MARK: - Close Button (robust)
    @IBAction func closeButtonTapped(_ sender: Any) {
        print("[ServiceAdding] close tapped. originTabIndex = \(String(describing: originTabIndex))")

        // If originTabIndex set, try to ensure that tab is selected and popped to root first
        if let idx = originTabIndex {
            if selectTabAndPopRoot(index: idx) {
                // then dismiss/pop current VC
                if presentingViewController != nil {
                    dismiss(animated: true, completion: nil)
                } else if let nav = navigationController {
                    nav.popViewController(animated: true)
                } else {
                    dismiss(animated: true, completion: nil)
                }
                return
            } else {
                print("[ServiceAdding] selectTabAndPopRoot failed — falling back.")
            }
        }

        // fallback
        if presentingViewController != nil {
            dismiss(animated: true, completion: nil)
            return
        }
        if let nav = navigationController {
            nav.popViewController(animated: true)
            return
        }
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Save Service
    @IBAction func saveServiceTapped(_ sender: Any) {
        let name = serviceTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else { return }

        let payload = ServiceCreatePayload(name: name, subservices: subServices)

        Task {
            do {
                let created = try await SupabaseManager.shared.createService(payload)
                print("✅ Created service id:", created.id)

                DispatchQueue.main.async {
                    let listVC = ServicesListViewController()
                    let nav = UINavigationController(rootViewController: listVC)
                    nav.modalPresentationStyle = .fullScreen

                    self.present(nav, animated: true) {
                        Task { await listVC.fetchAllServices() }
                    }
                }

            } catch {
                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: "Error Saving Service",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(.init(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - Add Subservice
    @IBAction func addButtonTapped(_ sender: Any) {
        let addVC = AddSubserviceViewController()
        addVC.modalPresentationStyle = .pageSheet

        if let sheet = addVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 22
        }

        addVC.onSave = { [weak self] (newSub: Subservice) in
            guard let self = self else { return }
            self.subServices.append(newSub)
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.updateEmptyState()
            }
        }

        present(addVC, animated: true)
    }

    // MARK: - Tab helpers (single implementations only)

    /// Selects desired tab and pops its navigation controller to root.
    /// Returns true if selection succeeded (UITabBarController found).
    private func selectTabAndPopRoot(index: Int) -> Bool {
        // Scene-safe key window lookup
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
        let keyWindow = windowScene?.windows.first { $0.isKeyWindow } ?? UIApplication.shared.windows.first { $0.isKeyWindow }
        guard let root = keyWindow?.rootViewController else {
            print("[ServiceAdding] No rootViewController found")
            return false
        }

        guard let tabBar = findTabBarController(from: root) else {
            print("[ServiceAdding] No UITabBarController found")
            return false
        }

        let safeIndex = max(0, min(index, (tabBar.viewControllers?.count ?? 1) - 1))
        print("[ServiceAdding] selecting tab index = \(safeIndex) (requested \(index))")

        tabBar.selectedIndex = safeIndex

        if let targetNav = tabBar.viewControllers?[safeIndex] as? UINavigationController {
            targetNav.popToRootViewController(animated: true)
        }

        return true
    }

    /// Recursive search for UITabBarController in view controller hierarchy
    private func findTabBarController(from vc: UIViewController) -> UITabBarController? {
        if let t = vc as? UITabBarController { return t }
        if let nav = vc as? UINavigationController {
            return findTabBarController(from: nav.viewControllers.first ?? nav)
        }
        if let presented = vc.presentedViewController {
            if let found = findTabBarController(from: presented) { return found }
        }
        for child in vc.children {
            if let found = findTabBarController(from: child) { return found }
        }
        return nil
    }
}

// MARK: - TableView
extension ServiceAddingViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        subServices.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = subServices[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = "\(item.name) — ₹\(Int(item.rate)) (\(item.unit))"
        content.image = item.image
        content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
        content.imageProperties.cornerRadius = 8
        cell.contentConfiguration = content

        let editButton = UIButton(type: .system)
        editButton.setImage(UIImage(systemName: "pencil.circle.fill"), for: .normal)
        editButton.tintColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        editButton.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        editButton.tag = indexPath.row
        editButton.addTarget(self, action: #selector(editButtonTapped(_:)), for: .touchUpInside)
        editButton.contentHorizontalAlignment = .center
        editButton.contentVerticalAlignment = .center
        cell.accessoryView = editButton
        cell.selectionStyle = .none

        return cell
    }

    @objc private func editButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        let editVC = EditSubserviceViewController()
        let item = subServices[index]
        editVC.subserviceToEdit = item
        editVC.parentServiceName = serviceTextField.text

        editVC.onSave = { [weak self] (updated: Subservice) in
            guard let self = self else { return }
            self.subServices[index] = updated
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }

        if let sheet = editVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 22
        }

        present(editVC, animated: true)
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            subServices.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

// MARK: - UITextField Padding Helper (file-local)
fileprivate extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: 1))
        leftView = paddingView
        leftViewMode = .always
    }
}

// MARK: - Local UI Helpers for ServiceAddingViewController (file-local)
fileprivate func makeLabel(_ text: String) -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = text
    label.font = .systemFont(ofSize: 20, weight: .semibold)
    label.textColor = .label
    return label
}

fileprivate func makeTextField(placeholder: String, keyboard: UIKeyboardType = .default) -> UITextField {
    let tf = UITextField()
    tf.translatesAutoresizingMaskIntoConstraints = false
    tf.keyboardType = keyboard
    tf.borderStyle = .roundedRect
    tf.layer.cornerRadius = 10
    tf.font = .systemFont(ofSize: 16)
    tf.backgroundColor = .white
    tf.clearButtonMode = .whileEditing
    let pad = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
    tf.leftView = pad
    tf.leftViewMode = .always
    tf.attributedPlaceholder = NSAttributedString(
        string: placeholder,
        attributes: [.foregroundColor: UIColor.systemGray, .font: UIFont.systemFont(ofSize: 15)]
    )
    return tf
}

fileprivate func makeActionButton(title: String, color: UIColor) -> UIButton {
    var config = UIButton.Configuration.filled()
    config.title = title
    config.baseBackgroundColor = color
    config.cornerStyle = .medium
    let button = UIButton(configuration: config)
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
}

fileprivate extension UITextField {
    func applyScreenStyle1(placeholder: String) {
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
