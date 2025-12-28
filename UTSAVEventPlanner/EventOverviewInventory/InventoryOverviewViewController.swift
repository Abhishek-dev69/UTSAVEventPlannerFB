//
//  InventoryOverviewViewController.swift
//  Post-event: support partial qty Received / Lost and Lost/Damaged list
//

import UIKit

final class InventoryOverviewViewController: UIViewController {

    private let event: EventRecord

    // inventory_items (allocated)
    private var plannerItems: [InventoryItemRecord] = []
    private var vendorItems: [InventoryItemRecord] = []

    // post-event: use PostEventRow (pending rows from vw_postevent_pending)
    private var postEventRows: [PostEventRow] = []

    // lost/damaged: server-backed list (fetched from inventory_postevent where state='lost')
    private var lostDamagedRows: [PostEventRow] = []

    // updated segments
    private let segmented = UISegmentedControl(items: ["Allocated", "Post-Event", "Lost/Damaged"])
    private let tableView = UITableView(frame: .zero, style: .plain)

    // bottom button kept for compatibility (bulk action) but not used for single-row flow
    private let bottomButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Mark as Received", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        btn.layer.cornerRadius = 22
        btn.isHidden = true
        return btn
    }()

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
            await loadLostRows()
        }
    }

    private func setupNav() {
        // ✅ Show event name as title
        navigationItem.title = event.eventName
        navigationItem.largeTitleDisplayMode = .never

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
        // optionally load lost rows only when switching to that segment:
        if segmented.selectedSegmentIndex == 2 {
            Task { await loadLostRows() }
        }
        tableView.reloadData()
    }

    @objc private func addItem() {
        let vc = AddInventoryItemViewController(eventId: event.id)
        vc.onItemAdded = { [weak self] newItem in
            self?.appendAndReload(newItem)
            Task {
                await self?.loadPostEventPending()
                await self?.loadLostRows()
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func appendAndReload(_ item: InventoryItemRecord) {
        let src = (item.sourceType ?? "planner").lowercased()
        if src == "vendor" { vendorItems.append(item) } else { plannerItems.append(item) }
        DispatchQueue.main.async { self.tableView.reloadData() }
    }

    // Load allocated inventory_items
    private func loadInventory() async {
        do {
            let items = try await InventoryDataManager.shared.fetchInventory(eventId: event.id)
            plannerItems = items.filter { (($0.sourceType ?? "planner").lowercased() == "planner") || (($0.sourceType ?? "").lowercased() != "vendor") }
            vendorItems = items.filter { ($0.sourceType ?? "").lowercased() == "vendor" }
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

    // Load lost/damaged rows from server
    private func loadLostRows() async {
        do {
            let rows = try await InventoryDataManager.shared.fetchLostPostEventRows(eventId: event.id)
            await MainActor.run {
                self.lostDamagedRows = rows
                self.tableView.reloadData()
            }
        } catch {
            print("Failed to load lost rows:", error)
        }
    }

    // Bottom button action: mark selected pending row as received for bulk use (not used by per-row flow)
    @objc private func receivedTapped() {
        // kept for compatibility; not required for per-row actions
    }
}

// MARK: - TableView
extension InventoryOverviewViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segmented.selectedSegmentIndex {
        case 0:
            let count = plannerItems.count + vendorItems.count
            tv.backgroundView = (count == 0) ? {
                let label = UILabel()
                label.text = "No inventory added yet"
                label.textColor = .gray
                label.textAlignment = .center
                return label
            }() : nil
            return count

        case 1:
            let count = postEventRows.count
            tv.backgroundView = (count == 0) ? {
                let label = UILabel()
                label.text = "No items in post-event"
                label.textColor = .gray
                label.textAlignment = .center
                return label
            }() : nil
            return count

        case 2:
            let count = lostDamagedRows.count
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
            let combined = plannerItems + vendorItems
            let item = combined[indexPath.row]
            let cell = tv.dequeueReusableCell(withIdentifier: "InventoryListCell", for: indexPath) as! InventoryListCell
            cell.configure(name: item.name, quantity: item.quantity, sourceType: item.sourceType)
            return cell

        case 1:
            let row = postEventRows[indexPath.row]
            let cell = tv.dequeueReusableCell(withIdentifier: "InventoryCheckboxCell", for: indexPath) as! InventoryCheckboxCell
            cell.configure(name: row.name, quantity: row.postQty, sourceType: row.sourceType)

            // When checkbox checked -> present actions (quantity selection included)
            cell.onChecked = { [weak self] checked in
                guard let self = self else { return }
                if checked {
                    self.presentPostEventAction(for: row, at: indexPath)
                } else {
                    // Unchecked: restore UI state by reloading
                    DispatchQueue.main.async { self.tableView.reloadRows(at: [indexPath], with: .none) }
                }
            }
            return cell

        case 2:
            let lost = lostDamagedRows[indexPath.row]
            let cell = tv.dequeueReusableCell(withIdentifier: "InventoryListCell", for: indexPath) as! InventoryListCell
            // Use name and postQty to show lost qty
            cell.configure(name: lost.name, quantity: lost.postQty, sourceType: lost.sourceType)
            return cell

        default:
            return UITableViewCell()
        }
    }

    // UX: deselect row on tap
    func tableView(_ tv: UITableView, didSelectRowAt indexPath: IndexPath) {
        tv.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Post-Event Actions (with partial-qty support)
private extension InventoryOverviewViewController {

    /// Present action sheet for a pending post-event row (Received / Lost). Quantity prompt included.
    func presentPostEventAction(for row: PostEventRow, at indexPath: IndexPath) {
        let ac = UIAlertController(title: row.name, message: "Choose action for the pending quantity (Qty: \(row.postQty))", preferredStyle: .actionSheet)

        ac.addAction(UIAlertAction(title: "Mark as Received", style: .default, handler: { [weak self] _ in
            self?.presentQuantityPrompt(for: row, maxQty: row.postQty, action: .received, at: indexPath)
        }))

        ac.addAction(UIAlertAction(title: "Mark as Lost / Damaged", style: .destructive, handler: { [weak self] _ in
            self?.presentQuantityPrompt(for: row, maxQty: row.postQty, action: .lost, at: indexPath)
        }))

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
            DispatchQueue.main.async { self?.tableView.reloadRows(at: [indexPath], with: .none) }
        }))

        if let pop = ac.popoverPresentationController, let cell = tableView.cellForRow(at: indexPath) {
            pop.sourceView = cell
            pop.sourceRect = cell.bounds
        }

        present(ac, animated: true)
    }

    enum PostEventAction { case received, lost }

    /// Ask user how many units to mark (1...maxQty). on confirm, call RPC and update local lists.
    func presentQuantityPrompt(for row: PostEventRow, maxQty: Int, action: PostEventAction, at indexPath: IndexPath) {
        let title = (action == .received) ? "Mark Received" : "Mark Lost / Damaged"
        let ac = UIAlertController(title: title, message: "Enter quantity (1 - \(maxQty))", preferredStyle: .alert)
        ac.addTextField { tf in
            tf.keyboardType = .numberPad
            tf.text = "\(maxQty)" // prefill with max
        }

        ac.addAction(UIAlertAction(title: "Confirm", style: action == .lost ? .destructive : .default, handler: { [weak self] _ in
            guard let self = self else { return }
            guard let text = ac.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), let qty = Int(text), qty >= 1, qty <= maxQty else {
                // invalid input -> show quick alert and keep the row UI consistent
                let err = UIAlertController(title: "Invalid quantity", message: "Please enter a number between 1 and \(maxQty).", preferredStyle: .alert)
                err.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    DispatchQueue.main.async { self.tableView.reloadRows(at: [indexPath], with: .none) }
                })
                self.present(err, animated: true)
                return
            }

            Task {
                await self.performPostEventAction(row: row, qty: qty, action: action, at: indexPath)
            }
        }))

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
            DispatchQueue.main.async { self?.tableView.reloadRows(at: [indexPath], with: .none) }
        }))

        present(ac, animated: true)
    }

    /// Perform RPC and update local lists/UI accordingly (partial qty supported).
    func performPostEventAction(row: PostEventRow, qty: Int, action: PostEventAction, at indexPath: IndexPath) async {
        switch action {
        case .received:
            do {
                try await InventoryDataManager.shared.markPostEventReceived(postEventId: row.posteventId, qty: qty)

                // authoritative refresh: re-fetch pending and lost rows and inventory
                await loadPostEventPending()
                await loadLostRows()
                Task { await self.loadInventory() }

                await MainActor.run { self.tableView.reloadData() }

            } catch {
                print("Failed to mark received:", error)
                await MainActor.run { self.tableView.reloadRows(at: [indexPath], with: .none) }
            }

        case .lost:
            do {
                try await InventoryDataManager.shared.markPostEventLost(postEventId: row.posteventId, qty: qty, note: nil)

                // authoritative refresh: re-fetch pending and lost rows and inventory
                await loadPostEventPending()
                await loadLostRows()
                Task { await self.loadInventory() }

                await MainActor.run { self.tableView.reloadData() }

            } catch {
                print("Failed to mark lost:", error)
                await MainActor.run { self.tableView.reloadRows(at: [indexPath], with: .none) }
            }
        }
    }
}

