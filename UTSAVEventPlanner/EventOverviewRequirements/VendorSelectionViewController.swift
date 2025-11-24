import UIKit

final class VendorSelectionViewController: UIViewController {

    private let requirement: CartItemRecord

    private let segmented = UISegmentedControl(items: ["My Vendor", "Marketplace"])
    private let tableView = UITableView()

    private var myVendors: [Vendor] = []
    private var marketplaceVendors: [Vendor] = []

    init(requirement: CartItemRecord) {
        self.requirement = requirement
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Assign Vendor"
        view.backgroundColor = .white

        setupSegment()
        setupTable()
        loadVendors()
    }

    private func setupSegment() {
        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(segChanged), for: .valueChanged)
        segmented.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmented)

        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmented.heightAnchor.constraint(equalToConstant: 34)
        ])
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(VendorCell.self, forCellReuseIdentifier: "VendorCell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadVendors() {
        // Fetch from Supabase later
        myVendors = [
            Vendor(id: "d1f3c0b8-6d9c-4c2b-8c7b-3a5e1f7b9a10", name: "GreenLeaf Floral", rating: 4.9, years: 8),
            Vendor(id: "vendor-2", name: "The Gourmet Kitchen", rating: 4.7, years: 6)
        ]

        marketplaceVendors = [
            Vendor(id: "vendor-3", name: "Blossom & Vine", rating: 4.8, years: 10),
            Vendor(id: "vendor-4", name: "The Flower Boutique", rating: 4.7, years: 5)
        ]
        tableView.reloadData()
    }

    @objc private func segChanged() { tableView.reloadData() }
}

extension VendorSelectionViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        segmented.selectedSegmentIndex == 0 ? myVendors.count : marketplaceVendors.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VendorCell", for: indexPath) as! VendorCell
        let vendor = segmented.selectedSegmentIndex == 0 ? myVendors[indexPath.row] : marketplaceVendors[indexPath.row]
        cell.configure(vendor: vendor)

        cell.onSelect = { [weak self] in
            guard let self else { return }
            let vc = VendorProposalViewController(vendor: vendor, requirement: self.requirement)
            self.navigationController?.pushViewController(vc, animated: true)
        }

        return cell
    }
}
