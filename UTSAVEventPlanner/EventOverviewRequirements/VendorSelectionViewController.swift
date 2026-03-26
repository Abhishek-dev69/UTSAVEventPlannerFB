//
// VendorSelectionViewController.swift
// EventPlanner
//

import UIKit

final class VendorSelectionViewController: UIViewController {

    // MARK: - Input
    private let requirements: [CartItemRecord]

    init(requirements: [CartItemRecord]) {
        self.requirements = requirements
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: - UI
    private let segmented = UISegmentedControl(items: ["My Vendors", "Marketplace"])
    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .plain)

    // MARK: - Glass Header Components
    private let glassHeaderCard = UIView()
    private let blurView        = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let tintOverlay     = UIView()
    private let headerSeparator = UIView()
    private let headerTitleLabel = UILabel()
    private let backButton = UIButton(type: .system)
    private let bgGradientLayer = CAGradientLayer()

    // MARK: - Data (original)
    private var myVendors: [VendorRecord] = []
    private var marketplaceVendors: [VendorRecord] = []

    // MARK: - Data (filtered)
    private var filteredMyVendors: [VendorRecord] = []
    private var filteredMarketplaceVendors: [VendorRecord] = []

    // MARK: - Loading
    private var loadingHud: UIActivityIndicatorView?

    // MARK: - Init
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyBrandGradient()
        view.backgroundColor = .clear // Allow gradient to show through

        setupGlassHeader()
        setupSegment()
        setupSearchBar()
        setupTable()
        loadMyVendors()
        fetchMarketplaceVendors()
    }

    // Reload My Vendors every time screen appears
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        loadMyVendors()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientFrame()
        if let grad = tintOverlay.layer.sublayers?.first as? CAGradientLayer {
            grad.frame = tintOverlay.bounds
        }
    }

    // MARK: - Setup UI

    private func setupGlassHeader() {
        let purple = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)

        glassHeaderCard.translatesAutoresizingMaskIntoConstraints = false
        glassHeaderCard.clipsToBounds = false
        glassHeaderCard.layer.shadowColor   = purple.cgColor
        glassHeaderCard.layer.shadowOpacity = 0.0
        glassHeaderCard.layer.shadowRadius  = 12
        glassHeaderCard.layer.shadowOffset  = CGSize(width: 0, height: 4)
        view.addSubview(glassHeaderCard)

        blurView.clipsToBounds = true
        blurView.layer.cornerRadius = 20
        blurView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.alpha = 0
        glassHeaderCard.addSubview(blurView)

        tintOverlay.isUserInteractionEnabled = false
        tintOverlay.layer.cornerRadius = 20
        tintOverlay.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        tintOverlay.clipsToBounds = true
        tintOverlay.translatesAutoresizingMaskIntoConstraints = false
        tintOverlay.alpha = 0
        let grad = CAGradientLayer()
        grad.colors = [purple.withAlphaComponent(0.18).cgColor,
                       purple.withAlphaComponent(0.04).cgColor]
        grad.startPoint = CGPoint(x: 0.5, y: 0)
        grad.endPoint   = CGPoint(x: 0.5, y: 1)
        tintOverlay.layer.insertSublayer(grad, at: 0)
        glassHeaderCard.addSubview(tintOverlay)

        headerSeparator.backgroundColor = purple.withAlphaComponent(0.25)
        headerSeparator.alpha = 0
        headerSeparator.translatesAutoresizingMaskIntoConstraints = false
        glassHeaderCard.addSubview(headerSeparator)

        headerTitleLabel.text = "Assign Vendor"
        headerTitleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        headerTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        glassHeaderCard.addSubview(headerTitleLabel)

        let backImg = UIImage(systemName: "chevron.left")
        backButton.setImage(backImg, for: .normal)
        backButton.tintColor = .black
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        glassHeaderCard.addSubview(backButton)

        let safeTop = view.safeAreaLayoutGuide.topAnchor
        NSLayoutConstraint.activate([
            glassHeaderCard.topAnchor.constraint(equalTo: view.topAnchor),
            glassHeaderCard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            glassHeaderCard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            glassHeaderCard.bottomAnchor.constraint(equalTo: safeTop, constant: 52),

            blurView.topAnchor.constraint(equalTo: glassHeaderCard.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: glassHeaderCard.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: glassHeaderCard.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor),

            tintOverlay.topAnchor.constraint(equalTo: glassHeaderCard.topAnchor),
            tintOverlay.leadingAnchor.constraint(equalTo: glassHeaderCard.leadingAnchor),
            tintOverlay.trailingAnchor.constraint(equalTo: glassHeaderCard.trailingAnchor),
            tintOverlay.bottomAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor),

            headerSeparator.leadingAnchor.constraint(equalTo: glassHeaderCard.leadingAnchor),
            headerSeparator.trailingAnchor.constraint(equalTo: glassHeaderCard.trailingAnchor),
            headerSeparator.bottomAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor),
            headerSeparator.heightAnchor.constraint(equalToConstant: 0.5),

            backButton.leadingAnchor.constraint(equalTo: glassHeaderCard.leadingAnchor, constant: 8),
            backButton.centerYAnchor.constraint(equalTo: headerTitleLabel.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            headerTitleLabel.bottomAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor, constant: -12),
            headerTitleLabel.centerXAnchor.constraint(equalTo: glassHeaderCard.centerXAnchor)
        ])
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func setupSegment() {
        segmented.selectedSegmentIndex = 0
        segmented.selectedSegmentTintColor = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)
        segmented.backgroundColor = UIColor(white: 1.0, alpha: 0.4)
        segmented.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmented.addTarget(self, action: #selector(segChanged), for: .valueChanged)
        segmented.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmented)

        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor, constant: 12),
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
        tableView.rowHeight = 110
        tableView.backgroundColor = .clear
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

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        let progress = min(max((offset - 10) / 30, 0), 1)
        UIView.animate(withDuration: 0.1) {
            self.blurView.alpha = progress
            self.tintOverlay.alpha = progress
            self.headerSeparator.alpha = progress
            self.glassHeaderCard.layer.shadowOpacity = Float(progress * 0.08)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return segmented.selectedSegmentIndex == 0
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
                requirements: self.requirements
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
            requirements: self.requirements
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
