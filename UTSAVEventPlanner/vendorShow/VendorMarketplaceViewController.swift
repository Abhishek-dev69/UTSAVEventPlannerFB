//
// VendorMarketplaceViewController.swift
// EventPlanner - marketplace fetch from shared Supabase
//

import UIKit
import Supabase

final class VendorMarketplaceViewController: UIViewController {

    private var vendors: [VendorRecord] = []
    private var filteredVendors: [VendorRecord] = []

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchBar = UISearchBar()

    private var imageCache = NSCache<NSString, UIImage>()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Vendors"
        view.backgroundColor = .systemBackground
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        setupSearchBar()
        setupTableView()
        loadVendors()
    }

    private func setupSearchBar() {
        searchBar.placeholder = "Search vendors"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.sizeToFit()
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
        tableView.tableHeaderView = searchBar
        tableView.rowHeight = 110
        tableView.register(VendorMarketplaceCell.self,
                           forCellReuseIdentifier: VendorMarketplaceCell.reuseIdentifier)

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 12
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.06
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 6

        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.layer.cornerRadius = 10
        thumbnailImageView.clipsToBounds = true

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.boldSystemFont(ofSize: 15)
        nameLabel.numberOfLines = 2

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
            nameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 18),

            categoryLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            categoryLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            categoryLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        currentImageURL = nil
    }
}

