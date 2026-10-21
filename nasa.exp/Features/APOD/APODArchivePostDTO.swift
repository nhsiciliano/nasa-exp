import Foundation

/// A post of the APOD category in the science.nasa.gov WordPress API
/// (`APODSource.archivePostURL(for:)`), which holds the whole archive since 1995.
nonisolated struct APODArchivePostDTO: Decodable {
    nonisolated struct Rendered: Decodable {
        let rendered: String
    }

    /// Publication time in site time (US Eastern), such as `2026-10-21T00:05:00`.
    let date: String
    let link: String?
    let title: Rendered
    /// The article page HTML, with site chrome around the explanation and credit.
    let content: Rendered
    let featuredImageUrl: String?
}

nonisolated extension APODRecord {
    init?(post: APODArchivePostDTO) {
        // Site time already is US Eastern, so the date part of `date` is the APOD day.
        let id = String(post.date.prefix(10))
        guard APODDay.isValidID(id) else {
            return nil
        }

        let page = post.content.rendered
        self.init(
            id: id,
            title: APODHTMLExtractor.title(fromHTML: post.title.rendered),
            explanation: APODHTMLExtractor.explanation(fromHTML: page),
            credit: APODHTMLExtractor.credit(fromArticleHTML: page),
            pageURL: post.link.flatMap(URL.init(string:)),
            imageURL: APODHTMLExtractor.imageURL(preferring: [post.featuredImageUrl], inHTML: page),
            videoURL: APODHTMLExtractor.videoURL(inHTML: page)
        )
    }
}
