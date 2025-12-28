//
//  ClientRequirementsViewController.swift
//

import UIKit

final class ClientRequirementsViewController: UIViewController {

    private let segmented = UISegmentedControl(items: ["In House Service", "Outsource Service"])
    private let tableView = UITableView()
    private let event: EventRecord
    private var cartItems: [CartItemRecord] = []
    private var inhouse: [CartItemRecord] = []
    private var outsource: [CartItemRecord] = []

    private var selectedSegment = 0
    private var cartPersistObserver: NSObjectProtocol?

    // Use a failable initializer that accepts an initial snapshot of cart items (can be empty)
    init(event: EventRecord, cartItems: [CartItemRecord] = []) {
        self.event = event
        self.cartItems = cartItems
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("Use init(event:cartItems:)") }

    deinit {
        if let obs = cartPersistObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Client Requirements"

        setupSegment()
        setupTable()

        // Observe persisted cart changes and refetch only if it belongs to this event
        cartPersistObserver = NotificationCenter.default.addObserver(forName: .CartItemPersisted, object: nil, queue: .main) { [weak self] note in
            guard let self = self else { return }
            if let userInfo = note.userInfo,
               let persistedEventId = userInfo["eventId"] as? String {
                // If persisted item belongs to this event -> refetch
                if persistedEventId == self.event.id {
                    Task { await self.fetchAndSplitCart() }
                    return
                }
            } else {
                // If eventId unknown (nil or NSNull), we still attempt a safe refresh
                Task { await self.fetchAndSplitCartIfNeeded() }
            }
        }

        // If we were passed items, show them; otherwise fetch fresh
        if cartItems.isEmpty {
            Task { await fetchAndSplitCart() }
        } else {
            // ensure passed items are grouped and split correctly
            groupCartItems()
            splitCartItems()
            tableView.reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task {
            await fetchAndSplitCartIfNeeded()
        }
    }

    // MARK: - UI Setup

    private func setupSegment() {
        segmented.selectedSegmentIndex = 0
        segmented.translatesAutoresizingMaskIntoConstraints = false
        segmented.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        view.addSubview(segmented)

        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmented.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    @objc private func segmentChanged() {
        selectedSegment = segmented.selectedSegmentIndex
        tableView.reloadData()
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self

        tableView.register(InhouseRequirementCell.self, forCellReuseIdentifier: "InhouseRequirementCell")
        tableView.register(OutsourceRequirementCell.self, forCellReuseIdentifier: "OutsourceRequirementCell")

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Data Helpers

    private func sourceType(for item: CartItemRecord) -> String {
        // 1) explicit sourceType field
        if let s = item.sourceType?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
            return s.lowercased()
        }

        // 2) metadata["type"]
        if let t = item.metadata?["type"]?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty {
            return t.lowercased()
        }

        // 3) fallback to serviceName inspection (serviceName may be optional)
        let name = item.serviceName?.lowercased() ?? ""
        if name.contains("outsource") || name.contains("outsourced") {
            return "outsource"
        }

        return "in_house"
    }

    /// Group cartItems by serviceId+subserviceId so UI shows a single row per unique subservice
    /// and sums quantity/lineTotal. This is defensive: if old data contains multiple rows,
    /// we merge them for display.
    private func groupCartItems() {
        guard !cartItems.isEmpty else { return }

        var grouped: [String: [CartItemRecord]] = [:]
        for item in cartItems {
            let sid = item.serviceId ?? item.serviceName ?? "noservice"
            let subid = item.subserviceId ?? item.subserviceName ?? "nosub"
            let key = "\(sid)|\(subid)"
            var arr = grouped[key] ?? []
            arr.append(item)
            grouped[key] = arr
        }

        var compacted: [CartItemRecord] = []
        for (_, items) in grouped {
            guard let first = items.first else { continue }
            let totalQty = items.reduce(0) { $0 + ($1.quantity ?? 0) }
            let rate = first.rate ?? 0
            let lineTotal = rate > 0 ? Double(totalQty) * rate : first.lineTotal

            // Create a new CartItemRecord with aggregated quantity and computed lineTotal.
            // Using memberwise init available on the struct.
            let merged = CartItemRecord(
                id: first.id,
                userId: first.userId,
                eventId: first.eventId,
                serviceId: first.serviceId,
                serviceName: first.serviceName,
                subserviceId: first.subserviceId,
                subserviceName: first.subserviceName,
                rate: first.rate,
                unit: first.unit,
                quantity: totalQty,
                lineTotal: lineTotal,
                metadata: first.metadata,
                createdAt: first.createdAt,
                updatedAt: first.updatedAt,
                sourceType: first.sourceType
            )
            compacted.append(merged)
        }

        // Maintain stable ordering: sort by serviceName then subserviceName
        compacted.sort { lhs, rhs in
            let lsvc = lhs.serviceName ?? ""
            let rsvc = rhs.serviceName ?? ""
            if lsvc != rsvc { return lsvc < rsvc }
            return (lhs.subserviceName ?? "") < (rhs.subserviceName ?? "")
        }

        self.cartItems = compacted
    }

    private func splitCartItems() {
        inhouse = cartItems.filter { sourceType(for: $0) == "in_house" || sourceType(for: $0) == "inhouse" }
        outsource = cartItems.filter { sourceType(for: $0) == "outsource" || sourceType(for: $0) == "outsourced" }
    }

    /// Fetch cart items for this event from server and update UI
    private func fetchAndSplitCart() async {
        do {
            // EventDataManager already fetches event-scoped rows
            let items = try await EventDataManager.shared.fetchCartItems(eventId: event.id)

            await MainActor.run {
                self.cartItems = items
                // group duplicates defensively before splitting
                self.groupCartItems()
                self.splitCartItems()
                self.tableView.reloadData()
            }
        } catch {
            print("Failed to fetch cart items for event: \(error)")
            await MainActor.run {
                // still attempt to show grouped/split existing local data
                self.groupCartItems()
                self.splitCartItems()
                self.tableView.reloadData()
            }
        }
    }

    /// Optionally refetch if the current arrays are empty (prevents unnecessary network calls)
    private func fetchAndSplitCartIfNeeded() async {
        if cartItems.isEmpty || (inhouse.isEmpty && outsource.isEmpty) {
            await fetchAndSplitCart()
        } else {
            await MainActor.run {
                self.groupCartItems()
                self.splitCartItems()
                self.tableView.reloadData()
            }
        }
    }
}

extension ClientRequirementsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedSegment == 0 ? inhouse.count : outsource.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return selectedSegment == 0 ? 60 : 150
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if selectedSegment == 0 {
            // IN-HOUSE CELL
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "InhouseRequirementCell",
                for: indexPath
            ) as! InhouseRequirementCell

            cell.configure(item: inhouse[indexPath.row])
            return cell

        } else {
            // OUTSOURCE CELL
            // OUTSOURCE CELL
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "OutsourceRequirementCell",
                for: indexPath
            ) as! OutsourceRequirementCell

            cell.configure(item: outsource[indexPath.row])

            // ✅ FIXED FLOW: Directly open Assign Vendor screen
            cell.setAssignAction { [weak self] in
                guard let self else { return }
                let item = self.outsource[indexPath.row]

                let vc = VendorSelectionViewController(requirement: item)
                self.navigationController?.pushViewController(vc, animated: true)
            }

            return cell
        }
    }
}

