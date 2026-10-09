//
//  CameraOptions.swift
//  depthOfFieldCalculator
//
//  The selectable inputs of the calculator: sensor format, aperture and
//  the unit used for entering and displaying distances.
//

import Foundation

/// A camera sensor format, characterised by the diameter of its circle of confusion.
struct SensorFormat: Identifiable, Hashable, Sendable {
    let name: String
    /// Circle of confusion diameter in millimetres.
    let circleOfConfusion: Double

    var id: String { name }

    // Circle of confusion values follow the common reference values (e.g. DOFMaster).
    static let fullFrame = SensorFormat(name: "35 mm (Full Frame)", circleOfConfusion: 0.030)
    static let apsc = SensorFormat(name: "APS-C", circleOfConfusion: 0.020)
    static let microFourThirds = SensorFormat(name: "Micro Four Thirds", circleOfConfusion: 0.015)
    static let oneInch = SensorFormat(name: "1-inch", circleOfConfusion: 0.011)

    static let all: [SensorFormat] = [.fullFrame, .apsc, .microFourThirds, .oneInch]
}

/// A lens aperture expressed as an f-number.
struct Aperture: Identifiable, Hashable, Sendable {
    let fNumber: Double

    var id: Double { fNumber }

    var label: String {
        "f/" + fNumber.formatted(.number.precision(.fractionLength(0...1)))
    }

    /// The standard full- and third-stop apertures offered by the picker.
    static let standard: [Aperture] = [1.2, 1.4, 1.8, 2, 2.8, 3.5, 4, 5.6, 8, 11, 16, 22, 32, 64]
        .map(Aperture.init)
}

/// The unit used for entering the focus distance and for displaying results.
enum DistanceUnit: String, CaseIterable, Identifiable, Sendable {
    case meters, centimeters, feet, inches

    var id: Self { self }

    var unitLength: UnitLength {
        switch self {
        case .meters: .meters
        case .centimeters: .centimeters
        case .feet: .feet
        case .inches: .inches
        }
    }

    var name: String {
        switch self {
        case .meters: "Meters"
        case .centimeters: "Centimeters"
        case .feet: "Feet"
        case .inches: "Inches"
        }
    }

    var symbol: String { unitLength.symbol }

    /// Converts a value in this unit to millimetres.
    func toMillimeters(_ value: Double) -> Double {
        Measurement(value: value, unit: unitLength).converted(to: .millimeters).value
    }

    /// Converts a value in millimetres to this unit.
    func fromMillimeters(_ millimeters: Double) -> Double {
        Measurement(value: millimeters, unit: UnitLength.millimeters).converted(to: unitLength).value
    }
}
