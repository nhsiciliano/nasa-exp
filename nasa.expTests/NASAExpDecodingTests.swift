import Foundation
import XCTest
@testable import nasa_exp

final class NASAExpDecodingTests: XCTestCase {
    func test_apodDecoding_mapsImageMediaCorrectly() throws {
        let json = """
        {
          "date": "2026-03-13",
          "explanation": "Sample APOD explanation for decoder tests.",
          "media_type": "image",
          "title": "Sample APOD",
          "url": "https://apod.nasa.gov/apod/image/2603/sample.jpg",
          "hdurl": "https://apod.nasa.gov/apod/image/2603/sample_hd.jpg",
          "copyright": "NASA"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dto = try decoder.decode(APODResponseDTO.self, from: json)
        let entry = APODEntry(dto: dto)

        XCTAssertEqual(entry.id, "2026-03-13")
        XCTAssertEqual(entry.title, "Sample APOD")
        XCTAssertEqual(entry.copyright, "NASA")

        switch entry.media {
        case let .image(url):
            XCTAssertTrue(url.absoluteString.contains("sample_hd.jpg"))
        default:
            XCTFail("Expected image media")
        }
    }

    func test_roversDecoding_mapsCameraAndDate() throws {
        let json = """
        {
          "photos": [
            {
              "id": 123456,
              "img_src": "https://mars.nasa.gov/msl-raw-images/sample.jpg",
              "earth_date": "2026-03-10",
              "camera": {
                "name": "NAVCAM",
                "full_name": "Navigation Camera"
              },
              "rover": {
                "name": "Curiosity",
                "status": "active",
                "launch_date": "2011-11-26",
                "landing_date": "2012-08-06"
              }
            }
          ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dto = try decoder.decode(RoverPhotosResponseDTO.self, from: json)

        XCTAssertEqual(dto.photos.count, 1)

        let photo = RoverPhoto(dto: dto.photos[0])
        XCTAssertEqual(photo.id, 123456)
        XCTAssertEqual(photo.cameraName, "NAVCAM")
        XCTAssertEqual(photo.cameraFullName, "Navigation Camera")
        XCTAssertEqual(photo.roverName, "Curiosity")
        XCTAssertNotNil(photo.imageURL)
    }

    func test_epicDecoding_buildsArchiveImageURL() throws {
        let json = """
        [
          {
            "identifier": "202603130001",
            "caption": "Sample EPIC caption for tests",
            "image": "epic_1b_202603130001",
            "date": "2026-03-13 00:01:00",
            "centroid_coordinates": {
              "lat": 12.34,
              "lon": -56.78
            }
          }
        ]
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dto = try decoder.decode([EPICEntryDTO].self, from: json)

        XCTAssertEqual(dto.count, 1)

        let entry = EPICEntry(dto: dto[0])
        XCTAssertTrue(entry.title.contains("202603130001"))
        XCTAssertEqual(entry.latitude, 12.34, accuracy: 0.001)
        XCTAssertEqual(entry.longitude, -56.78, accuracy: 0.001)
        XCTAssertNotNil(entry.imageURL)
        XCTAssertTrue(entry.imageURL?.absoluteString.contains("epic_1b_202603130001") == true)
    }
}
