//
//  LocationPrivacy.swift
//  AntiSocial
//
//  Never expose exact GPS of another user. Store only coarse coordinates.
//

import Foundation
import CoreLocation

public struct LocationPrivacy {
    /// ~1.1 km grid. Exact GPS is never persisted.
    public static let coordinateDecimals = 2
    public static let geohashPrecision = 5

    public static func coarsen(coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: coarsen(coordinate.latitude),
            longitude: coarsen(coordinate.longitude)
        )
    }

    public static func coarsen(_ value: Double) -> Double {
        let factor = pow(10.0, Double(coordinateDecimals))
        return (value * factor).rounded() / factor
    }

    public static func approximateDistanceKilometers(
        fromLatitude: Double?,
        fromLongitude: Double?,
        toLatitude: Double?,
        toLongitude: Double?
    ) -> Double? {
        guard let fromLatitude, let fromLongitude, let toLatitude, let toLongitude else {
            return nil
        }
        let from = CLLocation(latitude: fromLatitude, longitude: fromLongitude)
        let to = CLLocation(latitude: toLatitude, longitude: toLongitude)
        return from.distance(from: to) / 1000.0
    }

    public static func distanceLabel(kilometers: Double?, collegeHint: String? = nil) -> String {
        guard let kilometers else {
            if let collegeHint, !collegeHint.isEmpty {
                return "Near \(collegeHint)"
            }
            return "Distance unavailable"
        }
        if kilometers < 0.2 {
            return "< 0.2 km away"
        }
        return String(format: "%.1f km away", kilometers)
    }

    public static func geohash(for coordinate: CLLocationCoordinate2D, precision: Int = geohashPrecision) -> String {
        GeoHash.encode(latitude: coordinate.latitude, longitude: coordinate.longitude, precision: precision)
    }

    public static func neighborPrefixes(for geohash: String) -> [String] {
        GeoHash.neighborsIncludingSelf(geohash)
    }
}

public struct GeoHash {
    private static let base32 = Array("0123456789bcdefghjkmnpqrstuvwxyz")

    public static func encode(latitude: Double, longitude: Double, precision: Int) -> String {
        var minLat = -90.0, maxLat = 90.0
        var minLon = -180.0, maxLon = 180.0
        var hash = ""
        var bit = 0
        var ch = 0
        var even = true

        while hash.count < precision {
            if even {
                let mid = (minLon + maxLon) / 2
                if longitude >= mid {
                    ch |= 1 << (4 - bit)
                    minLon = mid
                } else {
                    maxLon = mid
                }
            } else {
                let mid = (minLat + maxLat) / 2
                if latitude >= mid {
                    ch |= 1 << (4 - bit)
                    minLat = mid
                } else {
                    maxLat = mid
                }
            }
            even.toggle()
            if bit < 4 {
                bit += 1
            } else {
                hash.append(base32[ch])
                bit = 0
                ch = 0
            }
        }
        return hash
    }

    public static func neighborsIncludingSelf(_ hash: String) -> [String] {
        guard !hash.isEmpty else { return [] }
        let decoded = decode(hash)
        let latStep = (decoded.maxLat - decoded.minLat)
        let lonStep = (decoded.maxLon - decoded.minLon)
        let centerLat = (decoded.minLat + decoded.maxLat) / 2
        let centerLon = (decoded.minLon + decoded.maxLon) / 2
        var values = Set<String>()
        for dLat in [-1.0, 0.0, 1.0] {
            for dLon in [-1.0, 0.0, 1.0] {
                values.insert(encode(
                    latitude: centerLat + dLat * latStep,
                    longitude: centerLon + dLon * lonStep,
                    precision: hash.count
                ))
            }
        }
        return Array(values)
    }

    private static func decode(_ hash: String) -> (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) {
        var minLat = -90.0, maxLat = 90.0
        var minLon = -180.0, maxLon = 180.0
        var even = true
        for character in hash.lowercased() {
            guard let index = base32.firstIndex(of: character) else { continue }
            for i in stride(from: 4, through: 0, by: -1) {
                let bit = (index >> i) & 1
                if even {
                    let mid = (minLon + maxLon) / 2
                    if bit == 1 { minLon = mid } else { maxLon = mid }
                } else {
                    let mid = (minLat + maxLat) / 2
                    if bit == 1 { minLat = mid } else { maxLat = mid }
                }
                even.toggle()
            }
        }
        return (minLat, maxLat, minLon, maxLon)
    }
}
