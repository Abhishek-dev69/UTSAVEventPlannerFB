import UIKit
import Supabase

final class ServicesListViewController: UIViewController {

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .plain)

    // MARK: - Data
    private var services: [Service] = [] {
        didSet { tableView.reloadData() }
    }

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
        // ONLY add button — no back, no save
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addServiceTapped)
        )
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
            }

        } catch {
            print("❌ Fetch services failed:", error)
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

