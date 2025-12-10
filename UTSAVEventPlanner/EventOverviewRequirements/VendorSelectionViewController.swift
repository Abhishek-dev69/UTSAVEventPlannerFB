//
// VendorSelectionViewController.swift
// EventPlanner - select vendor from marketplace and send proposal
//

import UIKit

final class VendorSelectionViewController: UIViewController {

    private let requirement: CartItemRecord

    private let segmented = UISegmentedControl(items: ["My Vendor", "Marketplace"])
    private let tableView = UITableView()

    // myVendors (hardcoded sample as VendorRecord — replace with your own fetch if needed)
    private var myVendors: [VendorRecord] = []

    // marketplace vendors fetched from Supabase
    private var marketplaceVendors: [VendorRecord] = []

    // Loading indicator
    private var loadingHud: UIActivityIndicatorView?

    init(requirement: CartItemRecord) {
        self.requirement = requirement
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Assign Vendor"
        view.backgroundColor = .systemBackground

        setupSegment()
        setupTable()
        loadInitialData()
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
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadInitialData() {
        // Example hardcoded myVendors using VendorRecord (so code compiles).
        // Replace this with an actual Supabase query if you maintain a planner->vendor link table.
        myVendors = [
            VendorRecord(
                id: "11111111-1111-1111-1111-111111111111",
                userId: nil, fullName: "GreenLeaf Floral", role: "Florist",
                bio: nil, email: nil, phone: nil, businessName: "GreenLeaf",
                businessAddress: nil, avatarUrl: nil, avatarPath: nil,
                createdAt: nil, updatedAt: nil
            ),
            VendorRecord(
                id: "22222222-2222-2222-2222-222222222222",
                userId: nil, fullName: "The Gourmet Kitchen", role: "Caterer",
                bio: nil, email: nil, phone: nil, businessName: "Gourmet Kitchen",
                businessAddress: nil, avatarUrl: nil, avatarPath: nil,
                createdAt: nil, updatedAt: nil
            )
        ]

        // fetch marketplace vendors from Supabase
        fetchMarketplaceVendors()
    }

    @objc private func segChanged() {
        tableView.reloadData()
    }

    // MARK: - Loading indicator
    private func showLoading(_ show: Bool) {
        if show {
            if loadingHud == nil {
                let hud = UIActivityIndicatorView(style: .large)
                hud.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
                hud.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
                view.addSubview(hud)
                hud.startAnimating()
                loadingHud = hud
            }
        } else {
            loadingHud?.removeFromSuperview()
            loadingHud = nil
        }
    }

    // MARK: - Fetch marketplace vendors
    private func fetchMarketplaceVendors() {
        showLoading(true)
        Task {
            do {
                let records = try await VendorManager.shared.fetchAllVendors()
                await MainActor.run {
                    self.marketplaceVendors = records
                    self.tableView.reloadData()
                    self.showLoading(false)
                }
            } catch {
                await MainActor.run {
                    self.showLoading(false)
                    let a = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(a, animated: true)
                }
            }
        }
    }
}

// MARK: - Table datasource / delegate

extension VendorSelectionViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        segmented.selectedSegmentIndex == 0 ? myVendors.count : marketplaceVendors.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "VendorCell", for: indexPath) as? VendorCell else {
            return UITableViewCell()
        }

        let record = segmented.selectedSegmentIndex == 0 ? myVendors[indexPath.row] : marketplaceVendors[indexPath.row]
        cell.configure(with: record)

        // When user taps "Select" on the VendorCell, open the proposal screen
        cell.onSelect = { [weak self] in
            guard let self = self else { return }
            let vc = VendorProposalViewController(vendor: record, requirement: self.requirement)
            self.navigationController?.pushViewController(vc, animated: true)
        }

        return cell
    }

    // row tap opens proposal as well
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let record = segmented.selectedSegmentIndex == 0 ? myVendors[indexPath.row] : marketplaceVendors[indexPath.row]
        let vc = VendorProposalViewController(vendor: record, requirement: requirement)
        navigationController?.pushViewController(vc, animated: true)
    }
}

