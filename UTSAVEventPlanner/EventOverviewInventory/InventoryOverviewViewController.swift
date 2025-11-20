import UIKit

final class InventoryOverviewViewController: UIViewController {

    private let event: EventRecord

    private var plannerItems: [InventoryItemRecord] = []
    private var vendorItems: [InventoryItemRecord] = []
    private var postEventItems: [InventoryItemRecord] = []

    private let segmented = UISegmentedControl(items: ["My Services", "Vendor", "Post-Event"])
    private let tableView = UITableView(frame: .zero, style: .plain)

    // MARK: Bottom Button (Only for Post-Event)
    private let bottomButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Mark as Received", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        btn.layer.cornerRadius = 22
        btn.isHidden = true
        return btn
    }()

    private var selectedPostEventItem: InventoryItemRecord?

    init(event: EventRecord) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("Use init(event:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupNav()

        // IMPORTANT: bottom button must be added BEFORE table view.
        setupBottomButton()
        setupSegment()
        setupTable()

        Task { await loadInventory() }
    }

    // MARK: Navigation Bar
    private func setupNav() {
        navigationItem.title = "Inventory Overview"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Add",
            style: .plain,
            target: self,
            action: #selector(addItem)
        )
    }

    // MARK: Segment Control
    private func setupSegment() {
        segmented.selectedSegmentIndex = 0
        segmented.translatesAutoresizingMaskIntoConstraints = false
        segmented.addTarget(self, action: #selector(segChanged), for: .valueChanged)
        view.addSubview(segmented)

        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            segmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmented.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    // MARK: Table
    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.register(InventoryListCell.self, forCellReuseIdentifier: "InventoryListCell")
        tableView.register(InventoryCheckboxCell.self, forCellReuseIdentifier: "InventoryCheckboxCell")
        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // table stays above bottom button
            tableView.bottomAnchor.constraint(equalTo: bottomButton.topAnchor, constant: -14)
        ])
    }

    // MARK: Bottom Button
    private func setupBottomButton() {
        bottomButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomButton)

        bottomButton.addTarget(self, action: #selector(receivedTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            bottomButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bottomButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bottomButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            bottomButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: Segment Changed
    @objc private func segChanged() {
        selectedPostEventItem = nil
        bottomButton.isHidden = true
        tableView.reloadData()
    }

    // MARK: Add New Item
    @objc private func addItem() {
        let vc = AddInventoryItemViewController(eventId: event.id)
        vc.onItemAdded = { [weak self] newItem in
            self?.appendAndReload(newItem)
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func appendAndReload(_ item: InventoryItemRecord) {
        let src = item.sourceType?.lowercased() ?? "planner"

        if src == "vendor" {
            vendorItems.append(item)
        } else {
            plannerItems.append(item)
        }

        postEventItems = plannerItems + vendorItems

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    // MARK: Load Items from DB
    private func loadInventory() async {
        do {
            let items = try await InventoryDataManager.shared.fetchInventory(eventId: event.id)

            plannerItems = items.filter { ($0.sourceType ?? "planner").lowercased() == "planner" }
            vendorItems = items.filter { ($0.sourceType ?? "").lowercased() == "vendor" }
            postEventItems = items

            await MainActor.run { tableView.reloadData() }

        } catch {
            print("Inventory load failed:", error)
        }
    }

    // MARK: Mark as Received
    @objc private func receivedTapped() {
        guard let item = selectedPostEventItem else { return }

        Task {
            do {
                try await InventoryDataManager.shared.deleteInventoryItem(itemId: item.id)

                postEventItems.removeAll { $0.id == item.id }

                await MainActor.run {
                    selectedPostEventItem = nil
                    bottomButton.isHidden = true
                    tableView.reloadData()
                }
            } catch {
                print("Error deleting:", error)
            }
        }
    }
}

// MARK: - TableView
extension InventoryOverviewViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {

        let count: Int

        switch segmented.selectedSegmentIndex {
        case 0: count = plannerItems.count
        case 1: count = vendorItems.count
        case 2: count = postEventItems.count
        default: count = 0
        }

        if count == 0 {
            let label = UILabel()
            label.text = "No inventory added yet"
            label.textColor = .gray
            label.textAlignment = .center
            tv.backgroundView = label
        } else {
            tv.backgroundView = nil
        }

        return count
    }

    func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch segmented.selectedSegmentIndex {

        case 0:
            let item = plannerItems[indexPath.row]
            let cell = tv.dequeueReusableCell(withIdentifier: "InventoryListCell", for: indexPath) as! InventoryListCell
            cell.configure(name: item.name, quantity: item.quantity)
            return cell

        case 1:
            let item = vendorItems[indexPath.row]
            let cell = tv.dequeueReusableCell(withIdentifier: "InventoryListCell", for: indexPath) as! InventoryListCell
            cell.configure(name: item.name, quantity: item.quantity)
            return cell

        case 2:
            let item = postEventItems[indexPath.row]
            let cell = tv.dequeueReusableCell(withIdentifier: "InventoryCheckboxCell", for: indexPath) as! InventoryCheckboxCell
            cell.configure(name: item.name, quantity: item.quantity)

            cell.onChecked = { [weak self] checked in
                if checked {
                    self?.selectedPostEventItem = item
                    self?.bottomButton.isHidden = false
                } else {
                    self?.selectedPostEventItem = nil
                    self?.bottomButton.isHidden = true
                }
            }

            return cell

        default:
            return UITableViewCell()
        }
    }
}

