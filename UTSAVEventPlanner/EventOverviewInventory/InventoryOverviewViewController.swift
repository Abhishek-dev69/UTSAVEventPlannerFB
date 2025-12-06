//
//  InventoryOverviewViewController.swift
//  Uses sourceType ("planner" / "vendor") only; shows source on cards and uses post-event rows.
//

import UIKit

final class InventoryOverviewViewController: UIViewController {

    private let event: EventRecord

    // inventory_items (allocated)
    private var plannerItems: [InventoryItemRecord] = []
    private var vendorItems: [InventoryItemRecord] = []
    private var lostDamagedItems: [InventoryItemRecord] = []

    // post-event: use PostEventRow (pending rows from vw_postevent_pending)
    private var postEventRows: [PostEventRow] = []

    // updated segments
    private let segmented = UISegmentedControl(items: ["Allocated", "Post-Event", "Lost/Damaged"])
    private let tableView = UITableView(frame: .zero, style: .plain)

    // bottom button kept for compatibility but unused in new per-row flow
    private let bottomButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Mark as Received", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        btn.layer.cornerRadius = 22
        btn.isHidden = true
        return btn
    }()

    // selected pending row (optional — not required by action-sheet flow)
    private var selectedPostEventRow: PostEventRow?

    init(event: EventRecord) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("Use init(event:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupNav()
        setupBottomButton()
        setupSegment()
        setupTable()

        Task {
            await loadInventory()
            await loadPostEventPending()
        }
    }

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
            tableView.bottomAnchor.constraint(equalTo: bottomButton.topAnchor, constant: -14)
        ])
    }

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

    @objc private func segChanged() {
        selectedPostEventRow = nil
        bottomButton.isHidden = true
        tableView.reloadData()
    }

    @objc private func addItem() {
        let vc = AddInventoryItemViewController(eventId: event.id)
        vc.onItemAdded = { [weak self] newItem in
            self?.appendAndReload(newItem)
            // Optionally refresh pending list if Add flow created a post-event row
            Task { await self?.loadPostEventPending() }
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func appendAndReload(_ item: InventoryItemRecord) {
        let src = (item.sourceType ?? "planner").lowercased()

        if src == "vendor" {
            vendorItems.append(item)
        } else {
            plannerItems.append(item)
        }

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    // Load allocated inventory_items
    private func loadInventory() async {
        do {
            let items = try await InventoryDataManager.shared.fetchInventory(eventId: event.id)

            // map only planner/vendor. If DB has "both" or other values, treat as planner by default.
            plannerItems = items.filter { (($0.sourceType ?? "planner").lowercased() == "planner") || (($0.sourceType ?? "").lowercased() != "vendor") }
            vendorItems = items.filter { ($0.sourceType ?? "").lowercased() == "vendor" }

            lostDamagedItems = [] // you can populate by querying inventory_postevent where state='lost'

            await MainActor.run { tableView.reloadData() }
        } catch {
            print("Inventory load failed:", error)
        }
    }

    // Load pending post-event rows using the view vw_postevent_pending
    private func loadPostEventPending() async {
        do {
            let rows = try await InventoryDataManager.shared.fetchPendingPostEventRows(eventId: event.id)
            await MainActor.run {
                self.postEventRows = rows
                self.tableView.reloadData()
            }
        } catch {
            print("Failed to load post-event pending:", error)
        }
    }

    // Bottom button action: kept but repurposed to mark selected pending row as received if you need bulk action
    @objc private func receivedTapped() {
        guard let row = selectedPostEventRow else { return }

        Task {
            do {
                try await InventoryDataManager.shared.markPostEventReceived(postEventId: row.posteventId, qty: row.postQty)
                await MainActor.run {
                    self.postEventRows.removeAll { $0.posteventId == row.posteventId }
                    self.selectedPostEventRow = nil
                    self.bottomButton.isHidden = true
                    self.tableView.reloadData()
                }
            } catch {
                print("Error marking received:", error)
            }
        }
    }
}

// MARK: - TableView
extension InventoryOverviewViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count: Int
        switch segmented.selectedSegmentIndex {
        case 0:
            // Allocated = planner + vendor combined
            count = plannerItems.count + vendorItems.count
            tv.backgroundView = (count == 0) ? {
                let label = UILabel()
                label.text = "No inventory added yet"
                label.textColor = .gray
                label.textAlignment = .center
                return label
            }() : nil
            return count

        case 1:
            count = postEventRows.count
            tv.backgroundView = (count == 0) ? {
                let label = UILabel()
                label.text = "No items in post-event"
                label.textColor = .gray
                label.textAlignment = .center
                return label
            }() : nil
            return count

        case 2:
            count = lostDamagedItems.count
            tv.backgroundView = (count == 0) ? {
                let label = UILabel()
                label.text = "No lost / damaged items"
                label.textColor = .gray
                label.textAlignment = .center
                return label
            }() : nil
            return count

        default:
            return 0
        }
    }

    func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch segmented.selectedSegmentIndex {

        case 0:
            // Allocated: combine planner then vendor
            let combined = plannerItems + vendorItems
            let item = combined[indexPath.row]
            let cell = tv.dequeueReusableCell(withIdentifier: "InventoryListCell", for: indexPath) as! InventoryListCell
            cell.configure(name: item.name, quantity: item.quantity, sourceType: item.sourceType)
            return cell

        case 1:
            let row = postEventRows[indexPath.row]
            let cell = tv.dequeueReusableCell(withIdentifier: "InventoryCheckboxCell", for: indexPath) as! InventoryCheckboxCell
            cell.configure(name: row.name, quantity: row.postQty, sourceType: row.sourceType)

            // When checkbox is checked -> show action sheet to choose Received or Lost
            cell.onChecked = { [weak self] checked in
                guard let self = self else { return }
                if checked {
                    // present actions for this pending row
                    self.presentPostEventAction(for: row, at: indexPath)
                } else {
                    // if unchecked we don't persist anything; reload row to ensure consistent UI
                    DispatchQueue.main.async {
                        self.tableView.reloadRows(at: [indexPath], with: .none)
                    }
                }
            }

            return cell

        case 2:
            let item = lostDamagedItems[indexPath.row]
            let cell = tv.dequeueReusableCell(withIdentifier: "InventoryListCell", for: indexPath) as! InventoryListCell
            cell.configure(name: item.name, quantity: item.quantity, sourceType: item.sourceType)
            return cell

        default:
            return UITableViewCell()
        }
    }

    // Optional: improve UX by deselecting rows on tap
    func tableView(_ tv: UITableView, didSelectRowAt indexPath: IndexPath) {
        tv.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Post-Event Actions
private extension InventoryOverviewViewController {

    func presentPostEventAction(for row: PostEventRow, at indexPath: IndexPath) {
        let ac = UIAlertController(title: row.name, message: "Select action for this item", preferredStyle: .actionSheet)

        ac.addAction(UIAlertAction(title: "Mark as Received", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            Task {
                do {
                    try await InventoryDataManager.shared.markPostEventReceived(postEventId: row.posteventId, qty: row.postQty)
                    await MainActor.run {
                        // remove only from pending list (Allocated remains unchanged)
                        self.postEventRows.removeAll { $0.posteventId == row.posteventId }
                        self.tableView.reloadData()
                    }
                } catch {
                    print("Failed to mark received:", error)
                    await MainActor.run { self.tableView.reloadRows(at: [indexPath], with: .none) }
                }
            }
        }))

        ac.addAction(UIAlertAction(title: "Mark as Lost / Damaged", style: .destructive, handler: { [weak self] _ in
            self?.presentLostNoteDialog(for: row, at: indexPath)
        }))

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
            // revert checkbox UI by reloading row
            DispatchQueue.main.async { self?.tableView.reloadRows(at: [indexPath], with: .none) }
        }))

        // For iPad safety
        if let pop = ac.popoverPresentationController, let cell = tableView.cellForRow(at: indexPath) {
            pop.sourceView = cell
            pop.sourceRect = cell.bounds
        }

        present(ac, animated: true)
    }

    func presentLostNoteDialog(for row: PostEventRow, at indexPath: IndexPath) {
        let ac = UIAlertController(title: "Lost / Damaged", message: "Add an optional note", preferredStyle: .alert)
        ac.addTextField { tf in tf.placeholder = "Note (optional)" }
        ac.addAction(UIAlertAction(title: "Confirm", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            let note = ac.textFields?.first?.text
            Task {
                do {
                    try await InventoryDataManager.shared.markPostEventLost(postEventId: row.posteventId, qty: row.postQty, note: note)
                    await MainActor.run {
                        // remove from pending
                        self.postEventRows.removeAll { $0.posteventId == row.posteventId }
                        self.tableView.reloadData()
                    }
                } catch {
                    print("Failed to mark lost:", error)
                    await MainActor.run { self.tableView.reloadRows(at: [indexPath], with: .none) }
                }
            }
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
            self?.tableView.reloadRows(at: [indexPath], with: .none)
        }))
        present(ac, animated: true)
    }
}

