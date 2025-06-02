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
                .appRemoteControl
            ]
            sessionManager.initiateSession(with: scopes, options: .default, campaign: nil)

    }
    override func viewDidLoad() {
        super.viewDidLoad()
 }



    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("✅ Logged in! Token:", session.accessToken)

        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let mainVC = storyboard.instantiateViewController(withIdentifier: "MainViewController") as? MainViewController {
                mainVC.modalPresentationStyle = .fullScreen
                self.present(mainVC, animated: true, completion: nil)
            } else {
                print("❌ MainViewController 인스턴스 생성 실패")
            }
        }
    }


    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("❌ Login failed:", error.localizedDescription)
    }
}
