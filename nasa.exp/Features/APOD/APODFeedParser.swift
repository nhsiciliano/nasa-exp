import Foundation

/// Parses the "APOD Basic" RSS feed (`APODSource.feedURL`) into records, newest first.
nonisolated enum APODFeedParser {
    static func records(from data: Data) throws -> [APODRecord] {
        let collector = ItemCollector()
        let parser = XMLParser(data: data)
        parser.delegate = collector

        guard parser.parse() else {
            throw NASAAPIError.decodingError(parser.parserError ?? CocoaError(.coderReadCorrupt))
        }

        return collector.items.compactMap(record(from:))
    }

    /// Builds a record from the text of an `<item>`'s child elements, keyed by qualified name.
    static func record(from item: [String: String]) -> APODRecord? {
        guard let title = item["title"],
              let published = item["pubDate"].flatMap(pubDateFormatter.date(from:)) else {
            return nil
        }

        // `content:encoded` is the full article page; videos only show up there, as an <iframe>.
        let page = item["content:encoded"] ?? ""

        return APODRecord(
            // `pubDate` is UTC (04:05Z); the APOD day is the New York day it was published on.
            id: APODDay.id(for: published),
            title: HTMLText.plainText(title),
            explanation: APODHTMLExtractor.explanation(fromHTML: item["apod:explanation"] ?? item["description"] ?? ""),
            credit: APODHTMLExtractor.credit(fromHTML: item["apod:credit"] ?? item["apod:copyright"] ?? ""),
            pageURL: (item["link"] ?? item["apod:url"]).flatMap(URL.init(string:)),
            imageURL: APODHTMLExtractor.imageURL(preferring: [item["apod:hdurl"]], inHTML: page),
            videoURL: APODHTMLExtractor.videoURL(inHTML: page)
        )
    }

    private static let pubDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return formatter
    }()

    /// Collects the text of each `<item>` child; CDATA blocks keep their HTML as is.
    nonisolated private final class ItemCollector: NSObject, XMLParserDelegate {
        private(set) var items: [[String: String]] = []
        private var currentItem: [String: String]?
        private var text = ""

        func parser(
            _ parser: XMLParser,
            didStartElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?,
            attributes attributeDict: [String: String] = [:]
        ) {
            if elementName == "item" {
                currentItem = [:]
            }
            text = ""
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            text += string
        }

        func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
            text += String(decoding: CDATABlock, as: UTF8.self)
        }

        func parser(
            _ parser: XMLParser,
            didEndElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?
        ) {
            if elementName == "item" {
                if let currentItem {
                    items.append(currentItem)
                }
                currentItem = nil
            } else if currentItem != nil {
                currentItem?[elementName] = text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            text = ""
        }
    }
}
