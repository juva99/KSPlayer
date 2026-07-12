@testable import KSPlayer
import XCTest

final class DolbyVisionConfigurationTests: XCTestCase {
    func testProfile5ConfigurationAtom() {
        let record = doviRecord(
            profile: 5, level: 7, rpu: 1,
            enhancementLayer: 0, baseLayer: 0, compatibility: 0
        )

        XCTAssertEqual(record.configurationAtomKey, "dvcC")
        XCTAssertEqual(record.configurationAtomData,
                       Data([0x01, 0x00, 0x0A, 0x3C, 0x00] + Array(repeating: 0, count: 19)))
        XCTAssertTrue(record.supportsNativeVideoToolboxDecode)
        XCTAssertFalse(record.usesBaseLayerFallback)
    }

    func testProfile8ConfigurationAtom() {
        let record = doviRecord(
            profile: 8, level: 6, rpu: 1,
            enhancementLayer: 0, baseLayer: 1, compatibility: 1
        )

        XCTAssertEqual(record.configurationAtomKey, "dvvC")
        XCTAssertEqual(record.configurationAtomData,
                       Data([0x01, 0x00, 0x10, 0x35, 0x10] + Array(repeating: 0, count: 19)))
        XCTAssertTrue(record.supportsNativeVideoToolboxDecode)
        XCTAssertFalse(record.usesBaseLayerFallback)
    }

    func testProfile7UsesBaseLayerFallback() {
        let record = doviRecord(
            profile: 7, level: 6, rpu: 1,
            enhancementLayer: 1, baseLayer: 1, compatibility: 6
        )

        XCTAssertEqual(record.configurationAtomKey, "dvcC")
        XCTAssertEqual(record.configurationAtomData,
                       Data([0x01, 0x00, 0x0E, 0x37, 0x60] + Array(repeating: 0, count: 19)))
        XCTAssertFalse(record.supportsNativeVideoToolboxDecode)
        XCTAssertTrue(record.usesBaseLayerFallback)
    }

    private func doviRecord(profile: UInt8, level: UInt8, rpu: UInt8,
                            enhancementLayer: UInt8, baseLayer: UInt8,
                            compatibility: UInt8) -> DOVIDecoderConfigurationRecord
    {
        DOVIDecoderConfigurationRecord(
            dv_version_major: 1,
            dv_version_minor: 0,
            dv_profile: profile,
            dv_level: level,
            rpu_present_flag: rpu,
            el_present_flag: enhancementLayer,
            bl_present_flag: baseLayer,
            dv_bl_signal_compatibility_id: compatibility
        )
    }
}
