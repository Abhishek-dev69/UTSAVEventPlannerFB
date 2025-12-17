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
            updateEmptyStateVisibility()
        }
    }

    // Empty state label is a subview of the main view and will be positioned
    // dynamically between subServicesLabel bottom and saveButton top.
    private let emptyStateLabel: UILabel = {
        let l = UILabel()
        l.text = "No Sub-Services found"
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 15)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // centerY constraint for emptyStateLabel — updated in viewDidLayoutSubviews
    private var emptyStateCenterYConstraint: NSLayoutConstraint!

    var onServiceSave: ((Service) -> Void)?
    var originTabIndex: Int?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGroupedBackground

        setupUI()
        setupConstraints()
        setupTable()
        setupInitialState()
        setupKeyboardObservers()
        setupTapToDismiss()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Recompute the vertical midpoint between subServicesLabel.bottom and saveButton.top,
        // then update the centerY constraint constant to place the emptyStateLabel there.
        // Only do this when both frames are available.
        let topY = subServicesLabel.frame.maxY
        let bottomY = saveButton.frame.minY

        // In some layout states bottomY might be <= topY (very small screen or animation), guard:
        guard bottomY > topY else {
            emptyStateCenterYConstraint.constant = 0
            return
        }

        let midpoint = (topY + bottomY) / 2.0
        // convert midpoint (in view coordinates) to a constant relative to view.centerYAnchor
        let centerYSuper = view.bounds.midY
        let constant = midpoint - centerYSuper

        emptyStateCenterYConstraint.constant = constant
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
        // Top bar
        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.backgroundColor = .clear
        view.addSubview(topBar)

        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .label
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.accessibilityLabel = "Close"
        topBar.addSubview(closeButton)

        headerTitle.text = "Create Service"
        headerTitle.font = .systemFont(ofSize: 20, weight: .semibold)
        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        headerTitle.textAlignment = .center
        headerTitle.accessibilityTraits = .header
        topBar.addSubview(headerTitle)

        // Purple card
        purpleCard.backgroundColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        purpleCard.layer.cornerRadius = 12
        purpleCard.layer.masksToBounds = false
        purpleCard.translatesAutoresizingMaskIntoConstraints = false
        purpleCard.layer.shadowColor = UIColor.black.cgColor
        purpleCard.layer.shadowOpacity = 0.08
        purpleCard.layer.shadowOffset = CGSize(width: 0, height: 8)
        purpleCard.layer.shadowRadius = 16
        view.addSubview(purpleCard)

        serviceTitleLabel.text = "Service Name"
        serviceTitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        serviceTitleLabel.textColor = .white
        serviceTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        purpleCard.addSubview(serviceTitleLabel)

        // Service text field
        serviceTextField.placeholder = "Enter service name"
        serviceTextField.backgroundColor = .white
        serviceTextField.layer.cornerRadius = 10
        serviceTextField.font = .systemFont(ofSize: 16)
        serviceTextField.translatesAutoresizingMaskIntoConstraints = false
        serviceTextField.heightAnchor.constraint(equalToConstant: 48).isActive = true
        serviceTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        serviceTextField.autocapitalizationType = .words
        serviceTextField.returnKeyType = .done
        serviceTextField.clearButtonMode = .whileEditing
        serviceTextField.textAlignment = .natural
        serviceTextField.accessibilityLabel = "Service name"
        serviceTextField.isUserInteractionEnabled = true

        let leftPadding = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 48))
        serviceTextField.leftView = leftPadding
        serviceTextField.leftViewMode = .always

        purpleCard.addSubview(serviceTextField)

        // Sub-services label + add button
        subServicesLabel.text = "Sub-Services"
        subServicesLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        subServicesLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subServicesLabel)

        // Configure addButton as circular and centered plus
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.backgroundColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        addButton.layer.cornerRadius = 20 // half of width/height (40)
        addButton.layer.masksToBounds = true
        addButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        addButton.heightAnchor.constraint(equalToConstant: 40).isActive = true

        // Use bold plus symbol sized appropriately
        let plusConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        let plusImage = UIImage(systemName: "plus", withConfiguration: plusConfig)
        addButton.setImage(plusImage, for: .normal)
        addButton.tintColor = .white
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        addButton.accessibilityLabel = "Add sub-service"
        view.addSubview(addButton)

        // Table view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear // show grouped background
        tableView.layer.cornerRadius = 8
        tableView.layer.masksToBounds = true
        view.addSubview(tableView)

        // Empty state label (as a subview of the main view)
        view.addSubview(emptyStateLabel)
        // centerX constraint
        emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        // centerY constraint — store and update in viewDidLayoutSubviews
        emptyStateCenterYConstraint = emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        emptyStateCenterYConstraint.isActive = true
        // width constraints to avoid overflow
        emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20).isActive = true
        emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20).isActive = true

        // Save button
        saveButton.setTitle("Save Service", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        saveButton.layer.cornerRadius = 28
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.layer.shadowColor = UIColor.black.cgColor
        saveButton.layer.shadowOpacity = 0.12
        saveButton.layer.shadowOffset = CGSize(width: 0, height: 8)
        saveButton.layer.shadowRadius = 16
        view.addSubview(saveButton)
    }

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Top bar
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 56),

            closeButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16),
            closeButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            headerTitle.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            headerTitle.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),

            // Purple card
            purpleCard.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 12),
            purpleCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            purpleCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            purpleCard.heightAnchor.constraint(equalToConstant: 160),

            // Title set higher inside card and centered horizontally
            serviceTitleLabel.topAnchor.constraint(equalTo: purpleCard.topAnchor, constant: 20),
            serviceTitleLabel.centerXAnchor.constraint(equalTo: purpleCard.centerXAnchor),

            // Larger gap between title and text field
            serviceTextField.topAnchor.constraint(equalTo: serviceTitleLabel.bottomAnchor, constant: 20),
            serviceTextField.leadingAnchor.constraint(equalTo: purpleCard.leadingAnchor, constant: 16),
            serviceTextField.trailingAnchor.constraint(equalTo: purpleCard.trailingAnchor, constant: -16),

            // Sub-services row
            subServicesLabel.topAnchor.constraint(equalTo: purpleCard.bottomAnchor, constant: 20),
            subServicesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            addButton.centerYAnchor.constraint(equalTo: subServicesLabel.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            subServicesLabel.trailingAnchor.constraint(lessThanOrEqualTo: addButton.leadingAnchor, constant: -12),

            // Table
            tableView.topAnchor.constraint(equalTo: subServicesLabel.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            // Save button
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 300),
            saveButton.heightAnchor.constraint(equalToConstant: 54)
        ])

        saveButtonBottomConstraint = saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        saveButtonBottomConstraint.isActive = true

        tableView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -18).isActive = true
    }

    // MARK: - Table Setup
    private func setupTable() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableFooterView = UIView()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 16)
        tableView.rowHeight = 68
        tableView.keyboardDismissMode = .interactive

        updateEmptyStateVisibility()
    }

    private func setupInitialState() {
        addButton.isEnabled = false
        addButton.alpha = 0.4
        updateEmptyStateVisibility()
    }

    private func updateEmptyStateVisibility() {
        // show/hide the centered label depending on data
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

        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.28
        saveButtonBottomConstraint.constant = -(frame.height + 10)
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.28
        saveButtonBottomConstraint.constant = -30
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    // MARK: - Tap to dismiss
    private func setupTapToDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    // MARK: - Actions
    @objc private func textFieldChanged() {
        let hasText = !(serviceTextField.text ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        addButton.isEnabled = hasText
        addButton.alpha = hasText ? 1.0 : 0.4
    }

    @objc private func closeTapped() {
        if let idx = originTabIndex, selectTabAndPopRoot(index: idx) {
            if presentingViewController != nil { dismiss(animated: true) } else { navigationController?.popViewController(animated: true) }
            return
        }
        if presentingViewController != nil { dismiss(animated: true) } else { navigationController?.popViewController(animated: true) }
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
            self.updateEmptyStateVisibility()
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
                    self.present(nav, animated: true) { Task { await listVC.fetchAllServices() } }
                }
            } catch {
                let alert = UIAlertController(title: "Error Saving Service", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(.init(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }

    // MARK: - Tab helpers
    private func selectTabAndPopRoot(index: Int) -> Bool {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
        let keyWindow = windowScene?.windows.first { $0.isKeyWindow }
        guard let root = keyWindow?.rootViewController else { return false }
        guard let tabBar = findTabBarController(from: root) else { return false }
        let safeIndex = max(0, min(index, (tabBar.viewControllers?.count ?? 1) - 1))
        tabBar.selectedIndex = safeIndex
        (tabBar.viewControllers?[safeIndex] as? UINavigationController)?.popToRootViewController(animated: true)
        return true
    }

    private func findTabBarController(from vc: UIViewController) -> UITabBarController? {
        if let t = vc as? UITabBarController { return t }
        if let nav = vc as? UINavigationController { return findTabBarController(from: nav.viewControllers.first!) }
        if let presented = vc.presentedViewController { return findTabBarController(from: presented) }
        for child in vc.children { if let found = findTabBarController(from: child) { return found } }
        return nil
    }
}

// MARK: - TableView
extension ServiceAddingViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { subServices.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = subServices[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = "\(item.name) — ₹\(Int(item.rate)) (\(item.unit))"
        content.image = item.image
        content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
        content.imageProperties.cornerRadius = 8
        content.secondaryTextProperties.font = .systemFont(ofSize: 12)
        cell.contentConfiguration = content

        let editButton = UIButton(type: .system)
        // --- UPDATED: Use plain pencil (bold) without circle background ---
        let pencilConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        editButton.setImage(UIImage(systemName: "pencil", withConfiguration: pencilConfig), for: .normal)
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

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            subServices.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

