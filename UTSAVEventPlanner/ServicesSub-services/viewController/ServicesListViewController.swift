import UIKit

final class ServicesListViewController: UIViewController {

    // MARK: - UI
    private let glassHeaderCard = UIView()
    private let blurView        = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let tintOverlay     = UIView()
    private let headerSeparator = UIView()

    private let titleLabel = UILabel()
    private let addButton  = UIButton(type: .system)
    private let tableView  = UITableView(frame: .zero, style: .plain)
    // MARK: - Empty State
    private let emptyStateStack = UIStackView()
    private let emptyIcon = UIImageView()
    private let emptyTitle = UILabel()
    private let emptySubtitle = UILabel()

    // MARK: - Data
    private var services: [Service] = []

    // bg layer
    private let bgGradientLayer = CAGradientLayer()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        applyBrandGradient()
        view.backgroundColor = .clear

        setupHeader()
        setupTableView()
        setupLayout()
        setupEmptyState()

        // ✅ 1. SHOW CACHED SERVICES INSTANTLY (offline-safe)
        if ServicesStore.shared.hasCache {
            self.services = ServicesStore.shared.services
            self.tableView.reloadData()
            updateEmptyState()
        }

        // ✅ 2. SYNC FROM SERVER IN BACKGROUND
        Task { await refreshFromServer() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)

        // 🔁 Always sync UI from cache
        self.services = ServicesStore.shared.services
        self.tableView.reloadData()
        updateEmptyState()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientFrame()
        if let grad = tintOverlay.layer.sublayers?.first as? CAGradientLayer {
            grad.frame = tintOverlay.bounds
        }
    }

    // MARK: - Header
    private func setupHeader() {
        let purple = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)

        glassHeaderCard.translatesAutoresizingMaskIntoConstraints = false
        glassHeaderCard.clipsToBounds = false
        glassHeaderCard.layer.shadowColor   = purple.cgColor
        glassHeaderCard.layer.shadowOpacity = 0.0 // Initially flat
        glassHeaderCard.layer.shadowRadius  = 12
        glassHeaderCard.layer.shadowOffset  = CGSize(width: 0, height: 4)
        view.addSubview(glassHeaderCard)

        blurView.clipsToBounds = true
        blurView.layer.cornerRadius = 20
        blurView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.alpha = 0 // Initially transparent
        glassHeaderCard.addSubview(blurView)

        tintOverlay.isUserInteractionEnabled = false
        tintOverlay.layer.cornerRadius = 20
        tintOverlay.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        tintOverlay.clipsToBounds = true
        tintOverlay.translatesAutoresizingMaskIntoConstraints = false
        tintOverlay.alpha = 0 // Initially transparent
        let grad = CAGradientLayer()
        grad.colors = [purple.withAlphaComponent(0.18).cgColor,
                       purple.withAlphaComponent(0.04).cgColor]
        grad.startPoint = CGPoint(x: 0.5, y: 0)
        grad.endPoint   = CGPoint(x: 0.5, y: 1)
        tintOverlay.layer.insertSublayer(grad, at: 0)
        glassHeaderCard.addSubview(tintOverlay)

        headerSeparator.backgroundColor = purple.withAlphaComponent(0.25)
        headerSeparator.alpha = 0
        headerSeparator.translatesAutoresizingMaskIntoConstraints = false
        glassHeaderCard.addSubview(headerSeparator)

        titleLabel.text = "Services"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        glassHeaderCard.addSubview(titleLabel)

        let plusConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        addButton.setImage(UIImage(systemName: "plus", withConfiguration: plusConfig), for: .normal)
        addButton.tintColor = purple
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addServiceTapped), for: .touchUpInside)
        glassHeaderCard.addSubview(addButton)

        let safeTop = view.safeAreaLayoutGuide.topAnchor
        NSLayoutConstraint.activate([
            glassHeaderCard.topAnchor.constraint(equalTo: view.topAnchor),
            glassHeaderCard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            glassHeaderCard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            glassHeaderCard.bottomAnchor.constraint(equalTo: safeTop, constant: 60),

            blurView.topAnchor.constraint(equalTo: glassHeaderCard.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: glassHeaderCard.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: glassHeaderCard.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor),

            tintOverlay.topAnchor.constraint(equalTo: glassHeaderCard.topAnchor),
            tintOverlay.leadingAnchor.constraint(equalTo: glassHeaderCard.leadingAnchor),
            tintOverlay.trailingAnchor.constraint(equalTo: glassHeaderCard.trailingAnchor),
            tintOverlay.bottomAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor),

            headerSeparator.leadingAnchor.constraint(equalTo: glassHeaderCard.leadingAnchor),
            headerSeparator.trailingAnchor.constraint(equalTo: glassHeaderCard.trailingAnchor),
            headerSeparator.bottomAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor),
            headerSeparator.heightAnchor.constraint(equalToConstant: 0.5),

            titleLabel.bottomAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor, constant: -16),
            titleLabel.centerXAnchor.constraint(equalTo: glassHeaderCard.centerXAnchor),

            addButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: glassHeaderCard.trailingAnchor, constant: -20),
            addButton.widthAnchor.constraint(equalToConstant: 24),
            addButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    // MARK: - Table
    private func setupTableView() {
        tableView.register(ServiceCell.self, forCellReuseIdentifier: ServiceCell.reuseID)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    private func setupEmptyState() {

        emptyStateStack.axis = .vertical
        emptyStateStack.spacing = 12
        emptyStateStack.alignment = .center
        emptyStateStack.translatesAutoresizingMaskIntoConstraints = false

        emptyIcon.image = UIImage(systemName: "shippingbox")
        emptyIcon.tintColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        emptyIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 40)

        emptyTitle.text = "No Services Yet"
        emptyTitle.font = .systemFont(ofSize: 20, weight: .semibold)
        emptyTitle.textColor = .darkGray

        emptySubtitle.text = "Tap + to add services like\nSound System, Decoration, Photography"
        emptySubtitle.font = .systemFont(ofSize: 15)
        emptySubtitle.textColor = .gray
        emptySubtitle.textAlignment = .center
        emptySubtitle.numberOfLines = 0

        emptyStateStack.addArrangedSubview(emptyIcon)
        emptyStateStack.addArrangedSubview(emptyTitle)
        emptyStateStack.addArrangedSubview(emptySubtitle)

        view.addSubview(emptyStateStack)

        NSLayoutConstraint.activate([
            emptyStateStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateStack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 40)
        ])
    }
    private func updateEmptyState() {

        let isEmpty = services.isEmpty

        emptyStateStack.isHidden = !isEmpty
        tableView.isHidden = isEmpty

        if isEmpty {
            startPlusAnimation()
        } else {
            addButton.layer.removeAllAnimations()
        }
    }
    private func startPlusAnimation() {

        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.duration = 0.8
        pulse.fromValue = 1.0
        pulse.toValue = 1.25
        pulse.autoreverses = true
        pulse.repeatCount = .infinity

        addButton.layer.add(pulse, forKey: "pulse")
    }

    // MARK: - Server Sync (BACKGROUND ONLY)
    private func refreshFromServer() async {
        do {
            let records = try await SupabaseManager.shared.fetchServices()
            let mapped = records.map { $0.toServiceModel() }

            await MainActor.run {
                // ✅ Update disk cache
                ServicesStore.shared.set(mapped)

                // ✅ Update UI
                self.services = mapped
                self.tableView.reloadData()
                updateEmptyState()
            }
        } catch {
            print("⚠️ Services sync failed (offline?):", error)
            // ❌ Do NOT clear UI — cached data remains visible
        }
    }

    // MARK: - Add Service
    @objc private func addServiceTapped() {
        let vc = ServiceAddingViewController()
        vc.modalPresentationStyle = .pageSheet

        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }

        vc.onServiceSave = { [weak self] newService in
            guard let self = self else { return }

            var updated = ServicesStore.shared.services
            updated.insert(newService, at: 0)

            ServicesStore.shared.set(updated)
            self.services = updated
            self.tableView.reloadData()
        }

        present(vc, animated: true)
    }

    // MARK: - Delete
    private func confirmDeleteService(at indexPath: IndexPath) {
        let service = services[indexPath.row]

        let alert = UIAlertController(
            title: "Delete Service?",
            message: "This will permanently delete '\(service.name)' and all its sub-services.",
            preferredStyle: .alert
        )

        alert.addAction(.init(title: "Cancel", style: .cancel))
        alert.addAction(.init(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteService(service, at: indexPath)
        })

        present(alert, animated: true)
    }

    private func deleteService(_ service: Service, at indexPath: IndexPath) {
        guard let id = service.id else { return }

        Task {
            do {
                try await SupabaseManager.shared.deleteService(serviceId: id)

                await MainActor.run {
                    self.services.remove(at: indexPath.row)
                    ServicesStore.shared.set(self.services)
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                }

            } catch {
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Delete Failed",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(.init(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

// MARK: - Table Delegate
extension ServicesListViewController: UITableViewDataSource, UITableViewDelegate {
    
    // Glass blur fades in on scroll
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        let progress = min(max((offset - 10) / 30, 0), 1)
        UIView.animate(withDuration: 0.1) {
            self.blurView.alpha = progress
            self.tintOverlay.alpha = progress
            self.headerSeparator.alpha = progress
            self.glassHeaderCard.layer.shadowOpacity = Float(progress * 0.08)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        services.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: ServiceCell.reuseID,
            for: indexPath
        )

        let svc = services[indexPath.row]
        var cfg = cell.defaultContentConfiguration()
        cfg.text = svc.name
        cfg.secondaryText = "\(svc.subservices.count) sub-services"
        cell.contentConfiguration = cfg
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {

        let delete = UIContextualAction(style: .destructive, title: "Delete") {
            [weak self] _, _, done in
            self?.confirmDeleteService(at: indexPath)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let svc = services[indexPath.row]
        let vc = SubservicesListViewController(service: svc)

        vc.onSubservicesChanged = { [weak self] updatedSubs in
            guard let self = self else { return }

            // 1️⃣ Update local UI state
            if let idx = self.services.firstIndex(where: { $0.id == svc.id }) {
                self.services[idx].subservices = updatedSubs
                self.tableView.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .none)
            }

            // 2️⃣ Update persistent cache
            var all = ServicesStore.shared.services
            if let idx = all.firstIndex(where: { $0.id == svc.id }) {
                all[idx].subservices = updatedSubs
                ServicesStore.shared.set(all)
            }
        }

        navigationController?.pushViewController(vc, animated: true)
    }
}

