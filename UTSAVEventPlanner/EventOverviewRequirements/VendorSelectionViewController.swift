//
// VendorSelectionViewController.swift
// EventPlanner
//

import UIKit

final class VendorSelectionViewController: UIViewController {

    // MARK: - Input
    private let requirement: CartItemRecord

    // MARK: - UI
    private let segmented = UISegmentedControl(items: ["My Vendors", "Marketplace"])
    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .plain)

    // MARK: - Data (original)
    private var myVendors: [VendorRecord] = []
    private var marketplaceVendors: [VendorRecord] = []

    // MARK: - Data (filtered)
    private var filteredMyVendors: [VendorRecord] = []
    private var filteredMarketplaceVendors: [VendorRecord] = []

    // MARK: - Loading
    private var loadingHud: UIActivityIndicatorView?

    // MARK: - Init
    init(requirement: CartItemRecord) {
        self.requirement = requirement
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Assign Vendor"
        view.backgroundColor = .systemBackground

        setupSegment()
        setupSearchBar()
        setupTable()
        loadMyVendors()
        fetchMarketplaceVendors()
    }

    // Reload My Vendors every time screen appears
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadMyVendors()
    }

    // MARK: - Setup UI

    private func setupSegment() {
        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(segChanged), for: .valueChanged)
        segmented.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmented)

        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            segmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmented.heightAnchor.constraint(equalToConstant: 34)
        ])
    }

    private func setupSearchBar() {
        searchBar.placeholder = "Search vendors"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self

        // Apple-style SF symbol search icon
        searchBar.setImage(
            UIImage(systemName: "magnifyingglass"),
            for: .search,
            state: .normal
        )

        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            searchBar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(VendorCell.self, forCellReuseIdentifier: "VendorCell")
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 90
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 6),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Data Loading

    /// Loads vendors added in MyVendorsViewController
    private func loadMyVendors() {
        let ids = MyVendorsStore.shared.allVendorIds()
        myVendors = []
        filteredMyVendors = []

        guard !ids.isEmpty else {
            tableView.reloadData()
            return
        }

        Task {
            await withTaskGroup(of: VendorRecord?.self) { group in
                for id in ids {
                    group.addTask {
                        try? await VendorManager.shared.fetchVendorById(id)
                    }
                }

                var result: [VendorRecord] = []
                for await v in group {
                    if let v = v { result.append(v) }
                }

                // keep order same as stored
                let map = Dictionary(uniqueKeysWithValues: result.map { ($0.id, $0) })
                let ordered = ids.compactMap { map[$0] }

                await MainActor.run {
                    self.myVendors = ordered
                    self.filteredMyVendors = ordered
                    self.tableView.reloadData()
                }
            }
        }
    }

    /// Marketplace vendors
    private func fetchMarketplaceVendors() {
        showLoading(true)
        Task {
            do {
                let list = try await VendorManager.shared.fetchAllVendors()
                await MainActor.run {
                    self.marketplaceVendors = list
                    self.filteredMarketplaceVendors = list
                    self.showLoading(false)
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.showLoading(false)
                }
            }
        }
    }

    // MARK: - Loading HUD

    private func showLoading(_ show: Bool) {
        if show {
            if loadingHud == nil {
                let hud = UIActivityIndicatorView(style: .large)
                hud.center = view.center
                hud.startAnimating()
                view.addSubview(hud)
                loadingHud = hud
            }
        } else {
            loadingHud?.removeFromSuperview()
            loadingHud = nil
        }
    }

    // MARK: - Actions

    @objc private func segChanged() {
        searchBar.text = ""
        tableView.reloadData()
    }
}

// MARK: - TableView

extension VendorSelectionViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        segmented.selectedSegmentIndex == 0
        ? filteredMyVendors.count
        : filteredMarketplaceVendors.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "VendorCell",
            for: indexPath
        ) as! VendorCell

        let vendor = segmented.selectedSegmentIndex == 0
        ? filteredMyVendors[indexPath.row]
        : filteredMarketplaceVendors[indexPath.row]

        cell.configure(with: vendor)

        cell.onSelect = { [weak self] in
            guard let self = self else { return }
            let vc = VendorProposalViewController(
                vendor: vendor,
                requirement: self.requirement
            )
            self.navigationController?.pushViewController(vc, animated: true)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let vendor = segmented.selectedSegmentIndex == 0
        ? filteredMyVendors[indexPath.row]
        : filteredMarketplaceVendors[indexPath.row]

        let vc = VendorProposalViewController(
            vendor: vendor,
            requirement: requirement
        )
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Search

extension VendorSelectionViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange text: String) {
        let q = text.lowercased().trimmingCharacters(in: .whitespaces)

        if segmented.selectedSegmentIndex == 0 {
            filteredMyVendors = q.isEmpty
            ? myVendors
            : myVendors.filter {
                ($0.fullName ?? $0.businessName ?? "")
                    .lowercased()
                    .contains(q)
            }
        } else {
            filteredMarketplaceVendors = q.isEmpty
            ? marketplaceVendors
            : marketplaceVendors.filter {
                let name = $0.fullName ?? ""
                let role = $0.role ?? ""
                return name.lowercased().contains(q)
                    || role.lowercased().contains(q)
            }
        }

        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
