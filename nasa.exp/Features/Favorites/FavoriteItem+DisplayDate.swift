import Foundation

extension FavoriteItem {
    /// Date line shown for this favorite, formatted for `locale` when the original date was saved.
    /// The stored `subtitle` was formatted in the language active when saving, so it is only the
    /// fallback for favorites saved before `originalDate` existed.
    func displayDate(locale: Locale = .current, timeZone: TimeZone = .current) -> String {
        guard originalDate != nil else {
            return subtitle
        }

        switch contentType {
        case .apod:
            return APODEntry(favoriteItem: self).displayDate(locale: locale, timeZone: timeZone)
        case .rover:
            return RoverPhoto(favoriteItem: self).displayDate(locale: locale, timeZone: timeZone)
        case .epic:
            return EPICEntry(favoriteItem: self).displayDate(locale: locale, timeZone: timeZone)
        }
    }
}
