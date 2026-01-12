import UIKit
import Supabase

final class ServicesListViewController: UIViewController {

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .plain)

    // MARK: - Data
    private var services: [Service] = []
    
    private let addButton = UIButton(type: .system)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Services"

        setupNavBar()
        setupTableView()
        setupLayout()

        Task { await fetchAllServices() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await fetchAllServices() }
    }

    // MARK: - Navigation Bar
    private func setupNavBar() {
        navigationItem.title = "Services"

        let plusConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        addButton.setImage(
            UIImage(systemName: "plus", withConfiguration: plusConfig),
            for: .normal
        )
        addButton.tintColor = UIColor(
            red: 138/255,
            green: 73/255,
            blue: 246/255,
            alpha: 1
        )

        addButton.addTarget(self, action: #selector(addServiceTapped), for: .touchUpInside)

        // wrap inside UIBarButtonItem (NO background, NO circle)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addButton)
    }
    // MARK: - TableView
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ServiceCell.self, forCellReuseIdentifier: ServiceCell.reuseID)
        tableView.separatorStyle = .singleLine
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Fetch Services
    func fetchAllServices() async {
        do {
            let records = try await SupabaseManager.shared.fetchServices()

            let mapped: [Service] = records.map { rec in
                let subs = (rec.subservices ?? []).map {
                    Subservice(
                        id: $0.id,
                        name: $0.name,
                        rate: $0.rate,
                        unit: $0.unit,
                        image: nil,
                        isFixed: true
                    )
                }
                return Service(
                    id: rec.id,
                    name: rec.name,
                    subservices: subs
                )
            }

            await MainActor.run {
                self.services = mapped
                self.tableView.reloadData()   // ✅ THIS WAS MISSING
            }

        } catch {
            print("❌ Fetch services failed:", error)
        }
    }
    private func confirmDeleteService(at indexPath: IndexPath) {
        let service = services[indexPath.row]

        let alert = UIAlertController(
            title: "Delete Service?",
            message: "This will permanently delete '\(service.name)' and all its sub-services.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(
            title: "Delete",
            style: .destructive,
            handler: { [weak self] _ in
                self?.deleteService(service, at: indexPath)
            }
        ))

        present(alert, animated: true)
    }
    private func deleteService(_ service: Service, at indexPath: IndexPath) {
        guard let serviceId = service.id else { return }

        Task {
            do {
                // 🔥 Delete from Supabase
                try await SupabaseManager.shared.deleteService(serviceId: serviceId)

                // 🔥 Update UI on main thread
                await MainActor.run {
                    self.services.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                }

            } catch {
                await MainActor.run {
                    let err = UIAlertController(
                        title: "Delete Failed",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    err.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(err, animated: true)
                }
            }
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

        vc.onServiceSave = { [weak self] _ in
            Task { await self?.fetchAllServices() }
        }

        present(vc, animated: true)
    }
}

// MARK: - UITableView Delegate & DataSource
extension ServicesListViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        services.count
    }
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {

        let deleteAction = UIContextualAction(
            style: .destructive,
            title: "Delete"
        ) { [weak self] _, _, completion in
            self?.confirmDeleteService(at: indexPath)
            completion(true)
        }

        deleteAction.backgroundColor = .systemRed
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: ServiceCell.reuseID,
            for: indexPath
        )

        let svc = services[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = svc.name
        config.secondaryText = "\(svc.subservices.count) sub-services"
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let svc = services[indexPath.row]
        let vc = SubservicesListViewController(service: svc)

        vc.onSubservicesChanged = { [weak self] _ in
            Task { await self?.fetchAllServices() }
        }

        navigationController?.pushViewController(vc, animated: true)
    }
}

