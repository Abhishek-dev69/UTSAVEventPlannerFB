import UIKit

final class VendorPaymentBreakdownViewController: UIViewController {

    // MARK: - Inputs
    private let vendorId: String
    private let vendorName: String
    private let liabilities: [VendorEventLiability]

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // MARK: - Init
    init(vendorId: String, vendorName: String, liabilities: [VendorEventLiability]) {
        self.vendorId = vendorId
        self.vendorName = vendorName
        self.liabilities = liabilities
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        applyBrandGradient()
        setupUTSAVNavbar(title: "Event Breakdown")
        
        setupTable()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientFrame()
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "breakdownCell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension VendorPaymentBreakdownViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        liabilities.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = liabilities[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "breakdownCell")
        cell.backgroundColor = .white.withAlphaComponent(0.8)
        cell.layer.cornerRadius = 12
        cell.clipsToBounds = true
        
        cell.textLabel?.text = item.eventName
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        
        let detail = "Total Owed: ₹\(fmt(item.totalOwed))  |  Paid: ₹\(fmt(item.totalPaid))"
        cell.detailTextLabel?.text = detail
        cell.detailTextLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        cell.detailTextLabel?.textColor = .secondaryLabel
        
        let remainingLabel = UILabel()
        remainingLabel.text = "₹\(fmt(item.remaining))"
        remainingLabel.font = .systemFont(ofSize: 15, weight: .bold)
        remainingLabel.textColor = UIColor(red: 139/255, green: 59/255, blue: 240/255, alpha: 1)
        remainingLabel.sizeToFit()
        cell.accessoryView = remainingLabel
        
        return cell
    }

    private func fmt(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: v)) ?? "0"
    }
}
