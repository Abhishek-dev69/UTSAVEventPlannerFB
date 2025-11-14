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

    // Call back to parent if they want updates (optional)
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

        // empty background view
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

    // MARK: - Actions
    @objc private func addTapped() {
        let addVC = AddSubserviceViewController()
        addVC.onSave = { [weak self] newSub in
            guard let self = self else { return }
            self.subservices.append(newSub)
            // notify parent
            self.onSubservicesChanged?(self.subservices)
        }

        // present as sheet (matches your app style)
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { subservices.count }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sub = subservices[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var cfg = cell.defaultContentConfiguration()
        cfg.text = sub.name
        cfg.secondaryText = "₹\(Int(sub.rate)) • \(sub.unit)"
        cfg.image = sub.image
        cfg.imageProperties.maximumSize = CGSize(width: 44, height: 44)
        cfg.imageProperties.cornerRadius = 8
        cell.contentConfiguration = cfg

        // accessory: edit button (reuse same pattern you used)
        let editButton = UIButton(type: .system)
        editButton.setImage(UIImage(systemName: "pencil.circle.fill"), for: .normal)
        editButton.tintColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        editButton.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        editButton.tag = indexPath.row
        editButton.addTarget(self, action: #selector(editTapped(_:)), for: .touchUpInside)
        cell.accessoryView = editButton

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // optional: treat row tap as edit too
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
        editVC.parentServiceName = service.name
        editVC.onSave = { [weak self] updated in
            guard let self = self else { return }
            self.subservices[index] = updated
            self.onSubservicesChanged?(self.subservices)
        }
        if let sheet = editVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 22
        }
        present(editVC, animated: true)
    }

    // allow delete
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            subservices.remove(at: indexPath.row)
            onSubservicesChanged?(subservices)
        }
    }
}
