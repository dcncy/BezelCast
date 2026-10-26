import CoreGraphics
import XCTest
@testable import BezelCast

final class DeviceProfileTests: XCTestCase {
    func testNativeResolutionsKeepTheirFirstCatalogMatchInBothOrientations() throws {
        for profile in DeviceProfile.catalog {
            let expected = try XCTUnwrap(DeviceProfile.catalog.first { $0.screenSize == profile.screenSize })
            for size in [profile.screenSize,
                         CGSize(width: profile.screenSize.height, height: profile.screenSize.width)] {
                XCTAssertEqual(DeviceProfile.detect(for: size), expected.oriented(matching: size))
            }
        }
    }

    func testDownscaledIPadProFeedKeepsNativeGeometryInBothOrientations() throws {
        let native = try XCTUnwrap(DeviceProfile.catalog.first { $0.id == "ipad-pro-11" })
        for size in [CGSize(width: 1718, height: 1200), CGSize(width: 1200, height: 1718),
                     CGSize(width: 1719, height: 1200)] {
            XCTAssertEqual(DeviceProfile.detect(for: size), native.oriented(matching: size))
        }
    }

    func testScaledFeedsChooseTheClosestAspectBeforeCatalogOrder() throws {
        // 两款 Pro 的比例都在 1 像素误差内，应选择更接近 12.9 英寸的机型。
        XCTAssertEqual(DeviceProfile.detect(for: CGSize(width: 1601, height: 1200))?.id,
                       "ipad-pro-12-9-air-13")
        XCTAssertEqual(DeviceProfile.detect(for: CGSize(width: 1600, height: 1200))?.id,
                       "ipad-pro-13")
        XCTAssertEqual(DeviceProfile.detect(for: CGSize(width: 1741, height: 1200))?.id,
                       "ipad-pro-11-m4")
        XCTAssertEqual(DeviceProfile.detect(for: CGSize(width: 585, height: 1266))?.id,
                       "iphone-17e")
    }

    func testInvalidAndUnrelatedFrameSizesRemainUnsupported() {
        for size in [CGSize.zero, CGSize(width: -1200, height: 1718),
                     CGSize(width: CGFloat.nan, height: 1200),
                     CGSize(width: 1200, height: CGFloat.infinity),
                     CGSize(width: 1920, height: 1080), CGSize(width: 1200, height: 1200),
                     CGSize(width: 1700, height: 1200), CGSize(width: 1720, height: 1200)] {
            XCTAssertNil(DeviceProfile.detect(for: size), "\(size)")
        }
    }

    func testXRAnd11ResolutionDetectsNewestMatchingModelInBothOrientations() throws {
        // XR and 11 share a resolution; detection chooses the newest catalog
        // entry, while the bezel picker lets the user select XR explicitly.
        for size in [CGSize(width: 828, height: 1792), CGSize(width: 1792, height: 828)] {
            let detected = try XCTUnwrap(DeviceProfile.detect(for: size))
            XCTAssertEqual(detected.id, "iphone-11")
            XCTAssertEqual(detected.screenSize, size)
            XCTAssertEqual(detected.isLandscape, size.width > size.height)
        }
    }

    func testXRAnd11UseTheirNativeScaleAndWideNotchGeometry() throws {
        for id in ["iphone-xr", "iphone-11"] {
            let profile = try XCTUnwrap(DeviceProfile.catalog.first { $0.id == id }, id)
            XCTAssertEqual(profile.screenSize, CGSize(width: 828, height: 1792), id)
            XCTAssertEqual(profile.displayScale, 2, id)
            XCTAssertEqual(profile.screenCornerRadius, 83, id)
            XCTAssertEqual(profile.displayCutout, .wideNotch, id)

            let landscape = profile.oriented(matching: CGSize(width: 1792, height: 828))
            XCTAssertEqual(landscape.displayScale, 2, id)
            XCTAssertEqual(landscape.screenCornerRadius, 83, id)
            XCTAssertEqual(landscape.displayCutout, .wideNotch, id)
            XCTAssertEqual(landscape.oriented(matching: profile.screenSize), profile, id)
        }
    }
}
