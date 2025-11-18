//
//  ServiceAddingViewController.swift
//  UTSAVEventPlanner
//
//  Programmatic UI (matches XIB screenshot) + full logic + keyboard safe area
//

import UIKit
import Supabase

final class ServiceAddingViewController: UIViewController {

    // MARK: - UI
    private let topBar = UIView()
    private let closeButton = UIButton(type: .system)
    private let headerTitle = UILabel()

    private let purpleCard = UIView()
    private let serviceTitleLabel = UILabel()
    private let serviceTextField = UITextField()

    private let subServicesLabel = UILabel()
    private let addButton = UIButton(type: .system)

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let saveButton = UIButton(type: .system)

    private var saveButtonBottomConstraint: NSLayoutConstraint!

    // MARK: - Data
    var subServices: [Subservice] = [] {
        didSet {
            tableView.reloadData()
            emptyStateLabel.isHidden = !subServices.isEmpty
        }
    }
    private let emptyStateLabel = UILabel()

    var onServiceSave: ((Service) -> Void)?
    var originTabIndex: Int?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        setupUI()
        setupConstraints()
        setupTable()
        setupInitialState()
        setupKeyboardObservers()
        setupTapToDismiss()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }


    // MARK: - Setup UI
    private func setupUI() {
        // ---------- TOP BAR ----------
        topBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topBar)

        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .black
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        topBar.addSubview(closeButton)

        headerTitle.text = "Create Service"
        headerTitle.font = .systemFont(ofSize: 20, weight: .semibold)
        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(headerTitle)

        // ---------- PURPLE CARD ----------
        purpleCard.backgroundColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        purpleCard.layer.cornerRadius = 10
        purpleCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(purpleCard)

        serviceTitleLabel.text = "Service Name"
        serviceTitleLabel.font = .systemFont(ofSize: 18, weight: .medium)
        serviceTitleLabel.textColor = .white
        serviceTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        purpleCard.addSubview(serviceTitleLabel)

        serviceTextField.placeholder = "Enter Service Name"
        serviceTextField.backgroundColor = .white
        serviceTextField.layer.cornerRadius = 10
        serviceTextField.font = .systemFont(ofSize: 16)
        serviceTextField.translatesAutoresizingMaskIntoConstraints = false
        serviceTextField.heightAnchor.constraint(equalToConstant: 46).isActive = true
        serviceTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        purpleCard.addSubview(serviceTextField)

        // ---------- SUBSERVICES ----------
        subServicesLabel.text = "Sub-Services"
        subServicesLabel.font = .boldSystemFont(ofSize: 18)
        subServicesLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subServicesLabel)

        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = .black
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        view.addSubview(addButton)

        // ---------- TABLE ----------
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        emptyStateLabel.text = "No Sub-Services found"
        emptyStateLabel.textColor = .systemGray
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.addSubview(emptyStateLabel)

        // ---------- SAVE BUTTON ----------
        saveButton.setTitle("Save Service", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        saveButton.layer.cornerRadius = 24
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        view.addSubview(saveButton)
    }


    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // TOP BAR
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 50),

            closeButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 20),
            closeButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),

            headerTitle.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            headerTitle.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),

            // PURPLE CARD
            purpleCard.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 10),
            purpleCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            purpleCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            purpleCard.heightAnchor.constraint(equalToConstant: 140),

            serviceTitleLabel.topAnchor.constraint(equalTo: purpleCard.topAnchor, constant: 12),
            serviceTitleLabel.centerXAnchor.constraint(equalTo: purpleCard.centerXAnchor),

            serviceTextField.topAnchor.constraint(equalTo: serviceTitleLabel.bottomAnchor, constant: 12),
            serviceTextField.leadingAnchor.constraint(equalTo: purpleCard.leadingAnchor, constant: 20),
            serviceTextField.trailingAnchor.constraint(equalTo: purpleCard.trailingAnchor, constant: -20),

            // SUBSERVICES
            subServicesLabel.topAnchor.constraint(equalTo: purpleCard.bottomAnchor, constant: 20),
            subServicesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            addButton.centerYAnchor.constraint(equalTo: subServicesLabel.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // TABLE
            tableView.topAnchor.constraint(equalTo: subServicesLabel.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),

            // SAVE BUTTON
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 150),
            saveButton.heightAnchor.constraint(equalToConstant: 46)
        ])

        // Save bottom constraint in variable
        saveButtonBottomConstraint =
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        saveButtonBottomConstraint.isActive = true

        tableView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -20).isActive = true
    }


    // MARK: - Table Setup
    private func setupTable() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableFooterView = UIView()
    }


    private func setupInitialState() {
        addButton.isEnabled = false
        addButton.alpha = 0.4
        emptyStateLabel.isHidden = !subServices.isEmpty
    }


    // MARK: - Keyboard Observers
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


    @objc private func keyboardWillShow(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }

        saveButtonBottomConstraint.constant = -(frame.height + 10)

        UIView.animate(withDuration: 0.28) { self.view.layoutIfNeeded() }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        saveButtonBottomConstraint.constant = -20

        UIView.animate(withDuration: 0.28) { self.view.layoutIfNeeded() }
    }


    // MARK: - Tap to dismiss keyboard
    private func setupTapToDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }


    // MARK: - Button Actions
    @objc private func textFieldChanged() {
        let hasText = !(serviceTextField.text ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        addButton.isEnabled = hasText
        addButton.alpha = hasText ? 1.0 : 0.4
    }

    @objc private func closeTapped() {
        if let idx = originTabIndex, selectTabAndPopRoot(index: idx) {
            if presentingViewController != nil {
                dismiss(animated: true)
            } else {
                navigationController?.popViewController(animated: true)
            }
            return
        }

        if presentingViewController != nil {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc private func addTapped() {
        let addVC = AddSubserviceViewController()
        addVC.modalPresentationStyle = .pageSheet

        if let sheet = addVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 22
        }

        addVC.onSave = { [weak self] newSub in
            guard let self = self else { return }
            self.subServices.append(newSub)
            self.emptyStateLabel.isHidden = !self.subServices.isEmpty
            self.tableView.reloadData()
        }

        present(addVC, animated: true)
    }

    @objc private func saveTapped() {
        let name = serviceTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else { return }

        let payload = ServiceCreatePayload(name: name, subservices: subServices)

        Task {
            do {
                let created = try await SupabaseManager.shared.createService(payload)
                print("✅ Created service id:", created.id)

                DispatchQueue.main.async {
                    self.onServiceSave?(Service(name: name, subservices: self.subServices))
                    let listVC = ServicesListViewController()
                    let nav = UINavigationController(rootViewController: listVC)
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true) {
                        Task { await listVC.fetchAllServices() }
                    }
                }

            } catch {
                let alert = UIAlertController(
                    title: "Error Saving Service",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alert.addAction(.init(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }


    // MARK: - Tab Helpers
    private func selectTabAndPopRoot(index: Int) -> Bool {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
        let keyWindow = windowScene?.windows.first { $0.isKeyWindow }

        guard let root = keyWindow?.rootViewController else { return false }
        guard let tabBar = findTabBarController(from: root) else { return false }

        let safeIndex = max(0, min(index, (tabBar.viewControllers?.count ?? 1) - 1))
        tabBar.selectedIndex = safeIndex
        (tabBar.viewControllers?[safeIndex] as? UINavigationController)?
            .popToRootViewController(animated: true)
        return true
    }

    private func findTabBarController(from vc: UIViewController) -> UITabBarController? {
        if let t = vc as? UITabBarController { return t }
        if let nav = vc as? UINavigationController { return findTabBarController(from: nav.viewControllers.first!) }
        if let presented = vc.presentedViewController { return findTabBarController(from: presented) }
        for child in vc.children { if let found = findTabBarController(from: child) { return found }}
        return nil
    }
}



// MARK: - TableView
extension ServiceAddingViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        subServices.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath)
    -> UITableViewCell {

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
        editButton.tag = indexPath.row
        editButton.addTarget(self, action: #selector(editButtonTapped(_:)), for: .touchUpInside)
        editButton.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        cell.accessoryView = editButton

        cell.selectionStyle = .none
        return cell
    }

    @objc private func editButtonTapped(_ sender: UIButton) {
        let idx = sender.tag
        let editVC = EditSubserviceViewController()
        editVC.subserviceToEdit = subServices[idx]
        editVC.parentServiceName = serviceTextField.text

        editVC.onSave = { [weak self] updated in
            self?.subServices[idx] = updated
            self?.tableView.reloadData()
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

