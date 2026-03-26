//
// VendorMarketplaceViewController.swift
// EventPlanner - marketplace fetch from shared Supabase
//

import UIKit
import Supabase

final class VendorMarketplaceViewController: UIViewController {

    private var vendors: [VendorRecord] = []
    private var filteredVendors: [VendorRecord] = []

    private let glassHeaderCard = UIView()
    private let blurView        = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let tintOverlay     = UIView()
    private let headerSeparator = UIView()
    private let headerTitleLabel = UILabel()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchBar = UISearchBar()

    private var imageCache = NSCache<NSString, UIImage>()

    // bg layer
    private let bgGradientLayer = CAGradientLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyBrandGradient()
        view.backgroundColor = .systemBackground
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        setupGlassHeader()
        setupSearchBar()
        setupTableView()
        loadVendors()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
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

    private func setupGlassHeader() {
        let purple = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)

        glassHeaderCard.translatesAutoresizingMaskIntoConstraints = false
        glassHeaderCard.clipsToBounds = false
        glassHeaderCard.layer.shadowColor   = purple.cgColor
        glassHeaderCard.layer.shadowOpacity = 0.0 // Initially flat
        glassHeaderCard.layer.shadowRadius  = 12
        glassHeaderCard.layer.shadowOffset  = CGSize(width: 0, height: 4)
        view.addSubview(glassHeaderCard)

        blurView.clipsToBounds = true
        blurView.layer.cornerRadius = 20
        blurView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.alpha = 0 // Initially transparent
        glassHeaderCard.addSubview(blurView)

        tintOverlay.isUserInteractionEnabled = false
        tintOverlay.layer.cornerRadius = 20
        tintOverlay.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        tintOverlay.clipsToBounds = true
        tintOverlay.translatesAutoresizingMaskIntoConstraints = false
        tintOverlay.alpha = 0 // Initially transparent
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

        headerTitleLabel.text = "Vendors"
        headerTitleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        headerTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        glassHeaderCard.addSubview(headerTitleLabel)

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

            headerTitleLabel.bottomAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor, constant: -12),
            headerTitleLabel.centerXAnchor.constraint(equalTo: glassHeaderCard.centerXAnchor)
        ])
    }

    private func setupSearchBar() {
        searchBar.placeholder = "Search vendors"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12)
        ])
    }
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func setupTableView() {
        tableView.keyboardDismissMode = .onDrag
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = 110
        tableView.register(VendorMarketplaceCell.self,
                           forCellReuseIdentifier: VendorMarketplaceCell.reuseIdentifier)

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Data Loading

    private func loadVendors() {
        showLoading(true)
        Task {
            do {
                let list = try await VendorManager.shared.fetchAllVendors()
                await MainActor.run {
                    self.vendors = list
                    self.filteredVendors = list
                    self.tableView.reloadData()
                    self.showLoading(false)
                }
            } catch {
                await MainActor.run {
                    self.showLoading(false)
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Helpers

    private func showLoading(_ show: Bool) {
        if show {
            let hud = UIActivityIndicatorView(style: .large)
            hud.center = view.center
            hud.tag = 5555
            hud.startAnimating()
            view.addSubview(hud)
        } else {
            view.viewWithTag(5555)?.removeFromSuperview()
        }
    }

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - Table DataSource/Delegate

extension VendorMarketplaceViewController: UITableViewDataSource, UITableViewDelegate {
    
    // Glass blur fades in on scroll
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filteredVendors.count }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: VendorMarketplaceCell.reuseIdentifier,
            for: indexPath
        ) as? VendorMarketplaceCell else {
            return UITableViewCell()
        }

        let vendor = filteredVendors[indexPath.row]
        cell.nameLabel.text = vendor.fullName ?? "Unknown"
        cell.categoryLabel.text = vendor.role ?? vendor.businessName ?? ""

        // placeholder
        cell.thumbnailImageView.image = UIImage(systemName: "person.crop.square")

        if let urlString = VendorManager.shared.resolvedAvatarURLString(for: vendor),
           let url = URL(string: urlString) {
            let cacheKey = NSString(string: url.absoluteString)
            if let cached = imageCache.object(forKey: cacheKey) {
                cell.thumbnailImageView.image = cached
            } else {
                cell.currentImageURL = url
                let req = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
                URLSession.shared.dataTask(with: req) { [weak self, weak cell] data, _, _ in
                    guard let self = self, let data = data, let img = UIImage(data: data) else { return }
                    DispatchQueue.main.async {
                        if cell?.currentImageURL == url {
                            cell?.thumbnailImageView.image = img
                        }
                        self.imageCache.setObject(img, forKey: cacheKey)
                    }
                }.resume()
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vendor = filteredVendors[indexPath.row]
        let vc = VendorDetailViewController(vendorId: vendor.id)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Search

extension VendorMarketplaceViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty {
            filteredVendors = vendors
        } else {
            filteredVendors = vendors.filter {
                let name = $0.fullName ?? ""
                let role = $0.role ?? ""
                return name.lowercased().contains(q.lowercased()) ||
                       role.lowercased().contains(q.lowercased())
            }
        }
        tableView.reloadData()
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) { searchBar.resignFirstResponder() }
}

// MARK: - Cell (kept local but you can reuse your existing UI)

final class VendorMarketplaceCell: UITableViewCell {

    static let reuseIdentifier = "VendorMarketplaceCell"

    let cardView = UIView()
    let nameLabel = UILabel()
    let categoryLabel = UILabel()
    let thumbnailImageView = UIImageView()

    // hold the image url for reuse-safety
    var currentImageURL: URL?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setupUI() }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = UIColor(white: 1.0, alpha: 0.85)
        cardView.layer.cornerRadius = 18
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowOffset = CGSize(width: 0, height: 3)
        cardView.layer.shadowRadius = 8

        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.layer.cornerRadius = 14
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.backgroundColor = .secondarySystemBackground

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        nameLabel.numberOfLines = 1

        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryLabel.font = UIFont.systemFont(ofSize: 13)
        categoryLabel.textColor = .secondaryLabel

        cardView.addSubview(thumbnailImageView)
        cardView.addSubview(nameLabel)
        cardView.addSubview(categoryLabel)
        contentView.addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            thumbnailImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 76),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 76),

            nameLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            nameLabel.bottomAnchor.constraint(equalTo: cardView.centerYAnchor, constant: -2),

            categoryLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            categoryLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            categoryLabel.topAnchor.constraint(equalTo: cardView.centerYAnchor, constant: 2),
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        currentImageURL = nil
    }
}

