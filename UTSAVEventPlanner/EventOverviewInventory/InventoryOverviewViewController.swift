import UIKit

final class InventoryOverviewViewController: UIViewController {

    private let event: EventRecord

    private var plannerItems: [InventoryItemRecord] = []
    private var vendorItems: [InventoryItemRecord] = []
    private var postEventItems: [InventoryItemRecord] = []

    private let segmented = UISegmentedControl(items: ["My Services", "Vendor", "Post-Event"])
    private let tableView = UITableView(frame: .zero, style: .plain)

    init(event: EventRecord) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("Use init(event:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupNav()
        setupSegment()
        setupTable()

        Task { await loadInventory() }
    }


    // MARK: UI Setup

    private func setupNav() {
        navigationItem.title = "Inventory Overview"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Add",
            style: .plain,
            target: self,
            action: #selector(addItem)
        )
    }

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
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }


    @objc private func segChanged() {
        tableView.reloadData()
    }


    // MARK: Add Item
    @objc private func addItem() {
        let vc = AddInventoryItemViewController(eventId: event.id)
        vc.onItemAdded = { [weak self] newItem in
            self?.appendAndReload(newItem)
        }
        navigationController?.pushViewController(vc, animated: true)
    }


    // MARK: Append new item
    private func appendAndReload(_ item: InventoryItemRecord) {

        let src = item.sourceType?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? "planner"

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


    // MARK: Load all inventory
    private func loadInventory() async {
        do {
            let items = try await InventoryDataManager.shared.fetchInventory(eventId: event.id)

            // Normalize source type
            plannerItems = items.filter {
                ($0.sourceType ?? "planner")
                    .lowercased()
                    .trimmingCharacters(in: .whitespacesAndNewlines) == "planner"
            }

            vendorItems = items.filter {
                ($0.sourceType ?? "")
                    .lowercased()
                    .trimmingCharacters(in: .whitespacesAndNewlines) == "vendor"
            }

            postEventItems = items

            await MainActor.run {
                tableView.reloadData()
            }

        } catch {
            print("Failed to load inventory:", error)
        }
    }
}


// MARK: - TableView
extension InventoryOverviewViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segmented.selectedSegmentIndex {
        case 0: return plannerItems.count
        case 1: return vendorItems.count
        case 2: return postEventItems.count
        default: return 0
        }
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
            return cell

        default:
            return UITableViewCell()
        }
    }
}

