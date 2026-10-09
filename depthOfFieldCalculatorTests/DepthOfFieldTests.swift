//
//  DepthOfFieldTests.swift
//  depthOfFieldCalculatorTests
//
//  Checks the calculation engine against the textbook thin-lens formulas
//  and the near/far limits produced by the original UIKit implementation.
//

import Foundation
import Testing
@testable import depthOfFieldCalculator

struct DepthOfFieldTests {

    /// 28 mm, f/3.5, c = 0.032 (the original app's full-frame value), focused at 8 m.
    @Test func legacyDefaultInputsReachInfinity() throws {
        let dof = try #require(DepthOfField(
            circleOfConfusion: 0.032,
            fNumber: 3.5, focalLength: 28, focusDistance: 8000
        ))

        #expect(dof.hyperfocal.isApproximately(7028))
        #expect(dof.near.isApproximately(3740.31))
        #expect(dof.far == nil)
        #expect(dof.total == nil)
        #expect(dof.isInfinite)
    }

    /// Same lens focused at 2 m yields a finite zone on both sides of the subject.
    @Test func legacyCloseFocusIsFinite() throws {
        let dof = try #require(DepthOfField(
            circleOfConfusion: 0.032,
            fNumber: 3.5, focalLength: 28, focusDistance: 2000
        ))

        #expect(dof.near.isApproximately(1560.41))
        #expect(try #require(dof.far).isApproximately(2784.41))
        #expect(try #require(dof.total).isApproximately(1224.00))
        #expect(!dof.isInfinite)
    }

    @Test func subjectExactlyAtHyperfocalIsInfinite() throws {
        // H = f²/(N·c) + f = 7000 + 28 = 7028 mm, so a subject there is exactly on the boundary.
        let dof = try #require(DepthOfField(
            circleOfConfusion: 0.032, fNumber: 3.5, focalLength: 28, focusDistance: 7028
        ))
        #expect(dof.hyperfocal.isApproximately(7028))
        #expect(dof.far == nil)
        // Focusing at the hyperfocal distance gives a near limit of H / 2.
        #expect(dof.near.isApproximately(3514))
    }

    /// DOFMaster reference: 35 mm, 50 mm lens, f/8, focused at 3 m, c = 0.03 mm.
    @Test func matchesDOFMasterReference() throws {
        let dof = try #require(DepthOfField(
            circleOfConfusion: SensorFormat.fullFrame.circleOfConfusion,
            fNumber: 8, focalLength: 50, focusDistance: 3000
        ))
        #expect(dof.hyperfocal.isApproximately(10467, tolerance: 1))
        #expect(dof.near.isApproximately(2338, tolerance: 1))
        #expect(try #require(dof.far).isApproximately(4185, tolerance: 1))
    }

    @Test func sensorConstantsMatchReferenceValues() {
        #expect(SensorFormat.fullFrame.circleOfConfusion == 0.030)
        #expect(SensorFormat.apsc.circleOfConfusion == 0.020)
        #expect(SensorFormat.microFourThirds.circleOfConfusion == 0.015)
        #expect(SensorFormat.oneInch.circleOfConfusion == 0.011)
    }

    @Test func smallerSensorHasShallowerHyperfocal() throws {
        let fullFrame = try #require(DepthOfField(
            circleOfConfusion: SensorFormat.fullFrame.circleOfConfusion,
            fNumber: 8, focalLength: 50, focusDistance: 3000
        ))
        let apsc = try #require(DepthOfField(
            circleOfConfusion: SensorFormat.apsc.circleOfConfusion,
            fNumber: 8, focalLength: 50, focusDistance: 3000
        ))
        #expect(apsc.hyperfocal > fullFrame.hyperfocal)
        #expect(try #require(apsc.total) < #require(fullFrame.total))
    }

    @Test(arguments: [
        (focalLength: 0.0, focusDistance: 1000.0),
        (focalLength: -28.0, focusDistance: 1000.0),
        (focalLength: 28.0, focusDistance: 28.0),
        (focalLength: 28.0, focusDistance: 10.0),
        (focalLength: .nan, focusDistance: 1000.0),
    ])
    func rejectsInvalidInputs(focalLength: Double, focusDistance: Double) {
        #expect(DepthOfField(
            circleOfConfusion: 0.032, fNumber: 4, focalLength: focalLength, focusDistance: focusDistance
        ) == nil)
    }
}

struct DistanceUnitTests {
    @Test func roundTripsThroughMillimeters() {
        for unit in DistanceUnit.allCases {
            #expect(unit.fromMillimeters(unit.toMillimeters(12.5)).isApproximately(12.5, tolerance: 1e-9))
        }
    }

    @Test func conversionFactorsMatchLegacyValues() {
        #expect(DistanceUnit.meters.toMillimeters(1).isApproximately(1000))
        #expect(DistanceUnit.centimeters.toMillimeters(100).isApproximately(1000))
        #expect(DistanceUnit.feet.toMillimeters(3.2808).isApproximately(1000, tolerance: 0.1))
        #expect(DistanceUnit.inches.toMillimeters(39.37).isApproximately(1000, tolerance: 0.1))
    }
}

struct CalculatorModelTests {
    /// A model backed by a throwaway defaults suite so tests never share persisted state.
    private func isolatedModel() throws -> CalculatorModel {
        CalculatorModel(defaults: try #require(UserDefaults(suiteName: "CalculatorModelTests.\(UUID())")))
    }

    @Test func formatsInSelectedUnit() throws {
        let model = try isolatedModel()
        let enUS = Locale(identifier: "en_US")
        model.unit = .meters
        #expect(model.formatted(millimeters: 3740.31, locale: enUS) == "3.74 m")
        model.unit = .feet
        #expect(model.formatted(millimeters: 3740.31, locale: enUS) == "12.27 ft")
        #expect(model.formatted(millimeters: nil) == "∞")
    }

    @Test func respectsLocaleDecimalSeparator() throws {
        let model = try isolatedModel()
        model.unit = .meters
        #expect(model.formatted(millimeters: 3740.31, locale: Locale(identifier: "de_DE")) == "3,74 m")
    }

    @Test func changingUnitKeepsThePhysicalDistance() throws {
        let model = try isolatedModel()
        model.unit = .meters
        model.focusDistance = 2
        model.unit = .centimeters
        #expect(model.focusDistance.isApproximately(200, tolerance: 1e-9))
        model.unit = .feet
        #expect(model.focusDistance.isApproximately(6.5617, tolerance: 1e-3))
        #expect(model.focusDistanceInMillimeters.isApproximately(2000, tolerance: 1e-6))
    }

    @Test func focusCloserThanFocalLengthProducesNoResult() throws {
        let model = try isolatedModel()
        model.unit = .centimeters
        model.focalLength = 400
        model.focusDistance = 20
        #expect(model.depthOfField == nil)
    }

    @Test func sliderRoundingKeepsThreeSignificantDigits() {
        let round = LogarithmicSlider.significantDigits(3)
        #expect(round(3.14159).isApproximately(3.14, tolerance: 1e-9))
        #expect(round(0.123456).isApproximately(0.123, tolerance: 1e-9))
        #expect(round(1234.5).isApproximately(1230, tolerance: 1e-9))
    }
}

private extension Double {
    func isApproximately(_ other: Double, tolerance: Double = 0.01) -> Bool {
        abs(self - other) <= tolerance
    }
}

struct PersistenceTests {
    private func freshDefaults() throws -> UserDefaults {
        let suite = "PersistenceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func startsWithDefaultsWhenNothingIsStored() throws {
        let model = CalculatorModel(defaults: try freshDefaults())
        #expect(model.sensor == CalculatorModel.defaultSensor)
        #expect(model.aperture == CalculatorModel.defaultAperture)
        #expect(model.focalLength == CalculatorModel.defaultFocalLength)
        #expect(model.focusDistance == CalculatorModel.defaultFocusDistance)
        #expect(model.unit == CalculatorModel.defaultUnit)
    }

    @Test func remembersLastChosenValues() throws {
        let defaults = try freshDefaults()
        let first = CalculatorModel(defaults: defaults)
        first.sensor = .microFourThirds
        first.aperture = Aperture(fNumber: 11)
        first.focalLength = 85
        first.unit = .feet
        first.focusDistance = 12.5

        let second = CalculatorModel(defaults: defaults)
        #expect(second.sensor == .microFourThirds)
        #expect(second.aperture.fNumber == 11)
        #expect(second.focalLength == 85)
        #expect(second.focusDistance == 12.5)
        #expect(second.unit == .feet)
    }

    @Test func resetRestoresDefaults() throws {
        let defaults = try freshDefaults()
        let model = CalculatorModel(defaults: defaults)
        model.focalLength = 200
        model.unit = .inches
        model.resetToDefaults()
        #expect(model.focalLength == CalculatorModel.defaultFocalLength)
        #expect(model.unit == CalculatorModel.defaultUnit)
        #expect(CalculatorModel(defaults: defaults).focalLength == CalculatorModel.defaultFocalLength)
    }
}
