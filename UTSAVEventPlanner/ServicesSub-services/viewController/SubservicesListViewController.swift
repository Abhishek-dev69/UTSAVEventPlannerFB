import UIKit

final class SubservicesListViewController: UIViewController {

    // MARK: - UI
    private let tableView = UITableView()
    private let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)

    // MARK: - Data
    private var service: Service
    private var subservices: [Subservice] {
        didSet {
            tableView.reloadData()
            updateEmptyState()
        }
    }

    // Notify parent when subservices change
    var onSubservicesChanged: (([Subservice]) -> Void)?

    // Empty state
    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "No sub-services"
        l.textAlignment = .center
        l.textColor = .secondaryLabel
        return l
    }()

    // MARK: - Init
    init(service: Service) {
        self.service = service
        self.subservices = service.subservices
        super.init(nibName: nil, bundle: nil)
        self.title = service.name
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTable()
        setupNavBar()
    }

    private func setupNavBar() {
        navigationItem.largeTitleDisplayMode = .never
        addButton.target = self
        addButton.action = #selector(addTapped)
        navigationItem.rightBarButtonItem = addButton
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()

        // Empty background view
        let container = UIView(frame: tableView.bounds)
        container.addSubview(emptyLabel)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        tableView.backgroundView = container

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        updateEmptyState()
    }

    private func updateEmptyState() {
        emptyLabel.isHidden = !subservices.isEmpty
    }

    // MARK: - Add Subservice
    @objc private func addTapped() {
        let addVC = AddSubserviceViewController()
        addVC.onSave = { [weak self] newSub in
            guard let self = self else { return }

            Task {
                do {
                    // Fetch latest service info to get correct id
                    let all = try await SupabaseManager.shared.fetchServices()
                    guard let svc = all.first(where: { $0.name == self.service.name }) else {
                        print("❌ Service not found for adding subservice.")
                        return
                    }

                    // Save to database
                    try await SupabaseManager.shared.addSubservice(serviceId: svc.id, sub: newSub)

                    // Update local list
                    self.subservices.append(newSub)

                    // Notify parent
                    self.onSubservicesChanged?(self.subservices)

                } catch {
                    print("❌ Failed to add subservice:", error)
                }
            }
        }

        addVC.modalPresentationStyle = .pageSheet
        if let sheet = addVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        present(addVC, animated: true)
    }
}


// MARK: - TableView
extension SubservicesListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subservices.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let sub = subservices[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        var cfg = cell.defaultContentConfiguration()
        cfg.text = sub.name
        cfg.secondaryText = "₹\(Int(sub.rate)) per unit"
        cfg.imageProperties.maximumSize = CGSize(width: 44, height: 44)
        cfg.imageProperties.cornerRadius = 8
        cell.contentConfiguration = cfg

        let editButton = UIButton(type: .system)
        // ---------- UPDATED: plain pencil (no circle) and purple tint ----------
        let pencilConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        editButton.setImage(UIImage(systemName: "pencil", withConfiguration: pencilConfig), for: .normal)
        editButton.tintColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        // --------------------------------------------------------------------
        editButton.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        editButton.tag = indexPath.row
        editButton.addTarget(self, action: #selector(editTapped(_:)), for: .touchUpInside)
        cell.accessoryView = editButton

        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)
        presentEdit(at: indexPath.row)
    }

    @objc private func editTapped(_ sender: UIButton) {
        presentEdit(at: sender.tag)
    }

    private func presentEdit(at index: Int) {
        let sub = subservices[index]
        let editVC = EditSubserviceViewController()
        editVC.subserviceToEdit = sub

        editVC.onSave = { [weak self] updated in
            guard let self = self else { return }

            Task {
                do {
                    // Get all services to find correct service/subservice id
                    let all = try await SupabaseManager.shared.fetchServices()
                    guard let svc = all.first(where: { $0.name == self.service.name }) else { return }
                    guard let subId = svc.subservices?.first(where: { $0.name == sub.name })?.id else {
                        print("❌ Subservice ID not found for update")
                        return
                    }

                    // Update DB
                    try await SupabaseManager.shared.updateSubservice(subId: subId, updated: updated)

                    // Update local array
                    self.subservices[index] = updated
                    self.onSubservicesChanged?(self.subservices)

                } catch {
                    print("❌ Failed to update subservice:", error)
                }
            }
        }

        if let sheet = editVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 22
        }
        present(editVC, animated: true)
    }

    // MARK: - Delete Subservice
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {
            let sub = subservices[indexPath.row]

            Task {
                do {
                    let all = try await SupabaseManager.shared.fetchServices()

                    guard let svc = all.first(where: { $0.name == self.service.name }) else {
                        print("❌ Service not found for delete")
                        return
                    }

                    guard let subId = svc.subservices?
                            .first(where: { $0.name == sub.name })?
                            .id else {
                        print("❌ Subservice ID not found for delete")
                        return
                    }

                    try await SupabaseManager.shared.deleteSubservice(subId: subId)

                    subservices.remove(at: indexPath.row)
                    onSubservicesChanged?(subservices)

                } catch {
                    print("❌ Failed to delete subservice:", error)
                }
            }
        }
    }
}

