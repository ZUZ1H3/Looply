import UIKit
import SpotifyiOS

class ViewController: UIViewController, SPTSessionManagerDelegate {

    // MARK: - IBOutlets (스토리보드에 추가할 것들)
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var loginButtonOutlet: UIButton! // 기존 버튼을 연결
    
    lazy var clientID: String = {
           guard let id = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_CLIENT_ID") as? String else {
               fatalError("SPOTIFY_CLIENT_ID가 Info.plist에 없음")
           }
           return id
       }()

       lazy var redirectURI: URL = {
           guard let uriString = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_REDIRECT_URI") as? String,
                 let uri = URL(string: uriString) else {
               fatalError("SPOTIFY_REDIRECT_URI가 유효하지 않음")
           }
           return uri
       }()

    lazy var configuration: SPTConfiguration = {
        let config = SPTConfiguration(clientID: clientID, redirectURL: redirectURI)
        config.playURI = ""
        return config
    }()

    lazy var sessionManager: SPTSessionManager = {
        let manager = SPTSessionManager(configuration: configuration, delegate: self)
        return manager
    }()

    @IBAction func loginButton(_ sender: UIButton) {
        let scopes: SPTScope = [
                .userReadPlaybackState,
                .userModifyPlaybackState,
                .userReadCurrentlyPlaying,
                .streaming,
                .appRemoteControl,
                .userLibraryRead
            ]
            sessionManager.initiateSession(with: scopes, options: .default, campaign: nil)

    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()

        // 임시: 기존 토큰 삭제 (권한이 부족한 토큰이라서)
        UserDefaults.standard.removeObject(forKey: "spotifyAccessToken")
        
        if let token = UserDefaults.standard.string(forKey: "spotifyAccessToken") {
            goToMainScreen()
        } else {
            print("🔓 로그인 필요")
        }
    }
    
    // MARK: - 🆕 UI 설정
    private func setupUI() {
        // 배경색
        view.backgroundColor = .white
        
        // 인사말 설정
        setupGreetingLabel()
        
        // Looply 로고 설정
        setupLogoImage()
        
        // 로그인 버튼 스타일링
        setupLoginButton()
    }
    
    private func setupLogoImage() {
        logoImageView.image = UIImage(named: "looply_logo")
        logoImageView.contentMode = .scaleAspectFit
        
        // 크기 제약조건 코드로 설정
        logoImageView.widthAnchor.constraint(equalToConstant: 180).isActive = true  // 원하는 크기로 조정
        logoImageView.heightAnchor.constraint(equalToConstant: 55).isActive = true  // 원하는 크기로 조정
    }
    
    private func setupLoginButton() {
        loginButtonOutlet.setTitle("Login with Spotify", for: .normal)
        loginButtonOutlet.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        loginButtonOutlet.setTitleColor(.white, for: .normal)
        
        loginButtonOutlet.backgroundColor = .black
        loginButtonOutlet.layer.cornerRadius = 10
        
        // Spotify 아이콘으로 변경 (Assets에 spotify_icon.png 추가하거나)
        if let spotifyIcon = UIImage(named: "spotify_icon") {
            loginButtonOutlet.setImage(spotifyIcon, for: .normal)
            loginButtonOutlet.tintColor = .white
            loginButtonOutlet.imageEdgeInsets = UIEdgeInsets(top: 0, left: -20, bottom: 0, right: 0)
        } else {
            loginButtonOutlet.setImage(UIImage(systemName: "music.note.list"), for: .normal)
        }
    }
    
    private func setupGreetingLabel() {
            greetingLabel.text = "오늘 네 기분, 어떤 음악으로 루프할까?"
            greetingLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            greetingLabel.textColor = .darkGray
            greetingLabel.numberOfLines = 0
        }
    
    // ViewController.swift (로그인 화면)에서
    func goToMainScreen() {
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            // TabBarController의 Storyboard ID가 설정되어 있어야 함
            let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarController")
            tabBarController.modalPresentationStyle = .fullScreen
            self.present(tabBarController, animated: true)
        }
    }


    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("✅ Logged in! Token:", session.accessToken)
        
        // 저장
        UserDefaults.standard.set(session.accessToken, forKey: "spotifyAccessToken")
        
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let mainVC = storyboard.instantiateViewController(withIdentifier: "MainViewController") as? MainViewController {
                mainVC.modalPresentationStyle = .fullScreen
                self.present(mainVC, animated: true, completion: nil)
            } 
        }
    }



    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("❌ Login failed:", error.localizedDescription)
    }
}
