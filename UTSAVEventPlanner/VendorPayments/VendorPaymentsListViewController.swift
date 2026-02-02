import UIKit

final class VendorPaymentsListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)

    private var allVendors: [VendorPaymentSummary] = []
    private var filteredVendors: [VendorPaymentSummary] = []
    private var isSearching = false

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "No vendor payments yet"
        l.textAlignment = .center
        l.textColor = .secondaryLabel
        l.font = .systemFont(ofSize: 15)
        return l
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        setupTable()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if allVendors.isEmpty {
            Task { await loadVendorPayments() }
        }
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(VendorPaymentCardCell.self, forCellReuseIdentifier: "VendorPaymentCardCell")
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140
        tableView.keyboardDismissMode = .onDrag
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadVendorPayments() async {
        do {
            let plannerId = try await SupabaseManager.shared.ensureUserId()
            let items = try await CartManager.shared.fetchAssignedVendorItemsForPlanner(plannerId: plannerId)
            let payments = try await PaymentSupabaseManager.shared.fetchAllVendorPayments()

            var map: [String: VendorPaymentSummary] = [:]

            for item in items {
                guard let id = item.assignedVendorId,
                      let name = item.assignedVendorName,
                      let amount = item.lineTotal else { continue }

                let existing = map[id]
                map[id] = VendorPaymentSummary(
                    vendorId: id,
                    vendorName: name,
                    totalPayable: (existing?.totalPayable ?? 0) + amount,
                    totalPaid: existing?.totalPaid ?? 0
                )
            }

            for pay in payments {
                guard let id = pay.vendor_id,
                      let existing = map[id] else { continue }

                map[id] = VendorPaymentSummary(
                    vendorId: id,
                    vendorName: existing.vendorName,
                    totalPayable: existing.totalPayable,
                    totalPaid: existing.totalPaid + pay.amount
                )
            }

            allVendors = Array(map.values)
            filteredVendors = allVendors

            await MainActor.run {
                UIView.performWithoutAnimation {
                    tableView.reloadData()
                }
                tableView.backgroundView = allVendors.isEmpty ? emptyLabel : nil
            }

        } catch {
            print("❌ VendorPaymentsList error:", error)
        }
    }
}

// MARK: - Search
extension VendorPaymentsListViewController: VendorSearchable {

    func updateVendorSearch(text: String) {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if query.isEmpty {
            isSearching = false
            filteredVendors = allVendors
        } else {
            isSearching = true
            filteredVendors = allVendors.filter {
                $0.vendorName.localizedCaseInsensitiveContains(query)
            }
        }

        tableView.reloadData()
    }
}

// MARK: - Table
extension VendorPaymentsListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ t: UITableView, numberOfRowsInSection section: Int) -> Int {
        (isSearching ? filteredVendors : allVendors).count
    }

    func tableView(_ t: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let list = isSearching ? filteredVendors : allVendors
        let vendor = list[indexPath.row]

        let cell = t.dequeueReusableCell(
            withIdentifier: "VendorPaymentCardCell",
            for: indexPath
        ) as! VendorPaymentCardCell

        cell.configure(
            vendorName: vendor.vendorName,
            total: vendor.totalPayable,
            paid: vendor.totalPaid
        )

        return cell
    }

    func tableView(_ t: UITableView, didSelectRowAt indexPath: IndexPath) {
        t.deselectRow(at: indexPath, animated: true)

        let vendor = (isSearching ? filteredVendors : allVendors)[indexPath.row]
        let vc = VendorPaymentDetailViewController(
            vendorId: vendor.vendorId,
            vendorName: vendor.vendorName,
            totalPayable: vendor.totalPayable
        )

        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

