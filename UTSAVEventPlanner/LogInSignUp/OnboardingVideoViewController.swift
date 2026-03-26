import UIKit
import AVFoundation

final class OnboardingVideoViewController: UIViewController {

    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private let videoNames = ["event2_bg", "event1_bg"]
    private var nextVideoIndex: Int = 0

    private let logoLabel: UILabel = {
        let l = UILabel()
        l.text = "UTSΛV"
        l.font = .systemFont(ofSize: 60, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private let taglineLabel: UILabel = {
        let l = UILabel()
        l.text = "Where events flow not fail"
        l.font = .systemFont(ofSize: 18, weight: .medium)
        l.textColor = .white.withAlphaComponent(0.9)
        l.textAlignment = .center
        return l
    }()

    private let getStartedButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupVideo()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player?.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
    }

    private func setupVideo() {
        let items = videoNames.compactMap { name -> AVPlayerItem? in
            guard let url = Bundle.main.url(forResource: name, withExtension: "mp4") else { return nil }
            return AVPlayerItem(url: url)
        }
        
        player = AVQueuePlayer(items: items)
        player?.actionAtItemEnd = .advance
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.frame = view.bounds
        view.layer.insertSublayer(playerLayer!, at: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }

    @objc private func playerItemDidReachEnd(notification: Notification) {
        guard let item = notification.object as? AVPlayerItem else { return }
        item.seek(to: .zero, completionHandler: nil)
        player?.advanceToNextItem()
        
        // Loop: re-add the item that just finished to the end of the queue
        let name = videoNames[nextVideoIndex]
        if let url = Bundle.main.url(forResource: name, withExtension: "mp4") {
            let newItem = AVPlayerItem(url: url)
            player?.insert(newItem, after: nil)
        }
        nextVideoIndex = (nextVideoIndex + 1) % videoNames.count
    }

    private func setupUI() {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
        blur.frame = view.bounds
        blur.alpha = 0.3
        view.insertSubview(blur, at: 1)
        
        let stack = UIStackView(arrangedSubviews: [logoLabel, taglineLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        setupUTSAVPrimaryButton(getStartedButton, title: "Get Started")
        getStartedButton.translatesAutoresizingMaskIntoConstraints = false
        getStartedButton.addTarget(self, action: #selector(getStartedTapped), for: .touchUpInside)
        view.addSubview(getStartedButton)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            
            getStartedButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            getStartedButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            getStartedButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            getStartedButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    @objc private func getStartedTapped() {
        let loginVC = LoginViewController()
        let nav = UINavigationController(rootViewController: loginVC)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        present(nav, animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds
    }
}
