import UIKit
import Supabase

final class ServiceAddingViewController: UIViewController {

    // MARK: - UI
    private let topBar = UIView()
    private let closeButton = UIButton(type: .system)
    private let headerTitle = UILabel()

    private let purpleCard = UIView()
    private let cardBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let cardTint = UIView()
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

        view.backgroundColor = UIColor(red: 244/255, green: 241/255, blue: 252/255, alpha: 1)

        setupUI()
        setupConstraints()
        setupTable()
        setupInitialState()
        setupKeyboardObservers()
        setupTapToDismiss()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Resize gradient layers
        if let barGrad = topBar.layer.sublayers?.first as? CAGradientLayer {
            barGrad.frame = topBar.bounds
        }
        if let saveGrad = saveButton.layer.sublayers?.first as? CAGradientLayer {
            saveGrad.frame = saveButton.bounds
        }

        let topY = subServicesLabel.frame.maxY
        let bottomY = saveButton.frame.minY
        guard bottomY > topY else {
            emptyStateCenterYConstraint.constant = 0
            return
        }
        let midpoint = (topY + bottomY) / 2.0
        let centerYSuper = view.bounds.midY
        emptyStateCenterYConstraint.constant = midpoint - centerYSuper
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
        let purple = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)
        let deepPurple = UIColor(red: 106/255, green: 31/255, blue: 208/255, alpha: 1)

        // ── Top bar ──────────────────────────────────────────────────────────
        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.clipsToBounds = false

        // Gradient fill for the top bar
        let barGrad = CAGradientLayer()
        barGrad.colors = [deepPurple.cgColor, purple.cgColor]
        barGrad.startPoint = CGPoint(x: 0, y: 0.5)
        barGrad.endPoint   = CGPoint(x: 1, y: 0.5)
        barGrad.cornerRadius = 0
        topBar.layer.insertSublayer(barGrad, at: 0)
        topBar.tag = 901   // used in viewDidLayoutSubviews to resize gradient
        view.addSubview(topBar)

        // Close button — white circle
        let closeCircle = UIView()
        closeCircle.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        closeCircle.layer.cornerRadius = 18
        closeCircle.translatesAutoresizingMaskIntoConstraints = false
        closeCircle.isUserInteractionEnabled = false
        topBar.addSubview(closeCircle)

        closeButton.setImage(
            UIImage(systemName: "xmark", withConfiguration:
                UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)),
            for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        topBar.addSubview(closeButton)

        headerTitle.text = "Create Service"
        headerTitle.font = .systemFont(ofSize: 18, weight: .bold)
        headerTitle.textColor = .white
        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        headerTitle.textAlignment = .center
        topBar.addSubview(headerTitle)

        // ── Service name card background (glass effect) ─────────────────────
        purpleCard.backgroundColor = .clear
        purpleCard.layer.cornerRadius = 20
        purpleCard.translatesAutoresizingMaskIntoConstraints = false
        purpleCard.layer.borderColor = purple.withAlphaComponent(0.20).cgColor
        purpleCard.layer.borderWidth  = 1
        purpleCard.layer.shadowColor  = purple.cgColor
        purpleCard.layer.shadowOpacity = 0.10
        purpleCard.layer.shadowRadius  = 14
        purpleCard.layer.shadowOffset  = CGSize(width: 0, height: 6)
        purpleCard.isUserInteractionEnabled = false // Background only
        view.addSubview(purpleCard)

        // Blur inside card
        cardBlur.layer.cornerRadius = 20
        cardBlur.clipsToBounds = true
        cardBlur.translatesAutoresizingMaskIntoConstraints = false
        cardBlur.isUserInteractionEnabled = false
        purpleCard.addSubview(cardBlur)

        // Tint inside card
        cardTint.backgroundColor = purple.withAlphaComponent(0.08)
        cardTint.layer.cornerRadius = 20
        cardTint.clipsToBounds = true
        cardTint.translatesAutoresizingMaskIntoConstraints = false
        cardTint.isUserInteractionEnabled = false
        purpleCard.addSubview(cardTint)

        // ── Service name label (Direct subview of view) ────────────────────
        serviceTitleLabel.text = "Service Name"
        serviceTitleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        serviceTitleLabel.textColor = purple
        serviceTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(serviceTitleLabel)

        // ── Service text field (Direct subview of view) ───────────────────
        let iconView = UIImageView(image: UIImage(systemName: "storefront.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)))
        iconView.tintColor = purple
        iconView.contentMode = .center
        iconView.frame = CGRect(x: 0, y: 0, width: 44, height: 52)

        serviceTextField.placeholder = "e.g. Photography, Decoration…"
        serviceTextField.backgroundColor = .white
        serviceTextField.textColor = .label
        serviceTextField.layer.cornerRadius = 14
        serviceTextField.layer.borderColor = purple.withAlphaComponent(0.20).cgColor
        serviceTextField.layer.borderWidth  = 1
        serviceTextField.font = .systemFont(ofSize: 16, weight: .medium)
        serviceTextField.translatesAutoresizingMaskIntoConstraints = false
        serviceTextField.heightAnchor.constraint(equalToConstant: 52).isActive = true
        serviceTextField.leftView  = iconView
        serviceTextField.leftViewMode = .always
        serviceTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        serviceTextField.autocapitalizationType = .words
        serviceTextField.returnKeyType   = .done
        serviceTextField.clearButtonMode = .whileEditing
        serviceTextField.isUserInteractionEnabled = true
        serviceTextField.layer.shadowColor   = purple.cgColor
        serviceTextField.layer.shadowOpacity = 0.06
        serviceTextField.layer.shadowRadius  = 8
        serviceTextField.layer.shadowOffset  = CGSize(width: 0, height: 3)
        view.addSubview(serviceTextField)
        view.bringSubviewToFront(serviceTextField)

        // ── Sub-Services header row ─────────────────────────────────────────
        subServicesLabel.text = "Sub-Services"
        subServicesLabel.font = .systemFont(ofSize: 16, weight: .bold)
        subServicesLabel.textColor = .label
        subServicesLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subServicesLabel)

        // Add button — pill shaped
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.backgroundColor = purple
        addButton.layer.cornerRadius = 18
        addButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        addButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
        let plusConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        addButton.setImage(UIImage(systemName: "plus", withConfiguration: plusConfig), for: .normal)
        addButton.setTitle(" Add", for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        addButton.tintColor  = .white
        addButton.setTitleColor(.white, for: .normal)
        addButton.layer.shadowColor   = purple.cgColor
        addButton.layer.shadowOpacity = 0.25
        addButton.layer.shadowRadius  = 8
        addButton.layer.shadowOffset  = CGSize(width: 0, height: 3)
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        view.addSubview(addButton)

        // ── Table view ──────────────────────────────────────────────────────
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        view.addSubview(tableView)

        // ── Empty state ─────────────────────────────────────────────────────
        view.addSubview(emptyStateLabel)
        emptyStateLabel.text = "Tap \"Add\" to create your first sub-service"
        emptyStateLabel.textColor = UIColor.secondaryLabel
        emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        emptyStateCenterYConstraint = emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        emptyStateCenterYConstraint.isActive = true
        emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20).isActive = true
        emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20).isActive = true

        // ── Save button — gradient full width ───────────────────────────────
        saveButton.setTitle("Save Service", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 26
        saveButton.clipsToBounds = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        let saveGrad = CAGradientLayer()
        saveGrad.colors  = [purple.cgColor, deepPurple.cgColor]
        saveGrad.startPoint = CGPoint(x: 0, y: 0.5)
        saveGrad.endPoint   = CGPoint(x: 1, y: 0.5)
        saveGrad.cornerRadius = 26
        saveButton.layer.insertSublayer(saveGrad, at: 0)
        saveButton.tag = 902  // for sizing in viewDidLayoutSubviews

        saveButton.layer.shadowColor   = purple.cgColor
        saveButton.layer.shadowOpacity = 0.35
        saveButton.layer.shadowRadius  = 14
        saveButton.layer.shadowOffset  = CGSize(width: 0, height: 6)
        view.addSubview(saveButton)

        // Store reference for gradient layer lookup
        view.tag = 900
    }

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Top bar — gradient header
            topBar.topAnchor.constraint(equalTo: view.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 64),

            closeButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16),
            closeButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor, constant: 4),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            headerTitle.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            headerTitle.centerYAnchor.constraint(equalTo: topBar.centerYAnchor, constant: 4),

            // Glass card BG
            purpleCard.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 16),
            purpleCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            purpleCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            purpleCard.bottomAnchor.constraint(equalTo: serviceTextField.bottomAnchor, constant: 16),

            cardBlur.topAnchor.constraint(equalTo: purpleCard.topAnchor),
            cardBlur.leadingAnchor.constraint(equalTo: purpleCard.leadingAnchor),
            cardBlur.trailingAnchor.constraint(equalTo: purpleCard.trailingAnchor),
            cardBlur.bottomAnchor.constraint(equalTo: purpleCard.bottomAnchor),

            cardTint.topAnchor.constraint(equalTo: purpleCard.topAnchor),
            cardTint.leadingAnchor.constraint(equalTo: purpleCard.leadingAnchor),
            cardTint.trailingAnchor.constraint(equalTo: purpleCard.trailingAnchor),
            cardTint.bottomAnchor.constraint(equalTo: purpleCard.bottomAnchor),

            // Foreground elements
            serviceTitleLabel.topAnchor.constraint(equalTo: purpleCard.topAnchor, constant: 16),
            serviceTitleLabel.leadingAnchor.constraint(equalTo: purpleCard.leadingAnchor, constant: 16),

            serviceTextField.topAnchor.constraint(equalTo: serviceTitleLabel.bottomAnchor, constant: 8),
            serviceTextField.leadingAnchor.constraint(equalTo: purpleCard.leadingAnchor, constant: 12),
            serviceTextField.trailingAnchor.constraint(equalTo: purpleCard.trailingAnchor, constant: -12),
            serviceTextField.bottomAnchor.constraint(equalTo: purpleCard.bottomAnchor, constant: -16),

            // Sub-services row
            subServicesLabel.topAnchor.constraint(equalTo: purpleCard.bottomAnchor, constant: 22),
            subServicesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            addButton.centerYAnchor.constraint(equalTo: subServicesLabel.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            subServicesLabel.trailingAnchor.constraint(lessThanOrEqualTo: addButton.leadingAnchor, constant: -12),

            // Table
            tableView.topAnchor.constraint(equalTo: subServicesLabel.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Save button — full width, floating above bottom
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 54)
        ])

        saveButtonBottomConstraint = saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        saveButtonBottomConstraint.isActive = true

        tableView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -14).isActive = true
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
        let name = serviceTextField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !name.isEmpty else { return }

        let payload = ServiceCreatePayload(
            name: name,
            subservices: subServices
        )

        Task {
            do {
                let created = try await SupabaseManager.shared.createService(payload)
                print("✅ Created service id:", created.id)

                DispatchQueue.main.async {
                    // 🔥 Notify parent
                    self.onServiceSave?(
                        Service(name: name, subservices: self.subServices)
                    )

                    // 🔥 Just dismiss — DO NOT present anything
                    self.dismiss(animated: true)
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
        cell.contentConfiguration = nil
        cell.subviews.filter { $0.tag == 777 }.forEach { $0.removeFromSuperview() }
        cell.backgroundColor = .clear
        cell.selectionStyle  = .none

        let item   = subServices[indexPath.row]
        let purple = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)

        // Card container
        let card = UIView()
        card.tag = 777
        card.backgroundColor = .white
        card.layer.cornerRadius = 14
        card.layer.shadowColor   = purple.cgColor
        card.layer.shadowOpacity = 0.07
        card.layer.shadowRadius  = 8
        card.layer.shadowOffset  = CGSize(width: 0, height: 3)
        card.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(card)

        // Purple left strip
        let strip = UIView()
        strip.backgroundColor = purple
        strip.layer.cornerRadius = 3
        strip.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(strip)

        // Name label
        let nameLabel = UILabel()
        nameLabel.text = item.name
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(nameLabel)

        // Pill amount badge
        let amountPill = UIView()
        amountPill.backgroundColor = purple.withAlphaComponent(0.10)
        amountPill.layer.cornerRadius = 12
        amountPill.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(amountPill)

        let amountLabel = UILabel()
        amountLabel.text = "₹\(Int(item.rate))"
        amountLabel.font = .systemFont(ofSize: 13, weight: .bold)
        amountLabel.textColor = purple
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountPill.addSubview(amountLabel)

        // Edit button
        let editButton = UIButton(type: .system)
        let pencilConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        editButton.setImage(UIImage(systemName: "pencil", withConfiguration: pencilConfig), for: .normal)
        editButton.tintColor = purple.withAlphaComponent(0.7)
        editButton.tag = indexPath.row
        editButton.addTarget(self, action: #selector(editButtonTapped(_:)), for: .touchUpInside)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(editButton)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 5),
            card.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -5),

            strip.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            strip.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            strip.widthAnchor.constraint(equalToConstant: 4),
            strip.heightAnchor.constraint(equalTo: card.heightAnchor, multiplier: 0.55),

            nameLabel.leadingAnchor.constraint(equalTo: strip.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            editButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            editButton.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            editButton.widthAnchor.constraint(equalToConstant: 30),
            editButton.heightAnchor.constraint(equalToConstant: 30),

            amountPill.trailingAnchor.constraint(equalTo: editButton.leadingAnchor, constant: -8),
            amountPill.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            amountLabel.topAnchor.constraint(equalTo: amountPill.topAnchor, constant: 5),
            amountLabel.bottomAnchor.constraint(equalTo: amountPill.bottomAnchor, constant: -5),
            amountLabel.leadingAnchor.constraint(equalTo: amountPill.leadingAnchor, constant: 10),
            amountLabel.trailingAnchor.constraint(equalTo: amountPill.trailingAnchor, constant: -10)
        ])

        return cell
    }

    @objc private func editButtonTapped(_ sender: UIButton) {
        let idx = sender.tag
        let editVC = EditSubserviceViewController()
        editVC.subserviceToEdit = subServices[idx]
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

