@testable import KSPlayer
import CoreMedia
import CoreVideo
import XCTest

final class HDR10MKVFixtureTests: XCTestCase {
    private var player: KSMEPlayer?
    private var readyExpectation: XCTestExpectation?

    @MainActor
    func testPhoneRecordedHDR10MKV() {
        guard let url = Bundle.module.url(forResource: "hdr10-h264-4k", withExtension: "mkv") else {
            XCTFail("The HDR10 MKV fixture is missing from the test bundle")
            return
        }
        let options = KSOptions()

        let player = KSMEPlayer(url: url, options: options)
        self.player = player
        player.delegate = self
        readyExpectation = expectation(description: "open HDR10 MKV")
        player.prepareToPlay()

        waitForExpectations(timeout: 15) { error in
            XCTAssertNil(error)
            XCTAssertTrue(player.isReadyToPlay)

            let videoTrack = player.tracks(mediaType: .video).first { $0.isEnabled }
            XCTAssertNotNil(videoTrack)
            XCTAssertEqual(videoTrack?.codecType, kCMVideoCodecType_H264)
            XCTAssertEqual(videoTrack?.dynamicRange, .hdr10)
            XCTAssertEqual(videoTrack?.colorPrimaries, kCVImageBufferColorPrimaries_ITU_R_2020 as String)
            XCTAssertEqual(videoTrack?.transferFunction, kCVImageBufferTransferFunction_SMPTE_ST_2084_PQ as String)
            XCTAssertEqual(videoTrack?.yCbCrMatrix, kCVImageBufferYCbCrMatrix_ITU_R_2020 as String)
        }
    }

    override func tearDown() {
        player?.shutdown()
        player = nil
        readyExpectation = nil
        super.tearDown()
    }
}

extension HDR10MKVFixtureTests: MediaPlayerDelegate {
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
            XCTFail("Failed to open HDR10 MKV: \(error)")
            readyExpectation?.fulfill()
        }
    }
}
