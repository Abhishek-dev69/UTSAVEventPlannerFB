import UIKit
import AVFoundation
import AuthenticationServices

final class LoginViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Video playlist
    private let videoNames = ["event1_bg", "event2_bg"]      // add .mp4 in bundle
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?

    // MARK: - UI
    private let heroView = UIView()
    private let heroDim  = CAGradientLayer()
    private let bottomCover = UIView()
    private let brandLabel = UILabel()
    private let videoCenterGuide = UILayoutGuide()

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let cardView = UIView()

    private let titleLabel = UILabel()

    private let phoneRow = UIStackView()
    private let countryButton = UIButton(type: .system)
    private let phoneTextField = UITextField()

    private let continueButton = UIButton(type: .system)

    private let sepRow = UIStackView()
    private let leftLine = UIView()
    private let orLabel  = UILabel()
    private let rightLine = UIView()

    private let socialStack = UIStackView()
    private let googleButton = UIButton(type: .system)
    private let appleButton  = ASAuthorizationAppleIDButton(type: .signIn, style: .black)

    private let footerLabel = UILabel()

    // MARK: - Layout constants
    private let corner: CGFloat = 28
    private let edge: CGFloat = 20
    private let fieldH: CGFloat = 52
    private let maxCardWidth: CGFloat = 480

    // MARK: - State
    private let requiredDigitsForIN = 10
    private var nextVideoIndex: Int = 0

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        navigationController?.setNavigationBarHidden(true, animated: false)

        buildUI()
        layoutUI()
        styleUI()
        hookEvents()
        updateContinueEnabled(isValid: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startVideoPlaylist()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = heroView.bounds
        heroDim.frame      = heroView.bounds
        heroView.bringSubviewToFront(brandLabel)
    }

    // MARK: - Build
    private func buildUI() {
        [heroView, scrollView].forEach { v in
            v.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(v)
        }
        brandLabel.translatesAutoresizingMaskIntoConstraints = false
        heroView.addSubview(brandLabel)
        view.addLayoutGuide(videoCenterGuide)

        bottomCover.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomCover)

        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        [titleLabel, phoneRow, continueButton, sepRow, socialStack, footerLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview($0)
        }

        phoneRow.axis = .horizontal
        phoneRow.spacing = 12
        phoneRow.alignment = .fill
        phoneRow.distribution = .fill
        phoneRow.addArrangedSubview(countryButton)
        phoneRow.addArrangedSubview(phoneTextField)

        sepRow.axis = .horizontal
        sepRow.alignment = .center
        sepRow.spacing = 12
        sepRow.addArrangedSubview(leftLine)
        sepRow.addArrangedSubview(orLabel)
        sepRow.addArrangedSubview(rightLine)

        socialStack.axis = .vertical
        socialStack.alignment = .fill
        socialStack.distribution = .fill
        socialStack.spacing = 12
        socialStack.addArrangedSubview(googleButton)
        socialStack.addArrangedSubview(appleButton)
    }

    // MARK: - Layout
    private func layoutUI() {
        // Update heroView constraints to fill entire view height so video is fully behind content
        NSLayoutConstraint.activate([
            heroView.topAnchor.constraint(equalTo: view.topAnchor),
            heroView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heroView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heroView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            videoCenterGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoCenterGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoCenterGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            videoCenterGuide.bottomAnchor.constraint(equalTo: cardView.topAnchor)
        ])

        NSLayoutConstraint.activate([
            brandLabel.centerXAnchor.constraint(equalTo: videoCenterGuide.centerXAnchor),
            brandLabel.centerYAnchor.constraint(equalTo: videoCenterGuide.centerYAnchor)
        ])

        NSLayoutConstraint.activate([
            bottomCover.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomCover.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomCover.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomCover.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
        contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor).isActive = true

        // Replace cardView constraints to pin to bottom and span full width with edge insets
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            cardView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor)
        ])

        // Internal layout remains the same
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 28),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: edge),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -edge),

            phoneRow.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            phoneRow.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: edge),
            phoneRow.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -edge),
            phoneRow.heightAnchor.constraint(equalToConstant: fieldH),
            countryButton.widthAnchor.constraint(equalToConstant: 110),

            continueButton.topAnchor.constraint(equalTo: phoneRow.bottomAnchor, constant: 14),
            continueButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: edge),
            continueButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -edge),
            continueButton.heightAnchor.constraint(equalToConstant: fieldH),

            sepRow.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: 12),
            sepRow.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: edge),
            sepRow.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -edge),

            socialStack.topAnchor.constraint(equalTo: sepRow.bottomAnchor, constant: 12),
            socialStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: edge),
            socialStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -edge),

            footerLabel.topAnchor.constraint(equalTo: socialStack.bottomAnchor, constant: 10),
            footerLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: edge),
            footerLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -edge),
            footerLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20)
        ])

        leftLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        rightLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        leftLine.setContentHuggingPriority(.defaultLow, for: .horizontal)
        rightLine.setContentHuggingPriority(.defaultLow, for: .horizontal)
        orLabel.setContentHuggingPriority(.required, for: .horizontal)
    }

    // MARK: - Style
    private func styleUI() {
        // Dim the top of the hero so status items are readable
        heroDim.colors = [UIColor.black.withAlphaComponent(0.35).cgColor, UIColor.clear.cgColor]
        heroDim.startPoint = CGPoint(x: 0.5, y: 0)
        heroDim.endPoint   = CGPoint(x: 0.5, y: 1)
        heroView.layer.addSublayer(heroDim)
        
        brandLabel.text = "UTSΛV"
        brandLabel.textColor = .white
        brandLabel.font = .systemFont(ofSize: 44, weight: .bold)
        brandLabel.textAlignment = .center
        brandLabel.numberOfLines = 1
        brandLabel.adjustsFontSizeToFitWidth = true
        brandLabel.minimumScaleFactor = 0.6

        bottomCover.backgroundColor = .systemBackground

        // Card: only top corners rounded, crisp iOS spacing
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = corner
        cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        cardView.layer.masksToBounds = false
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.12
        cardView.layer.shadowRadius = 12
        cardView.layer.shadowOffset = CGSize(width: 0, height: -2)

        titleLabel.text = "Log in or sign up"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .label

        var c = UIButton.Configuration.filled()
        c.title = "🇮🇳  +91 ▾"
        c.baseBackgroundColor = .secondarySystemBackground
        c.baseForegroundColor = .label
        c.cornerStyle = .large
        c.contentInsets = .init(top: 12, leading: 14, bottom: 12, trailing: 12)
        countryButton.configuration = c

        phoneTextField.placeholder = "Enter Mobile Number"
        phoneTextField.keyboardType = .numberPad
        phoneTextField.textContentType = .telephoneNumber
        phoneTextField.delegate = self
        phoneTextField.backgroundColor = .secondarySystemBackground
        phoneTextField.layer.cornerRadius = 14
        phoneTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        phoneTextField.leftViewMode = .always
        phoneTextField.clearButtonMode = .whileEditing
        phoneTextField.font = .systemFont(ofSize: 17)

        var cont = UIButton.Configuration.filled()
        cont.title = "Continue"
        cont.baseBackgroundColor = UIColor(red: 0x8B/255, green: 0x3B/255, blue: 0xF0/255, alpha: 1)
        cont.baseForegroundColor = .white
        cont.cornerStyle = .large
        cont.contentInsets = .init(top: 14, leading: 20, bottom: 14, trailing: 20)
        continueButton.configuration = cont
        continueButton.layer.cornerRadius = 14
        continueButton.layer.masksToBounds = true

        leftLine.backgroundColor = .tertiaryLabel
        rightLine.backgroundColor = .tertiaryLabel
        orLabel.text = "or"
        orLabel.textColor = .secondaryLabel
        orLabel.font = .systemFont(ofSize: 14, weight: .semibold)

        styleGoogleButton()

        appleButton.cornerRadius = 14
        appleButton.heightAnchor.constraint(equalToConstant: fieldH).isActive = true
        appleButton.addTarget(self, action: #selector(appleTapped), for: .touchUpInside)

        footerLabel.textAlignment = .center
        footerLabel.numberOfLines = 0
        footerLabel.font = .systemFont(ofSize: 12)
        footerLabel.textColor = .secondaryLabel
        footerLabel.text = "By continuing, you agree to our Terms of Service • Privacy Policy • Content Policies"
    }

    private func styleGoogleButton() {
        googleButton.configuration = nil
        googleButton.backgroundColor = .systemBackground
        googleButton.layer.cornerRadius = 14
        googleButton.layer.borderWidth = 1
        googleButton.layer.borderColor = UIColor.systemGray3.cgColor
        googleButton.heightAnchor.constraint(equalToConstant: fieldH).isActive = true

        // Clean row content
        googleButton.subviews.forEach {
            if $0 is UIStackView || $0 is UIImageView || $0 is UILabel { $0.removeFromSuperview() }
        }
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        row.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(named: "google_logo")?.withRenderingMode(.alwaysOriginal))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 20).isActive = true

        let label = UILabel()
        label.text = "Sign in with Google"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label

        row.addArrangedSubview(icon)
        row.addArrangedSubview(label)
        googleButton.addSubview(row)
        NSLayoutConstraint.activate([
            row.centerXAnchor.constraint(equalTo: googleButton.centerXAnchor),
            row.centerYAnchor.constraint(equalTo: googleButton.centerYAnchor)
        ])
        googleButton.addTarget(self, action: #selector(googleTapped), for: .touchUpInside)
    }

    // MARK: - Events
    private func hookEvents() {
        phoneTextField.addTarget(self, action: #selector(phoneChanged), for: .editingChanged)
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingNow))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(self, selector: #selector(appBecameActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnteredBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    @objc private func endEditingNow() { view.endEditing(true) }

    @objc private func phoneChanged() {
        let digits = phoneTextField.text?.filter(\.isNumber) ?? ""
        let limited = String(digits.prefix(requiredDigitsForIN))
        if limited != phoneTextField.text?.filter(\.isNumber) { phoneTextField.text = limited }
        updateContinueEnabled(isValid: limited.count == requiredDigitsForIN)
    }

    private func updateContinueEnabled(isValid: Bool) {
        continueButton.isEnabled = isValid
        continueButton.alpha = isValid ? 1.0 : 0.6
    }

    @objc private func continueTapped() {
        view.endEditing(true)
        let digits = phoneTextField.text?.filter(\.isNumber) ?? ""
        guard digits.count == requiredDigitsForIN else { return }
        let otpVC = OtpViewController(countryCode: "+91", phone: digits)
        navigationController?.pushViewController(otpVC, animated: true)
    }

    @objc private func googleTapped() { print("Google tapped") }
    @objc private func appleTapped()  { print("Apple tapped")  }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty { return true }
        guard CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string)) else { return false }
        let current = textField.text ?? ""
        if let r = Range(range, in: current) {
            let new = current.replacingCharacters(in: r, with: string)
            return new.filter(\.isNumber).count <= requiredDigitsForIN
        }
        return true
    }
}

// MARK: - Video (alternate two files forever; safe queueing)
private extension LoginViewController {
    var videoURLs: [URL] { videoNames.compactMap { Bundle.main.url(forResource: $0, withExtension: "mp4") } }

    func startVideoPlaylist() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let urls = videoURLs
        guard !urls.isEmpty else { return }

        // Start with the first item and keep appending on finish
        nextVideoIndex = 1 % urls.count
        let firstItem = AVPlayerItem(url: urls[0])
        let q = AVQueuePlayer(items: [firstItem])
        q.isMuted = true

        let layer = AVPlayerLayer(player: q)
        layer.videoGravity = .resizeAspectFill
        layer.frame = heroView.bounds
        heroView.layer.insertSublayer(layer, at: 0)

        heroView.bringSubviewToFront(brandLabel)
        heroView.layer.addSublayer(heroDim)

        NotificationCenter.default.addObserver(self, selector: #selector(itemDidFinish(_:)),
                                               name: .AVPlayerItemDidPlayToEndTime, object: nil)
        player = q
        playerLayer = layer
        q.play()
    }

    @objc func itemDidFinish(_ note: Notification) {
        guard let q = player else { return }
        let urls = videoURLs
        guard !urls.isEmpty else { return }
        let item = AVPlayerItem(url: urls[nextVideoIndex])
        nextVideoIndex = (nextVideoIndex + 1) % urls.count
        q.insert(item, after: nil)
    }

    @objc func appBecameActive()      { player?.play() }
    @objc func appEnteredBackground() { player?.pause() }
}

