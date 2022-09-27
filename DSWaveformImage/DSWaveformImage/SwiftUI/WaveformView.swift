import SwiftUI

@available(iOS 14.0, *)
public struct WaveformView: View {
    public static let defaultConfiguration = Waveform.Configuration(dampening: .init(percentage: 0.125, sides: .both))

    public let audioURL: URL
    public let configuration: Waveform.Configuration
    public let priority: TaskPriority

    @StateObject private var waveformDrawer = WaveformImageDrawer()
    @State private var waveformImage: UIImage = UIImage()

    public init(
        audioURL: URL,
        configuration: Waveform.Configuration = defaultConfiguration,
        priority: TaskPriority = .userInitiated
    ) {
        self.audioURL = audioURL
        self.configuration = configuration
        self.priority = priority
    }

    public var body: some View {
        GeometryReader { geometry in
            Image(uiImage: waveformImage)
                .resizable()
                .onAppear {
                    guard waveformImage.size == .zero else { return }
                    update(size: geometry.size, url: audioURL, configuration: configuration)
                }
                .onChange(of: geometry.size) { update(size: $0, url: audioURL, configuration: configuration) }
                .onChange(of: audioURL) { update(size: geometry.size, url: $0, configuration: configuration) }
                .onChange(of: configuration) { update(size: geometry.size, url: audioURL, configuration: $0) }
        }
    }

    private func update(size: CGSize, url: URL, configuration: Waveform.Configuration) {
        Task(priority: priority) {
            do {
                let image = try await waveformDrawer.waveformImage(fromAudioAt: url, with: configuration.with(size: size))
                await MainActor.run { waveformImage = image }
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
    }
}
