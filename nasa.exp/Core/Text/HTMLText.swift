import Foundation

/// Minimal HTML-to-text conversion for feed content: drops tags, decodes entities and collapses
/// whitespace. `NSAttributedString`'s HTML importer is avoided on purpose: it needs the main
/// thread and WebKit, and feeds are parsed in the background.
nonisolated enum HTMLText {
    static func plainText(_ html: String) -> String {
        let withoutTags = html
            .replacing(#/<br\s*/?>/#.ignoresCase(), with: " ")
            .replacing(#/<[^>]*>/#, with: "")

        return decodingEntities(withoutTags)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            // Tags that wrap a word on its own line leave stray spaces ("eclipse .", "( Inst.").
            .replacing(#/ ([.,;:!?)])/#) { String($0.output.1) }
            .replacing("( ", with: "(")
    }

    /// Decodes numeric (`&#8211;`, `&#x2013;`) and the common named HTML entities.
    static func decodingEntities(_ text: String) -> String {
        guard text.contains("&") else {
            return text
        }

        return text.replacing(#/&(#[0-9]+|#[xX][0-9a-fA-F]+|[a-zA-Z]+);/#) { match in
            decodedEntity(String(match.output.1)) ?? String(match.output.0)
        }
    }

    private static func decodedEntity(_ name: String) -> String? {
        if name.hasPrefix("#x") || name.hasPrefix("#X") {
            return UInt32(name.dropFirst(2), radix: 16).flatMap(Unicode.Scalar.init).map { String(Character($0)) }
        }

        if name.hasPrefix("#") {
            return UInt32(name.dropFirst()).flatMap(Unicode.Scalar.init).map { String(Character($0)) }
        }

        return namedEntities[name]
    }

    private static let namedEntities: [String: String] = [
        "amp": "&",
        "lt": "<",
        "gt": ">",
        "quot": "\"",
        "apos": "'",
        "nbsp": " ",
        "ndash": "–",
        "mdash": "—",
        "lsquo": "‘",
        "rsquo": "’",
        "ldquo": "“",
        "rdquo": "”",
        "hellip": "…",
        "deg": "°",
        "times": "×",
        "eacute": "é",
        "aacute": "á",
        "iacute": "í",
        "oacute": "ó",
        "uacute": "ú",
        "ntilde": "ñ",
        "uuml": "ü",
        "ouml": "ö",
        "auml": "ä"
    ]
}
