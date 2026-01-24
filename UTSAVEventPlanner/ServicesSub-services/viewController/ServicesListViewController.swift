import UIKit

final class ServicesListViewController: UIViewController {

    // MARK: - UI
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let addButton = UIButton(type: .system)
    private let tableView = UITableView(frame: .zero, style: .plain)

    // MARK: - Data
    private var services: [Service] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)

        setupHeader()
        setupTableView()
        setupLayout()

        // ✅ 1. SHOW CACHED SERVICES INSTANTLY (offline-safe)
        if ServicesStore.shared.hasCache {
            self.services = ServicesStore.shared.services
            self.tableView.reloadData()
        }

        // ✅ 2. SYNC FROM SERVER IN BACKGROUND
        Task { await refreshFromServer() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    // MARK: - Header
    private func setupHeader() {
        headerView.backgroundColor = UIColor(white: 0.97, alpha: 1)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        titleLabel.text = "Services"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let plusConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        addButton.setImage(UIImage(systemName: "plus", withConfiguration: plusConfig), for: .normal)
        addButton.tintColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addServiceTapped), for: .touchUpInside)

        headerView.addSubview(titleLabel)
        headerView.addSubview(addButton)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 120),

            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),

            addButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
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
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
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

        vc.onSubservicesChanged = { updatedSubs in
            var all = ServicesStore.shared.services
            if let idx = all.firstIndex(where: { $0.id == svc.id }) {
                all[idx].subservices = updatedSubs
                ServicesStore.shared.set(all)
            }
        }

        navigationController?.pushViewController(vc, animated: true)
    }
}

