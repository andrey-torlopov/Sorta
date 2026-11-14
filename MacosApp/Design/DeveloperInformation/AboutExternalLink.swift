import Foundation

struct AboutExternalLink: Identifiable, Equatable {
    let id: String
    let titleKey: String
    let symbol: String
    let address: String
    let displayAddress: String

    var descriptionKey: String? = nil

    var url: URL? { URL(string: address) }
}
