import TroposCore
import Quick
import Nimble

private let testCacheFileName = "TestWeatherUpdate"

private var testCachesDirectory: URL {
    // swiftlint:disable:next force_try
    return try! FileManager.default
        .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
}

private var testWeatherUpdateURL: URL {
    return testCachesDirectory.appendingPathComponent(testCacheFileName)
}

private func resetFilesystem(file: StaticString = #file, line: UInt = #line) {
    do {
        try FileManager.default.removeItem(at: testWeatherUpdateURL)
    } catch CocoaError.fileNoSuchFile {
        // already doesn't exist
    } catch POSIXError.ENOENT {
        // same
    } catch {
        XCTFail("\(error)", file: file, line: line)
    }
}

final class WeatherUpdateCacheSpec: QuickSpec {
    override func spec() {
        describe("TRWeatherUpdateCache") {
            beforeEach { resetFilesystem() }
            afterEach { resetFilesystem() }

            context("-archiveLatestWeatherUpdate") {
                it("archives the object to disk") {
                    let cache = WeatherUpdateCache(fileName: testCacheFileName, inDirectory: testCachesDirectory)
                    let update = WeatherUpdate(
                        placemark: testPlacemark,
                        currentConditionsJSON: [:],
                        yesterdaysConditionsJSON: [:]
                    )!

                    expect(cache.archiveWeatherUpdate(update)).to(beTrue())

                    expect(FileManager.default.isReadableFile(atPath: testWeatherUpdateURL.path)).to(beTrue())
                }
            }

            context("-latestWeatherUpdate") {
                it("returns nil when not archived") {
                    let cache = WeatherUpdateCache(fileName: testCacheFileName, inDirectory: testCachesDirectory)
                    expect(cache.latestWeatherUpdate).to(beNil())
                }

                it("returns an initialized TRWeatherUpdate when archive exists") {
                    let cache = WeatherUpdateCache(fileName: testCacheFileName, inDirectory: testCachesDirectory)
                    let update = WeatherUpdate(
                        placemark: testPlacemark,
                        currentConditionsJSON: [:],
                        yesterdaysConditionsJSON: [:]
                    )!

                    let success = cache.archiveWeatherUpdate(update)

                    expect(success).to(beTruthy())
                    expect(cache.latestWeatherUpdate).to(beAKindOf(WeatherUpdate.self))
                }

                it("caches the date") {
                    let cache = WeatherUpdateCache(fileName: testCacheFileName, inDirectory: testCachesDirectory)
                    let date = Date(timeIntervalSince1970: 0)
                    let update = WeatherUpdate(
                        placemark: testPlacemark,
                        currentConditionsJSON: [:],
                        yesterdaysConditionsJSON: [:],
                        date: date
                    )!

                    cache.archiveWeatherUpdate(update)

                    expect(cache.latestWeatherUpdate?.date) == date
                }
            }
        }
    }
}
