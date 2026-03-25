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
    private let headerCard = UIView()
    private let contactStack = UIStackView()
    private let emailButton = UIButton(type: .system)
    private let phoneButton = UIButton(type: .system)
    private let addToMyVendorsButton = UIButton(type: .system)

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

    // height constraint for dynamic content
    private var containerHeightConstraint: NSLayoutConstraint!

    private let utsavPurple = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)

    init(vendorId: String) {
        self.vendorId = vendorId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    // MARK: - Lifecycle

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientFrame()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyBrandGradient()
        setupUTSAVNavbar(title: "Vendor")
        
        setupScrollAndHeader()
        setupSegmented()
        setupPortfolioCollection()
        setupServicesTable()
        switchToSegment(0)

        fetchAll()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // refresh add button state in case vendor removed from MyVendors
        let isAdded = MyVendorsStore.shared.allVendorIds().contains(vendorId)
        updateAddButtonAppearance(isAdded: isAdded)
    }

    // MARK: - Setup UI

    private func setupScrollAndHeader() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .clear
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor), // To fill the screen
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
        
        // Optimized gap for UTSAV brand
        scrollView.contentInset.top = 20
        scrollView.verticalScrollIndicatorInsets.top = 20

        // Header views
        // 🔽 Header Card (Glassy)
        headerCard.translatesAutoresizingMaskIntoConstraints = false
        headerCard.backgroundColor = .white.withAlphaComponent(0.85)
        headerCard.layer.cornerRadius = 18
        headerCard.layer.shadowColor = UIColor.black.cgColor
        headerCard.layer.shadowOpacity = 0.08
        headerCard.layer.shadowRadius = 8
        headerCard.layer.shadowOffset = CGSize(width: 0, height: 4)
        contentView.addSubview(headerCard)

        NSLayoutConstraint.activate([
            headerCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            headerCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 35
        avatarImageView.clipsToBounds = true
        avatarImageView.image = UIImage(systemName: "person.crop.circle")
        avatarImageView.tintColor = .secondaryLabel
        avatarImageView.isUserInteractionEnabled = true
        headerCard.addSubview(avatarImageView)

        nameLabel.font = .systemFont(ofSize: 20, weight: .bold)
        nameLabel.textColor = .black
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        headerCard.addSubview(nameLabel)

        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        roleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        roleLabel.textColor = .darkGray
        roleLabel.numberOfLines = 1
        headerCard.addSubview(roleLabel)

        bioLabel.translatesAutoresizingMaskIntoConstraints = false
        bioLabel.font = .systemFont(ofSize: 14)
        bioLabel.textColor = .black
        bioLabel.numberOfLines = 0
        headerCard.addSubview(bioLabel)

        // Contact stack (horizontal: email then phone)
        contactStack.axis = .horizontal
        contactStack.spacing = 12
        contactStack.alignment = .center
        contactStack.distribution = .fill
        contactStack.translatesAutoresizingMaskIntoConstraints = false

        // Brand purple color
        let purpleColor = utsavPurple

        // Styling helper for compact bordered pill (no big grey background)
        func styleCompactPill(_ b: UIButton,
                              imageName: String,
                              titleText: String,
                              borderColor: UIColor = UIColor.systemGray5,
                              titleColor: UIColor = .label,
                              fontSize: CGFloat = 14) {
            b.translatesAutoresizingMaskIntoConstraints = false
            b.setImage(UIImage(systemName: imageName), for: .normal)
            b.setTitle(" " + titleText, for: .normal)
            b.tintColor = titleColor
            b.setTitleColor(titleColor, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: fontSize, weight: .regular)
            b.contentHorizontalAlignment = .leading
            b.imageView?.contentMode = .scaleAspectFit
            b.layer.cornerRadius = 12
            b.layer.borderWidth = 1
            b.layer.borderColor = borderColor.cgColor
            b.backgroundColor = .clear // remove grey fill
            b.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)

            // allow small dynamic font shrink so items fit better
            b.titleLabel?.adjustsFontSizeToFitWidth = true
            b.titleLabel?.minimumScaleFactor = 0.85
            b.titleLabel?.lineBreakMode = .byTruncatingMiddle
            b.titleLabel?.numberOfLines = 1
        }

        // Email (compact, first) - will truncate in the middle if necessary but can also shrink slightly
        styleCompactPill(emailButton, imageName: "envelope", titleText: "Email")
        emailButton.addTarget(self, action: #selector(emailTapped), for: .touchUpInside)

        // Phone (compact, next) - prefer to show full phone (higher hugging/resistance) and allow slight shrinking
        styleCompactPill(phoneButton, imageName: "phone", titleText: "Call")
        phoneButton.titleLabel?.lineBreakMode = .byTruncatingTail
        phoneButton.addTarget(self, action: #selector(phoneTapped), for: .touchUpInside)

        // Add button (purple pill) — below contact row, compact intrinsic width
        func stylePurplePill(_ b: UIButton, imageName: String, titleText: String) {
            b.translatesAutoresizingMaskIntoConstraints = false
            b.setImage(UIImage(systemName: imageName), for: .normal)
            b.setTitle(" " + titleText, for: .normal)
            b.tintColor = .white
            b.setTitleColor(.white, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            b.contentHorizontalAlignment = .center
            b.imageView?.contentMode = .scaleAspectFit
            b.layer.cornerRadius = 12
            b.backgroundColor = purpleColor
            b.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        }
        stylePurplePill(addToMyVendorsButton, imageName: "plus", titleText: "Add to My Vendors")
        addToMyVendorsButton.addTarget(self, action: #selector(addToMyVendorsTapped), for: .touchUpInside)

        // assemble contactStack and header
        contactStack.addArrangedSubview(emailButton)
        contactStack.addArrangedSubview(phoneButton)

        [contactStack, addToMyVendorsButton].forEach {
            headerCard.addSubview($0)
        }

        // Layout priority tweaks so phone keeps visible text and email can shrink a bit
        emailButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        emailButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        phoneButton.setContentHuggingPriority(.required, for: .horizontal)
        phoneButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        addToMyVendorsButton.setContentHuggingPriority(.required, for: .horizontal)
        addToMyVendorsButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Layout constraints
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 16),
            avatarImageView.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: 70),
            avatarImageView.heightAnchor.constraint(equalToConstant: 70),

            nameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -16),

            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            roleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            roleLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            bioLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 16),
            bioLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 16),
            bioLabel.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -16),

            contactStack.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 16),
            contactStack.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 16),
            contactStack.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -16),
            contactStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),

            addToMyVendorsButton.topAnchor.constraint(equalTo: contactStack.bottomAnchor, constant: 16),
            addToMyVendorsButton.centerXAnchor.constraint(equalTo: headerCard.centerXAnchor),
            addToMyVendorsButton.widthAnchor.constraint(equalTo: headerCard.widthAnchor, multiplier: 0.8),
            addToMyVendorsButton.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -16),
            addToMyVendorsButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    @objc private func avatarTapped() {
        guard let image = avatarImageView.image else { return }

        let vc = UIViewController()
        vc.view.backgroundColor = .black

        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true

        vc.view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: vc.view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor)
        ])

        // tap anywhere to dismiss
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissFullScreenImage))
        vc.view.addGestureRecognizer(dismissTap)

        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    @objc private func dismissFullScreenImage() {
        dismiss(animated: true)
    }


    private func setupSegmented() {
        segmented.translatesAutoresizingMaskIntoConstraints = false
        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)

        // Style the segment with brand purple
        segmented.selectedSegmentTintColor = utsavPurple
        segmented.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmented.setTitleTextAttributes([.foregroundColor: utsavPurple], for: .normal)
        segmented.backgroundColor = utsavPurple.withAlphaComponent(0.08)

        // segmented anchored below the add button
        contentView.addSubview(segmented)
        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: 16),
            segmented.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            segmented.heightAnchor.constraint(equalToConstant: 40)
        ])

        // container for segment content
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        containerHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: 300)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 12),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),
            containerHeightConstraint
        ])
    }

    private func setupPortfolioCollection() {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 2
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing

        let totalSideMargins: CGFloat = 16 + 16
        let available = view.bounds.width - totalSideMargins - spacing
        let itemWidth = floor(available / 2.0)

        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 20, right: 16)

        portfolioCollection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        portfolioCollection.translatesAutoresizingMaskIntoConstraints = false
        portfolioCollection.backgroundColor = .clear
        portfolioCollection.register(PortfolioCell.self, forCellWithReuseIdentifier: PortfolioCell.reuseIdentifier)
        portfolioCollection.dataSource = self
        portfolioCollection.delegate = self
        portfolioCollection.isScrollEnabled = false // Let main scroll handle it
        portfolioCollection.contentInsetAdjustmentBehavior = .never

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
        servicesTable.isScrollEnabled = false // Let main scroll handle it
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
        updateContainerHeight()
    }

    private func updateContainerHeight() {
        view.layoutIfNeeded()
        let activeIdx = segmented.selectedSegmentIndex
        let newHeight: CGFloat
        if activeIdx == 0 {
            newHeight = portfolioCollection.collectionViewLayout.collectionViewContentSize.height
        } else {
            newHeight = servicesTable.contentSize.height
        }
        containerHeightConstraint.constant = max(newHeight, 100)
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func emailTapped() {
        guard let t = emailButton.title(for: .normal)?.trimmingCharacters(in: .whitespaces), !t.isEmpty else { return }
        if t == "Email" { return }
        if let url = URL(string: "mailto:\(t)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    @objc private func phoneTapped() {
        guard let t = phoneButton.title(for: .normal)?.trimmingCharacters(in: .whitespaces), !t.isEmpty else { return }
        if t == "Call" { return }
        let digits = t.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        if let url = URL(string: "tel:\(digits)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    @objc private func addToMyVendorsTapped() {
        // Add (idempotent) to store
        MyVendorsStore.shared.add(vendorId: vendorId)

        // update appearance
        updateAddButtonAppearance(isAdded: true)

        // push MyVendors list
        let myVC = MyVendorsViewController()
        navigationController?.pushViewController(myVC, animated: true)
    }

    // helper to update button UI
    private func updateAddButtonAppearance(isAdded: Bool) {
        let purpleColor = utsavPurple
        if isAdded {
            addToMyVendorsButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
            addToMyVendorsButton.setTitle(" Added", for: .normal)
            addToMyVendorsButton.tintColor = .white
            addToMyVendorsButton.setTitleColor(.white, for: .normal)
            addToMyVendorsButton.backgroundColor = purpleColor
            addToMyVendorsButton.isEnabled = true
        } else {
            addToMyVendorsButton.setImage(UIImage(systemName: "plus"), for: .normal)
            addToMyVendorsButton.setTitle(" Add to My Vendors", for: .normal)
            addToMyVendorsButton.tintColor = .white
            addToMyVendorsButton.setTitleColor(.white, for: .normal)
            addToMyVendorsButton.backgroundColor = purpleColor
            addToMyVendorsButton.isEnabled = true
        }
    }

    // MARK: - Loading Helpers

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
                self.updateContainerHeight()
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
                self.updateContainerHeight()
            }
        } catch {
            await MainActor.run {
                NSLog("Failed to load services: %@", error.localizedDescription)
            }
        }
    }

    // MARK: - Populate header

    private func populateHeader(with vendor: VendorRecord) {
        nameLabel.text = vendor.businessName ?? vendor.fullName ?? "Vendor"
        
        // Profession
        let profession = vendor.role?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        roleLabel.text = !profession.isEmpty ? profession : (vendor.businessName ?? "Independent Professional")
        
        bioLabel.text = vendor.bio ?? "No description available."

        // set email / phone text
        if let mail = vendor.email, !mail.isEmpty {
            emailButton.setTitle(" \(mail)", for: .normal)
        } else {
            emailButton.setTitle(" Email", for: .normal)
        }
        if let phone = vendor.phone, !phone.isEmpty {
            phoneButton.setTitle(" \(phone)", for: .normal)
        } else {
            phoneButton.setTitle(" Call", for: .normal)
        }

        // update add button state if already added
        let alreadyAdded = MyVendorsStore.shared.allVendorIds().contains(vendorId)
        updateAddButtonAppearance(isAdded: alreadyAdded)

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
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = .systemGray6

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 1

        contentView.addSubview(iv)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            iv.topAnchor.constraint(equalTo: contentView.topAnchor),
            iv.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            iv.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            iv.heightAnchor.constraint(equalTo: contentView.heightAnchor, constant: -20),

            titleLabel.topAnchor.constraint(equalTo: iv.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
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

        guard let price = svc.price else {
            priceLabel.text = ""
            return
        }

        if let unit = svc.pricingUnit {
            priceLabel.text = "₹\(Int(price)) / \(unit)"
        } else {
            priceLabel.text = "₹\(Int(price))"
        }
    }
}
