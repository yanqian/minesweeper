import AVFoundation

final class SoundManager {
    static let shared = SoundManager()

    private var player: AVAudioPlayer?

    func playSuccess() {
        guard let url = Bundle.main.url(forResource: "success", withExtension: "wav") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            // Ignore playback errors in production to avoid blocking game flow.
        }
    }
}
