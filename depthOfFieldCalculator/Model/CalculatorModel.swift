//
//  CalculatorModel.swift
//  depthOfFieldCalculator
//
//  Observable state for the calculator screen. Holds the user's inputs,
//  derives the depth of field from them and remembers them between launches.
//

import Foundation
import Observation

@Observable
final class CalculatorModel {
    static let defaultSensor: SensorFormat = .fullFrame
    static let defaultAperture: Aperture = Aperture.standard[5] // f/3.5
    static let defaultFocalLength: Double = 28
    static let defaultFocusDistance: Double = 8
    static let defaultUnit: DistanceUnit = .meters

    /// Focal lengths offered by the slider, in millimetres.
    static let focalLengthRange: ClosedRange<Double> = 8...800
    /// Focus distances offered by the slider, in millimetres.
    static let focusDistanceRangeInMillimeters: ClosedRange<Double> = 100...100_000

    var sensor: SensorFormat { didSet { save() } }
    var aperture: Aperture { didSet { save() } }
    /// Lens focal length in millimetres.
    var focalLength: Double { didSet { save() } }
    /// Focus distance in the currently selected `unit`.
    var focusDistance: Double { didSet { save() } }
    /// Changing the unit converts the focus distance so the physical distance is unchanged.
    var unit: DistanceUnit {
        didSet {
            if unit != oldValue {
                focusDistance = unit.fromMillimeters(oldValue.toMillimeters(focusDistance))
            }
            save()
        }
    }

    /// Focus distances offered by the slider, in the selected unit.
    var focusDistanceRange: ClosedRange<Double> {
        unit.fromMillimeters(Self.focusDistanceRangeInMillimeters.lowerBound)
            ... unit.fromMillimeters(Self.focusDistanceRangeInMillimeters.upperBound)
    }

    @ObservationIgnored private let defaults: UserDefaults

    private enum Key {
        static let sensor = "sensor"
        static let aperture = "aperture"
        static let focalLength = "focalLength"
        static let focusDistance = "focusDistance"
        static let unit = "unit"
    }

    /// Restores the last used values from `defaults`, falling back to the app defaults.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        sensor = SensorFormat.all.first { $0.id == defaults.string(forKey: Key.sensor) } ?? Self.defaultSensor
        aperture = Aperture.standard.first { $0.fNumber == defaults.double(forKey: Key.aperture) } ?? Self.defaultAperture
        focalLength = defaults.object(forKey: Key.focalLength) as? Double ?? Self.defaultFocalLength
        focusDistance = defaults.object(forKey: Key.focusDistance) as? Double ?? Self.defaultFocusDistance
        unit = defaults.string(forKey: Key.unit).flatMap(DistanceUnit.init(rawValue:)) ?? Self.defaultUnit
    }

    private func save() {
        defaults.set(sensor.id, forKey: Key.sensor)
        defaults.set(aperture.fNumber, forKey: Key.aperture)
        defaults.set(focalLength, forKey: Key.focalLength)
        defaults.set(focusDistance, forKey: Key.focusDistance)
        defaults.set(unit.rawValue, forKey: Key.unit)
    }

    func resetToDefaults() {
        sensor = Self.defaultSensor
        aperture = Self.defaultAperture
        focalLength = Self.defaultFocalLength
        focusDistance = Self.defaultFocusDistance
        unit = Self.defaultUnit
    }

    var depthOfField: DepthOfField? {
        DepthOfField(
            circleOfConfusion: sensor.circleOfConfusion,
            fNumber: aperture.fNumber,
            focalLength: focalLength,
            focusDistance: unit.toMillimeters(focusDistance)
        )
    }

    /// Focus distance in millimetres.
    var focusDistanceInMillimeters: Double {
        unit.toMillimeters(focusDistance)
    }

    /// The focal length formatted in millimetres, e.g. "28 mm".
    var formattedFocalLength: String {
        Measurement(value: focalLength, unit: UnitLength.millimeters)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided,
                                    numberFormatStyle: .number.precision(.fractionLength(0))))
    }

    /// Formats a distance given in millimetres in the selected unit, e.g. "3.74 m".
    /// `nil` stands for infinity.
    func formatted(millimeters: Double?, locale: Locale = .autoupdatingCurrent) -> String {
        guard let millimeters else { return "∞" }
        return Measurement(value: unit.fromMillimeters(millimeters), unit: unit.unitLength)
            .formatted(.measurement(
                width: .abbreviated,
                usage: .asProvided,
                numberFormatStyle: .number.precision(.fractionLength(2))
            ).locale(locale))
    }
}
