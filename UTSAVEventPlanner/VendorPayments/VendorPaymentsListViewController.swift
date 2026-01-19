import UIKit

struct VendorPaymentSummary {
    let vendorId: String
    let vendorName: String
    let totalPayable: Double
    let totalPaid: Double
}

final class VendorPaymentsListViewController: UIViewController {

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .plain)

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "No vendor payments yet"
        l.textAlignment = .center
        l.textColor = .secondaryLabel
        l.font = .systemFont(ofSize: 15)
        return l
    }()

    // MARK: - Data
    private var vendors: [VendorPaymentSummary] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        setupTable()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await loadVendorPayments() }
    }

    // MARK: - Setup
    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(
            VendorPaymentCardCell.self,
            forCellReuseIdentifier: "VendorPaymentCardCell"
        )
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        // ✅ REQUIRED for card auto-sizing
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140
        tableView.contentInset.top = 8

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Data Loading
    private func loadVendorPayments() async {
        do {
            let plannerId = try await SupabaseManager.shared.ensureUserId()

            let items = try await CartManager.shared
                .fetchAssignedVendorItemsForPlanner(plannerId: plannerId)

            let payments = try await PaymentSupabaseManager.shared
                .fetchAllVendorPayments()

            var map: [String: VendorPaymentSummary] = [:]

            // 1️⃣ TOTAL PAYABLE (from cart items)
            for item in items {
                guard
                    let vendorId = item.assignedVendorId,
                    let vendorName = item.assignedVendorName,
                    let amount = item.lineTotal
                else { continue }

                if let existing = map[vendorId] {
                    map[vendorId] = VendorPaymentSummary(
                        vendorId: vendorId,
                        vendorName: existing.vendorName,
                        totalPayable: existing.totalPayable + amount,
                        totalPaid: existing.totalPaid
                    )
                } else {
                    map[vendorId] = VendorPaymentSummary(
                        vendorId: vendorId,
                        vendorName: vendorName,
                        totalPayable: amount,
                        totalPaid: 0
                    )
                }
            }

            // 2️⃣ TOTAL PAID
            for pay in payments {
                guard
                    let vendorId = pay.vendor_id,
                    let existing = map[vendorId]
                else { continue }

                map[vendorId] = VendorPaymentSummary(
                    vendorId: vendorId,
                    vendorName: existing.vendorName,
                    totalPayable: existing.totalPayable,
                    totalPaid: existing.totalPaid + pay.amount
                )
            }

            vendors = Array(map.values)

            await MainActor.run {
                tableView.reloadData()
                tableView.backgroundView = vendors.isEmpty ? emptyLabel : nil
            }

        } catch {
            print("❌ VendorPaymentsList error:", error)
        }
    }
}

// MARK: - Table
extension VendorPaymentsListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        vendors.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let vendor = vendors[indexPath.row]
        let cell = tableView.dequeueReusableCell(
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

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        let vendor = vendors[indexPath.row]

        // ✅ CRITICAL FIX: pass totalPayable
        let vc = VendorPaymentDetailViewController(
            vendorId: vendor.vendorId,
            vendorName: vendor.vendorName,
            totalPayable: vendor.totalPayable
        )

        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

