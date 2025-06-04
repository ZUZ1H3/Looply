import UIKit
import SpotifyiOS

class ViewController: UIViewController, SPTSessionManagerDelegate {

    
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
        
        // 임시: 기존 토큰 삭제 (권한이 부족한 토큰이라서)
        //UserDefaults.standard.removeObject(forKey: "spotifyAccessToken")
        
        if let token = UserDefaults.standard.string(forKey: "spotifyAccessToken") {
            goToMainScreen()
        } else {
            print("🔓 로그인 필요")
        }
    }
    
    func goToMainScreen() {
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let mainVC = storyboard.instantiateViewController(withIdentifier: "MainViewController") as? MainViewController {
                mainVC.modalPresentationStyle = .fullScreen
                self.present(mainVC, animated: true, completion: nil)
            }
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
