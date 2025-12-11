//
// VendorDetailViewController.swift
// EventPlanner - vendor public profile + portfolio & services
//

import UIKit
import Supabase
import AVKit

final class VendorDetailViewController: UIViewController {

    // MARK: - Public

    private let vendorId: String

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // header
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let bioLabel = UILabel()
    private let contactStack = UIStackView()
    private let emailButton = UIButton(type: .system)
    private let phoneButton = UIButton(type: .system)

    // segmented content
    private let segmented = UISegmentedControl(items: ["Portfolio", "Services"])
    private let containerView = UIView()

    // portfolio collection
    private var portfolioCollection: UICollectionView!
    private var portfolioItems: [PortfolioRecord] = []

    // services table
    private let servicesTable = UITableView(frame: .zero, style: .plain)
    private var services: [VendorServiceRecord] = []

    // image cache
    private let imageCache = NSCache<NSString, UIImage>()

    // loading indicator
    private var loadingHud: UIActivityIndicatorView?

    // MARK: - Init

    init(vendorId: String) {
        self.vendorId = vendorId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Vendor"

        setupScrollAndHeader()
        setupSegmented()
        setupPortfolioCollection()
        setupServicesTable()
        switchToSegment(0)

        fetchAll()
    }

    // MARK: - Setup UI

    private func setupScrollAndHeader() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

            // Important: width equal to view so content sizes correctly
            contentView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])

        // Header stack
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 44
        avatarImageView.clipsToBounds = true
        avatarImageView.image = UIImage(systemName: "person.crop.circle")
        avatarImageView.tintColor = .secondaryLabel

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        nameLabel.numberOfLines = 2

        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        roleLabel.font = .systemFont(ofSize: 15)
        roleLabel.textColor = .secondaryLabel
        roleLabel.numberOfLines = 1

        bioLabel.translatesAutoresizingMaskIntoConstraints = false
        bioLabel.font = .systemFont(ofSize: 14)
        bioLabel.textColor = .secondaryLabel
        bioLabel.numberOfLines = 0

        contactStack.axis = .horizontal
        contactStack.spacing = 12
        contactStack.distribution = .fillEqually
        contactStack.translatesAutoresizingMaskIntoConstraints = false

        emailButton.setTitle("Email", for: .normal)
        phoneButton.setTitle("Call", for: .normal)
        emailButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        phoneButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)

        emailButton.addTarget(self, action: #selector(emailTapped), for: .touchUpInside)
        phoneButton.addTarget(self, action: #selector(phoneTapped), for: .touchUpInside)

        [emailButton, phoneButton].forEach {
            $0.layer.cornerRadius = 10
            $0.backgroundColor = UIColor.systemGray6
            $0.setTitleColor(.label, for: .normal)
            contactStack.addArrangedSubview($0)
        }

        // assemble header
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(roleLabel)
        contentView.addSubview(bioLabel)
        contentView.addSubview(contactStack)

        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            avatarImageView.widthAnchor.constraint(equalToConstant: 88),
            avatarImageView.heightAnchor.constraint(equalToConstant: 88),

            nameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            roleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            roleLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            bioLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 12),
            bioLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bioLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            contactStack.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 12),
            contactStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contactStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            contactStack.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupSegmented() {
        segmented.translatesAutoresizingMaskIntoConstraints = false
        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)

        contentView.addSubview(segmented)
        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: contactStack.bottomAnchor, constant: 20),
            segmented.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            segmented.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            segmented.heightAnchor.constraint(equalToConstant: 36)
        ])

        // container for segment content
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 12),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300) // allow scrolling
        ])
    }

    private func setupPortfolioCollection() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        let side = (view.bounds.width - 20 - 20 - 12) / 2 // 2 columns with margins
        layout.itemSize = CGSize(width: side, height: side * 0.75)
        layout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 20, right: 12)

        portfolioCollection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        portfolioCollection.translatesAutoresizingMaskIntoConstraints = false
        portfolioCollection.backgroundColor = .clear
        portfolioCollection.register(PortfolioCell.self, forCellWithReuseIdentifier: PortfolioCell.reuseIdentifier)
        portfolioCollection.dataSource = self
        portfolioCollection.delegate = self

        containerView.addSubview(portfolioCollection)
        NSLayoutConstraint.activate([
            portfolioCollection.topAnchor.constraint(equalTo: containerView.topAnchor),
            portfolioCollection.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            portfolioCollection.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            portfolioCollection.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    private func setupServicesTable() {
        servicesTable.translatesAutoresizingMaskIntoConstraints = false
        servicesTable.register(VendorServiceCell.self, forCellReuseIdentifier: VendorServiceCell.reuseIdentifier)
        servicesTable.dataSource = self
        servicesTable.delegate = self
        servicesTable.tableFooterView = UIView()
        servicesTable.rowHeight = UITableView.automaticDimension
        servicesTable.estimatedRowHeight = 72

        containerView.addSubview(servicesTable)
        NSLayoutConstraint.activate([
            servicesTable.topAnchor.constraint(equalTo: containerView.topAnchor),
            servicesTable.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            servicesTable.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            servicesTable.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    // MARK: - Actions

    @objc private func segmentChanged(_ s: UISegmentedControl) {
        switchToSegment(s.selectedSegmentIndex)
    }

    private func switchToSegment(_ idx: Int) {
        portfolioCollection.isHidden = idx != 0
        servicesTable.isHidden = idx != 1
    }

    @objc private func emailTapped() {
        guard let email = emailButton.title(for: .normal), !email.isEmpty else { return }
        if let url = URL(string: "mailto:\(email)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    @objc private func phoneTapped() {
        guard let phone = phoneButton.title(for: .normal), !phone.isEmpty else { return }
        let digits = phone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        if let url = URL(string: "tel:\(digits)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Loading

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

    // MARK: - Data Fetching

    private func fetchAll() {
        showLoading(true)
        Task {
            async let vTask: () = loadVendor()
            async let pTask: () = loadPortfolio()
            async let sTask: () = loadServices()

            _ = await (vTask, pTask, sTask)
            await MainActor.run { self.showLoading(false) }
        }
    }

    private func loadVendor() async {
        do {
            if let vendor = try await VendorManager.shared.fetchVendorById(vendorId) {
                await MainActor.run { self.populateHeader(with: vendor) }
            } else {
                await MainActor.run { self.nameLabel.text = "Vendor" }
            }
        } catch {
            await MainActor.run {
                self.showSimpleAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }

    private func loadPortfolio() async {
        do {
            let items = try await VendorManager.shared.fetchPortfolioItems(vendorId: vendorId)
            await MainActor.run {
                self.portfolioItems = items
                self.portfolioCollection.reloadData()
            }
        } catch {
            await MainActor.run {
                NSLog("Failed to load portfolio: %@", error.localizedDescription)
            }
        }
    }

    private func loadServices() async {
        do {
            let svcs = try await VendorManager.shared.fetchServicesForVendor(vendorId: vendorId)
            await MainActor.run {
                self.services = svcs
                self.servicesTable.reloadData()
            }
        } catch {
            await MainActor.run {
                NSLog("Failed to load services: %@", error.localizedDescription)
            }
        }
    }

    // MARK: - Populate header

    private func populateHeader(with vendor: VendorRecord) {
        nameLabel.text = vendor.fullName ?? vendor.businessName ?? "Vendor"
        roleLabel.text = vendor.role ?? vendor.businessName ?? ""
        bioLabel.text = vendor.bio ?? ""
        emailButton.setTitle(vendor.email ?? "Email", for: .normal)
        phoneButton.setTitle(vendor.phone ?? "Call", for: .normal)
        title = vendor.fullName ?? "Vendor"

        if let urlStr = VendorManager.shared.resolvedAvatarURLString(for: vendor),
           let url = URL(string: urlStr) {
            loadImage(from: url) { [weak self] img in
                guard let self = self else { return }
                if let img = img { self.avatarImageView.image = img }
            }
        }
    }

    // MARK: - Image loading helper

    private func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let key = NSString(string: url.absoluteString)
        if let cached = imageCache.object(forKey: key) {
            completion(cached)
            return
        }
        let req = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
        URLSession.shared.dataTask(with: req) { [weak self] data, resp, err in
            guard let self = self, let data = data, let img = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            self.imageCache.setObject(img, forKey: key)
            DispatchQueue.main.async { completion(img) }
        }.resume()
    }

    // MARK: - Helpers

    private func showSimpleAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - CollectionView (Portfolio)

extension VendorDetailViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return portfolioItems.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = portfolioItems[indexPath.item]
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PortfolioCell.reuseIdentifier, for: indexPath) as? PortfolioCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: item, imageLoader: self.loadImage)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = portfolioItems[indexPath.item]
        guard let urlS = item.mediaUrl, let url = URL(string: urlS) else { return }

        if item.mediaType == "video" {
            let player = AVPlayer(url: url)
            let pvc = AVPlayerViewController()
            pvc.player = player
            present(pvc, animated: true) { player.play() }
            return
        }

        let vc = UIViewController()
        vc.view.backgroundColor = .black
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        vc.view.addSubview(iv)
        NSLayoutConstraint.activate([
            iv.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            iv.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
            iv.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor),
            iv.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor)
        ])

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let img = UIImage(data: data) {
                    await MainActor.run { iv.image = img }
                }
            } catch {
                await MainActor.run {
                    self.showSimpleAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }

        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - TableView (Services)

extension VendorDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { services.count }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let svc = services[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VendorServiceCell.reuseIdentifier, for: indexPath) as? VendorServiceCell else {
            return UITableViewCell()
        }
        cell.configure(with: svc)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // optional: show service details or add to cart
    }
}

// MARK: - PortfolioCell

private final class PortfolioCell: UICollectionViewCell {
    static let reuseIdentifier = "PortfolioCell"
    private let iv = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 12
        contentView.backgroundColor = .secondarySystemBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2

        contentView.addSubview(iv)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            iv.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            iv.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            iv.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            iv.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.68),

            titleLabel.topAnchor.constraint(equalTo: iv.bottomAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    func configure(with item: PortfolioRecord, imageLoader: @escaping (URL, @escaping (UIImage?) -> Void) -> Void) {
        titleLabel.text = item.title ?? ""
        iv.image = UIImage(systemName: "photo")
        if let s = item.mediaUrl, let url = URL(string: s) {
            imageLoader(url) { [weak self] img in
                guard let self = self else { return }
                if let img = img { self.iv.image = img }
            }
        }
    }
}

// MARK: - VendorServiceCell

private final class VendorServiceCell: UITableViewCell {
    static let reuseIdentifier = "VendorServiceCell"
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let priceLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = .systemFont(ofSize: 13)
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 2
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        priceLabel.textColor = .systemPurple

        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(priceLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: priceLabel.leadingAnchor, constant: -8),

            priceLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            detailLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    func configure(with svc: VendorServiceRecord) {
        titleLabel.text = svc.name
        detailLabel.text = svc.description ?? ""
        if let p = svc.price {
            priceLabel.text = String(format: "₹%.0f", p)
        } else {
            priceLabel.text = ""
        }
    }
}

