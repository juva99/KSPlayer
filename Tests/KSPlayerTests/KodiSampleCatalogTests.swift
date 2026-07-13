@testable import KSPlayer
import CoreMedia
import Foundation
import XCTest

final class KodiSampleCatalogTests: XCTestCase {
    private var player: KSMEPlayer?
    private var readyExpectation: XCTestExpectation?

    func testCatalogContainsAllRequestedSamples() throws {
        let samples = try loadSamples()

        XCTAssertEqual(samples.count, 43)
        XCTAssertEqual(Set(samples.map(\.id)).count, samples.count)
        XCTAssertTrue(samples.allSatisfy { URL(string: $0.url)?.scheme == "https" })
        XCTAssertTrue(samples.allSatisfy { !$0.fileName.isEmpty })
    }

    // This is intentionally opt-in: Kodi's samples are large, externally hosted fixtures.
    @MainActor
    func testSelectedLocalKodiSamplesOpen() throws {
        guard let directory = ProcessInfo.processInfo.environment["KSPLAYER_KODI_SAMPLES_DIRECTORY"] else {
            throw XCTSkip("Set KSPLAYER_KODI_SAMPLES_DIRECTORY to run local Kodi sample smoke tests.")
        }
        let selectedIDs = Set((ProcessInfo.processInfo.environment["KSPLAYER_KODI_SAMPLE_IDS"] ?? "")
            .split(separator: ",").map { String($0) })
        let samples = try loadSamples().filter { selectedIDs.isEmpty || selectedIDs.contains($0.id) }
        XCTAssertFalse(samples.isEmpty, "No Kodi samples matched KSPLAYER_KODI_SAMPLE_IDS")

        for sample in samples {
            let fileURL = URL(fileURLWithPath: directory).appendingPathComponent(sample.fixtureFileName)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                XCTFail("Missing \(sample.fixtureFileName); create it from \(sample.url)")
                continue
            }
            let player = KSMEPlayer(url: fileURL, options: KSOptions())
            self.player = player
            player.delegate = self
            readyExpectation = expectation(description: "open \(sample.name)")
            player.prepareToPlay()
            waitForExpectations(timeout: 15)
            XCTAssertTrue(player.isReadyToPlay, "Could not open \(sample.name)")
            if sample.id == "vp9-p2-hdr10plus" {
                XCTAssertEqual(player.tracks(mediaType: .video).first { $0.isEnabled }?.codecType, kCMVideoCodecType_VP9)
            }
            player.shutdown()
            self.player = nil
            readyExpectation = nil
        }
    }

    override func tearDown() {
        player?.shutdown()
        player = nil
        readyExpectation = nil
        super.tearDown()
    }

    private func loadSamples() throws -> [KodiSample] {
        guard let url = Bundle.module.url(forResource: "kodi-samples", withExtension: "json") else {
            throw NSError(domain: "KodiSampleCatalogTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Kodi sample catalog is missing"])
        }
        return try JSONDecoder().decode([KodiSample].self, from: Data(contentsOf: url))
    }
}

extension KodiSampleCatalogTests: MediaPlayerDelegate {
    @MainActor
    func readyToPlay(player _: some MediaPlayerProtocol) {
        readyExpectation?.fulfill()
    }

    @MainActor
    func changeLoadState(player _: some MediaPlayerProtocol) {}

    @MainActor
    func changeBuffering(player _: some MediaPlayerProtocol, progress _: Int) {}

    @MainActor
    func playBack(player _: some MediaPlayerProtocol, loopCount _: Int) {}

    @MainActor
    func finish(player _: some MediaPlayerProtocol, error: Error?) {
        if let error {
            XCTFail("Failed to open Kodi sample: \(error)")
            readyExpectation?.fulfill()
        }
    }
}

private struct KodiSample: Decodable {
    let id: String
    let name: String
    let container: String
    let fileName: String
    let url: String

    var fixtureFileName: String {
        "\(id)-3s.\((fileName as NSString).pathExtension)"
    }
}
