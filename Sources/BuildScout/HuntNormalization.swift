import Foundation

enum HuntNormalization {
    static func vehicleListing(
        from result: HuntResult,
        defaultLocation: String
    ) -> VehicleListing {
        var text = result.title + "\n" + result.snippet
        if let price = result.price {
            text += "\nCA$\(Int(price))"
        }
        if let odometerKM = result.odometerKM {
            text += "\n\(Int(odometerKM)) km"
        }
        if let vin = result.vin {
            text += "\nVIN \(vin)"
        }
        if !result.url.isEmpty {
            text += "\n\(result.url)"
        }

        var draft = ListingImportParser.parse(text)
        draft.source = result.provider
        draft.location = result.location ?? defaultLocation

        if let price = result.price {
            draft.price = price
        }

        var listing = draft.makeListing()
        listing.vin = result.vin ?? listing.vin
        listing.odometerKM = result.odometerKM ?? listing.odometerKM

        if let drivetrain = result.drivetrain, drivetrain != .unknown {
            listing.drivetrain = drivetrain
        }
        if let transmission = result.transmission, transmission != .unknown {
            listing.transmission = transmission
        }

        if result.kind == .auction {
            listing.strengths.append("Auction lead")
        }

        return listing
    }

    static func vehicles(
        from results: [HuntResult],
        defaultLocation: String
    ) -> [VehicleListing] {
        var seen = Set<String>()

        return results
            .filter { $0.kind == .vehicle || $0.kind == .auction }
            .map { vehicleListing(from: $0, defaultLocation: defaultLocation) }
            .filter { listing in
                let key: String
                if let vin = listing.vin, !vin.isEmpty {
                    key = "vin:\(vin)"
                } else if let url = listing.url, !url.isEmpty {
                    key = "url:\(url)"
                } else {
                    key = "\(listing.title.lowercased())|\(Int(listing.price))"
                }
                return seen.insert(key).inserted
            }
    }
}
