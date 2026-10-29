import Foundation
import XCTest
@testable import nasa_exp

final class NASAExpDecodingTests: XCTestCase {
    func test_roversDecoding_mapsCuriosityRawImage() throws {
        let json = """
        {
          "items": [
            {
              "id": 1647659,
              "imageid": "CR0_845799994EDR_F1251326CCAM01050M_",
              "sol": 5050,
              "instrument": "NAV_LEFT_B",
              "https_url": "https://mars.nasa.gov/msl-raw-images/sample.JPG",
              "date_taken": "2026-10-20T21:39:17.000Z",
              "title": "Sol 5050: Navigation Camera",
              "description": "This image was taken by Navcam onboard NASA's Mars rover Curiosity on Sol 5050.",
              "image_credit": "NASA/JPL-Caltech",
              "is_thumbnail": false,
              "extended": { "sample_type": "full" }
            }
          ],
          "more": true,
          "total": 1512633,
          "page": 0,
          "per_page": 1
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dto = try decoder.decode(MSLRawImagesResponseDTO.self, from: json)

        XCTAssertEqual(dto.items.count, 1)
        XCTAssertEqual(dto.more, true)

        let photo = RoverPhoto(dto: dto.items[0])
        XCTAssertEqual(photo.id, "msl-1647659")
        XCTAssertEqual(photo.rover, .curiosity)
        XCTAssertEqual(photo.sol, 5050)
        XCTAssertEqual(photo.cameraName, "Navcam")
        XCTAssertEqual(photo.cameraFullName, "Navigation Camera")
        XCTAssertEqual(photo.credit, "NASA/JPL-Caltech")
        XCTAssertEqual(photo.imageURL?.absoluteString, "https://mars.nasa.gov/msl-raw-images/sample.JPG")
        XCTAssertNotNil(photo.earthDate)
        XCTAssertTrue(photo.displayDate.hasPrefix("Sol 5050"))
    }

    func test_roversDecoding_acceptsStringPaginationFromMars2020Feed() throws {
        // Live shape since 2026-10-29: `per_page` is a string and an out-of-range sol adds `error_message`.
        let json = """
        {"images":[],"per_page":"24","error_message":"No more images.","total_results":0,"type":"mars2020-images-list-1.1","page":0,"mission":"mars2020","total_images":1054854}
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dto = try decoder.decode(Mars2020RawImagesResponseDTO.self, from: json)

        XCTAssertTrue(dto.images.isEmpty)
        XCTAssertEqual(dto.perPage, 24)
        XCTAssertEqual(dto.totalResults, 0)
        XCTAssertEqual(dto.page, 0)
    }

    func test_roversDecoding_mapsPerseveranceRawImage() throws {
        let json = """
        {
          "images": [
            {
              "imageid": "NLF_0100_0675835172_000ECM_N0040000NCAM00502_01_295J",
              "sol": 100,
              "camera": { "instrument": "NAVCAM_LEFT" },
              "image_files": {
                "small": "https://mars.nasa.gov/mars2020-raw-images/sample_320.jpg",
                "medium": "https://mars.nasa.gov/mars2020-raw-images/sample_800.jpg",
                "large": "https://mars.nasa.gov/mars2020-raw-images/sample_1200.jpg",
                "full_res": "https://mars.nasa.gov/mars2020-raw-images/sample.png"
              },
              "title": "Mars Perseverance Sol 100: Left Navigation Camera (Navcam)",
              "caption": "NASA's Mars Perseverance rover acquired this image using its Left Navigation Camera.",
              "credit": "NASA/JPL-Caltech",
              "date_taken_utc": "2021-06-01T14:24:18.590",
              "sample_type": "Full"
            }
          ],
          "per_page": 1,
          "total_results": 26,
          "page": 0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dto = try decoder.decode(Mars2020RawImagesResponseDTO.self, from: json)

        XCTAssertEqual(dto.images.count, 1)
        XCTAssertEqual(dto.totalResults, 26)

        let photo = RoverPhoto(dto: dto.images[0])
        XCTAssertEqual(photo.id, "m2020-NLF_0100_0675835172_000ECM_N0040000NCAM00502_01_295J")
        XCTAssertEqual(photo.rover, .perseverance)
        XCTAssertEqual(photo.sol, 100)
        XCTAssertEqual(photo.cameraName, "Navcam")
        XCTAssertEqual(photo.thumbnailURL?.absoluteString, "https://mars.nasa.gov/mars2020-raw-images/sample_320.jpg")
        XCTAssertEqual(photo.imageURL?.absoluteString, "https://mars.nasa.gov/mars2020-raw-images/sample_1200.jpg")
        XCTAssertNotNil(photo.earthDate)
    }

    func test_marsRawImagesRequest_buildsCuriosityURLWithSolAndCameraFilters() throws {
        let request = MarsRawImagesRequest(rover: .curiosity, sol: 1000, camera: .fhaz, page: 2)
        let url = try XCTUnwrap(request.url)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        XCTAssertEqual(components.host, "mars.nasa.gov")
        XCTAssertEqual(components.path, "/api/v1/raw_image_items/")
        XCTAssertEqual(query["condition_1"], "msl:mission")
        XCTAssertEqual(query["condition_2"], "1000:sol:gte")
        XCTAssertEqual(query["condition_3"], "1000:sol:lte")
        XCTAssertEqual(query["page"], "2")
        XCTAssertEqual(query["per_page"], "\(MarsRawImagesRequest.defaultPageSize)")
        XCTAssertEqual(query["search"], "FHAZ_LEFT_A|FHAZ_RIGHT_A|FHAZ_LEFT_B|FHAZ_RIGHT_B")
        XCTAssertNil(query["api_key"])
    }

    func test_marsRawImagesRequest_buildsPerseveranceURLWithoutCameraFilter() throws {
        let request = MarsRawImagesRequest(rover: .perseverance, sol: nil, camera: .all, page: 0, pageSize: 1)
        let url = try XCTUnwrap(request.url)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        XCTAssertEqual(components.path, "/rss/api/")
        XCTAssertEqual(query["category"], "mars2020")
        XCTAssertEqual(query["feedtype"], "json")
        XCTAssertEqual(query["num"], "1")
        XCTAssertNil(query["condition_2"])
        XCTAssertNil(query["search"])
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
