import Foundation

/// Pulls APOD fields out of science.nasa.gov HTML: the RSS item fields and the WordPress article
/// page, which wraps the same content in site chrome.
nonisolated enum APODHTMLExtractor {
    /// The explanation paragraph as plain text, without its "Explanation:" label (some entries
    /// repeat it) and without the "Tomorrow's picture:" teaser both sources append to it.
    static func explanation(fromHTML html: String) -> String {
        let paragraph = html
            .firstMatch(of: #/<strong>\s*Explanation:\s*</strong>(.*?)(?:</p>|$)/#.dotMatchesNewlines().ignoresCase())
            .map { String($0.output.1) } ?? html

        return HTMLText.plainText(paragraph)
            .replacing(#/^(?:Explanation\s*:\s*)+/#.ignoresCase(), with: "")
            .replacing(#/\s*Tomorrow['’]s picture:.*$/#.ignoresCase(), with: "")
    }

    /// The credit row of an article page ("Credit & Copyright:", "Credit:", ...), as plain text.
    static func credit(fromArticleHTML html: String) -> String? {
        let rows = html.matches(of: #/<th[^>]*>(.*?)</th>\s*<td[^>]*>(.*?)</td>/#.dotMatchesNewlines())

        for row in rows {
            let label = HTMLText.plainText(String(row.output.1)).lowercased()
            if label.contains("credit") || label.contains("copyright") {
                return credit(fromHTML: String(row.output.2))
            }
        }

        return nil
    }

    /// A credit as plain text, without a leading label such as "Image Credit:" or
    /// "Credit & Copyright:" (archive pages repeat it inside the value).
    static func credit(fromHTML html: String) -> String? {
        let credit = HTMLText.plainText(html)
            .replacing(#/^[^:]{0,40}(credit|copyright)[^:]{0,40}:\s*/#.ignoresCase(), with: "")

        return credit.isEmpty ? nil : credit
    }

    /// A title without the "APOD: 2026 October 21 – " prefix of WordPress post titles.
    static func title(fromHTML html: String) -> String {
        HTMLText.plainText(html)
            .replacing(#/^APOD:\s*\d{4}\s+\p{L}+\s+\d{1,2}\s*[–—-]\s*/#, with: "")
    }

    /// The player of a video entry: the first `<iframe>` source, made absolute with `https:`.
    static func videoURL(inHTML html: String) -> URL? {
        guard let match = html.firstMatch(of: #/<iframe\b[^>]*\bsrc\s*=\s*["']([^"']+)["']/#.ignoresCase()) else {
            return nil
        }

        var source = HTMLText.decodingEntities(String(match.output.1))
        if source.hasPrefix("//") {
            source = "https:" + source
        }

        guard let url = URL(string: source), url.scheme == "https" || url.scheme == "http" else {
            return nil
        }

        return url
    }

    /// The entry's picture, as the full-size original, from `candidates` (explicit fields such as
    /// `apod:hdurl` or the featured image) and the `<img>` sources of `html`, in this order:
    /// 1. a candidate the page also shows,
    /// 2. the page's own images,
    /// 3. a candidate alone (some pages carry no `<img>`).
    /// Only NASA asset images count, and never the WordPress placeholder (`APODImageURL.isAPODImage`).
    /// Ranking the page first keeps a site-wide default image in a candidate field from winning over
    /// the article's picture.
    static func imageURL(preferring candidates: [String?], inHTML html: String) -> URL? {
        let explicitImages = imageURLs(candidates.compactMap { $0 })
        let pageImages = imageURLs(
            html
                .matches(of: #/<img\b[^>]*\bsrc\s*=\s*["']([^"']+)["']/#.ignoresCase())
                .map { String($0.output.1) }
        )
        let pageOriginals = Set(pageImages.map(APODImageURL.original))
        let shownOnPage = explicitImages.filter { pageOriginals.contains(APODImageURL.original($0)) }

        return (shownOnPage + pageImages + explicitImages)
            .first
            .map(APODImageURL.original)
    }

    private static func imageURLs(_ sources: [String]) -> [URL] {
        sources
            .compactMap { URL(string: HTMLText.decodingEntities($0)) }
            .filter(APODImageURL.isAPODImage)
    }
}
