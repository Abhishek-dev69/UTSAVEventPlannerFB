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
    
    private let addButton = UIButton(type: .system)
    private var tableBottomConstraint: NSLayoutConstraint!
    private var selectedInventoryIds: Set<String> = []
    private var sentInventoryIds: Set<String> = []
    
    // MARK: - Inventory Card State
    private var allocatedCount: Int = 0
    private var receivedCount: Int = 0
    private var pendingCount: Int = 0
    private var lostCount: Int = 0
    
    private func styleSegments() {
        segmented.selectedSegmentTintColor = UIColor(
            red: 136/255,
            green: 71/255,
            blue: 246/255,
            alpha: 1
        )

        segmented.setTitleTextAttributes(
            [.foregroundColor: UIColor.white],
            for: .selected
        )

        segmented.setTitleTextAttributes(
            [.foregroundColor: UIColor.gray],
            for: .normal
        )
    }



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
        applyBrandGradient()
        view.backgroundColor = .clear
        setupNav()
        setupBottomButton()
        setupSegment()
        setupTable()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadFromCart),
            name: .inventoryUpdated,
            object: nil
        )

        // ✅ FIXED — Proper execution order
        Task {
            await loadInventory()
            await loadPostEventPending()
            await loadLostRows()
        }
    }
    @objc private func reloadFromCart() {
        Task {
            await loadInventory()
        }
    }
    @MainActor
    private func reloadAllInventoryData() async {
        // 1️⃣ reload raw data
        await loadInventory()
        await loadPostEventPending()
        await loadLostRows()

        // 2️⃣ recompute card values
        recomputeInventoryCard()

        // 3️⃣ reload ONLY the card cell
        reloadInventoryCardCell()
    }
    private func recomputeInventoryCard() {

        // 1️⃣ Allocated = sum of planner + vendor quantities
        let allItems = plannerItems + vendorItems
        allocatedCount = allItems.reduce(0) { $0 + $1.quantity }

        // 2️⃣ Pending = sum of post-event pending quantities
        // (these rows EXIST only if not fully received/lost)
        let pendingQty = postEventRows.reduce(0) { $0 + $1.postQty }

        // 3️⃣ Received = allocated - pending - lost
        let lostQty = lostDamagedRows.reduce(0) { $0 + $1.postQty }

        receivedCount = max(allocatedCount - pendingQty - lostQty, 0)
        pendingCount = pendingQty
        lostCount = lostQty
    }

    private func reloadInventoryCardCell() {
        let indexPath = IndexPath(row: 0, section: 0)
        guard tableView.indexPathsForVisibleRows?.contains(indexPath) == true else { return }

        tableView.reloadRows(at: [indexPath], with: .none)
    }



    private func setupNav() {
        setupUTSAVNavbar(title: event.eventName)
        navigationItem.largeTitleDisplayMode = .never

        let plusConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        addButton.setImage(
            UIImage(systemName: "plus", withConfiguration: plusConfig),
            for: .normal
        )
        addButton.tintColor = .black // Branded black for transparent navbar items

        addButton.addTarget(self, action: #selector(addItemTapped), for: .touchUpInside)

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addButton)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientFrame()
    }


    @objc private func addItemTapped() {
        let sheet = UIAlertController(
            title: "Add Inventory",
            message: nil,
            preferredStyle: .actionSheet
        )

        sheet.addAction(
            UIAlertAction(title: "My Inventory", style: .default) { [weak self] _ in
                self?.openAddInventory(source: "planner")
            }
        )

        sheet.addAction(
            UIAlertAction(title: "Vendor Inventory", style: .default) { [weak self] _ in
                self?.openAddInventory(source: "vendor")
            }
        )

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // ✅ iPad / dropdown anchor support
        if let pop = sheet.popoverPresentationController {
            pop.barButtonItem = navigationItem.rightBarButtonItem
        }

        present(sheet, animated: true)
    }
    private func openAddInventory(source: String) {
        let vc = AddInventoryItemViewController(eventId: event.id)
        vc.modalPresentationStyle = .pageSheet   // 👈 NOT full screen

        // preselect source
        vc.preselectedSource = source   // small addition (explained below)

        vc.onItemAdded = { [weak self] newItem in
            self?.appendAndReload(newItem)
            Task {
                await self?.loadPostEventPending()
                await self?.loadLostRows()
            }
        }

        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium()]     // 👈 dropdown-style height
            sheet.prefersGrabberVisible = true
        }

        present(vc, animated: true)
    }

    private func setupSegment() {
        segmented.selectedSegmentIndex = 0
        segmented.translatesAutoresizingMaskIntoConstraints = false
        segmented.addTarget(self, action: #selector(segChanged), for: .valueChanged)
        view.addSubview(segmented)
        
        styleSegments()

        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: view.topAnchor, constant: 100), // Adjusted for immersive top
            segmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmented.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.register(InventoryListCell.self, forCellReuseIdentifier: "InventoryListCell")
        tableView.register(InventoryCheckboxCell.self, forCellReuseIdentifier: "InventoryCheckboxCell")
        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        tableBottomConstraint = tableView.bottomAnchor.constraint(
            equalTo: bottomButton.topAnchor,
            constant: -12
        )
        tableBottomConstraint.isActive = true

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
    
    private func updateSendButton() {
        let count = selectedInventoryIds.count
        bottomButton.setTitle("Mark as Sent (\(count))", for: .normal)
        bottomButton.isHidden = count == 0
    }
    @objc private func receivedTapped() {

        print("🟣 Selected IDs:", selectedInventoryIds)

        let combined = plannerItems + vendorItems

        print("🟣 Combined IDs:", combined.map { $0.id })

        let selectedItems = combined.filter { item in
            selectedInventoryIds.contains(item.id)
        }

        print("🟣 Selected Items Count:", selectedItems.count)

        guard !selectedItems.isEmpty else {
            print("❌ No selected items found")
            return
        }

        Task {
            do {
                for item in selectedItems {

                    print("🚀 Creating post-event row for:", item.name)

                    try await InventoryDataManager.shared.createPostEventRow(
                        inventoryItemId: item.id,
                        eventId: event.id,
                        qty: item.quantity
                    )
                }

                print("✅ Inserted post-event rows")

                await loadPostEventPending()
                await loadLostRows()
                await loadInventory()

                await MainActor.run {
                    self.selectedInventoryIds.removeAll()
                    self.updateSendButton()
                    self.segmented.selectedSegmentIndex = 1
                    self.recomputeInventoryCard()
                    self.tableView.reloadData()
                }

            } catch {
                print("❌ Mark as Sent ERROR:", error)
            }
        }
    }
    // Load allocated inventory_items
    private func loadInventory() async {
        do {
            let items = try await InventoryDataManager.shared.fetchInventory(eventId: event.id)

            plannerItems = items.filter {
                ($0.sourceType ?? "").lowercased() == "planner"
                || ($0.sourceType ?? "").lowercased() == "cart"
            }

            vendorItems = items.filter {
                ($0.sourceType ?? "").lowercased() == "vendor"
            }

            await MainActor.run {
                tableView.reloadData()
            }

        } catch {
            print("Inventory load failed:", error)
        }
    }
    // Load pending post-event rows using the view vw_postevent_pending
    private func loadPostEventPending() async {
        do {
            let rows = try await InventoryDataManager.shared.fetchPendingPostEventRows(eventId: event.id)

            // 🔥 Fetch ALL sent item ids (not just pending)
            let allSentIds = try await InventoryDataManager.shared
                .fetchAllPostEventInventoryItemIds(eventId: event.id)

            await MainActor.run {
                self.postEventRows = rows
                self.sentInventoryIds = allSentIds 
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

        // =====================================================
        // MARK: - ALLOCATED
        // =====================================================
        case 0:

            let combined = plannerItems + vendorItems
            let item = combined[indexPath.row]

            let isCartItem = (item.sourceType ?? "").lowercased() == "cart"
            let alreadySent = sentInventoryIds.contains(item.id)

            if isCartItem {

                let cell = tv.dequeueReusableCell(
                    withIdentifier: "InventoryCheckboxCell",
                    for: indexPath
                ) as! InventoryCheckboxCell

                cell.configure(
                    name: item.name,
                    quantity: item.quantity,
                    sourceType: item.sourceType
                )

                // ALWAYS reset interaction safely
                cell.setCheckboxEnabled(true)
                cell.setChecked(false)
                cell.onChecked = nil

                if alreadySent {
                    // Permanently sent
                    cell.setChecked(true)
                    cell.setCheckboxEnabled(false)
                } else {

                    let isSelected = selectedInventoryIds.contains(item.id)
                    cell.setChecked(isSelected)

                    cell.onChecked = { [weak self] in
                        guard let self = self else { return }

                        if self.selectedInventoryIds.contains(item.id) {
                            self.selectedInventoryIds.remove(item.id)
                        } else {
                            self.selectedInventoryIds.insert(item.id)
                        }

                        self.updateSendButton()
                        tv.reloadRows(at: [indexPath], with: .none)
                    }
                }

                return cell
            }

            // Non-cart → normal list cell
            let cell = tv.dequeueReusableCell(
                withIdentifier: "InventoryListCell",
                for: indexPath
            ) as! InventoryListCell

            cell.configure(
                name: item.name,
                quantity: item.quantity,
                sourceType: item.sourceType
            )

            return cell


        case 1:

            let row = postEventRows[indexPath.row]

            let cell = tv.dequeueReusableCell(
                withIdentifier: "InventoryCheckboxCell",
                for: indexPath
            ) as! InventoryCheckboxCell

            cell.configure(
                name: row.name,
                quantity: row.postQty,
                sourceType: row.sourceType
            )

            // ALWAYS reset properly
            cell.setCheckboxEnabled(true)
            cell.setChecked(false)
            cell.onChecked = nil

            cell.onChecked = { [weak self] in
                guard let self = self else { return }
                self.presentPostEventAction(for: row, at: indexPath)
            }

            return cell


        case 2:

            let lost = lostDamagedRows[indexPath.row]

            let cell = tv.dequeueReusableCell(
                withIdentifier: "InventoryListCell",
                for: indexPath
            ) as! InventoryListCell

            cell.configure(
                name: lost.name,
                quantity: lost.postQty,
                sourceType: lost.sourceType
            )

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

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            guard let self = self else { return }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }
        })

        present(ac, animated: true)
    }

    /// Perform RPC and update local lists/UI accordingly (partial qty supported).
    func performPostEventAction(
        row: PostEventRow,
        qty: Int,
        action: PostEventAction,
        at indexPath: IndexPath
    ) async {

        do {
            // 1️⃣ Perform server action
            switch action {
            case .received:
                try await InventoryDataManager.shared.markPostEventReceived(
                    postEventId: row.posteventId,
                    qty: qty
                )

            case .lost:
                try await InventoryDataManager.shared.markPostEventLost(
                    postEventId: row.posteventId,
                    qty: qty,
                    note: nil
                )
            }

            // 2️⃣ Authoritative reload (same for both cases)
            await loadPostEventPending()
            await loadLostRows()
            await loadInventory()

            // 3️⃣ Update UI + card immediately
            await MainActor.run {
                self.recomputeInventoryCard()
                self.reloadInventoryCardCell()
                self.tableView.reloadData()
            }
        } catch {
            print("Post-event action failed:", error)

            await MainActor.run {
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
}
