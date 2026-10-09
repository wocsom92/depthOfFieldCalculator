//
//  DepthOfField.swift
//  depthOfFieldCalculator
//
//  Pure depth-of-field maths. Everything here is expressed in millimetres
//  and has no knowledge of the user interface.
//

import Foundation

/// The result of a depth-of-field calculation. All distances are in millimetres.
struct DepthOfField: Equatable, Sendable {
    /// Hyperfocal distance, H = f² / (N·c) + f.
    let hyperfocal: Double
    /// Nearest distance that is acceptably sharp.
    let near: Double
    /// Farthest distance that is acceptably sharp, or `nil` when it extends to infinity.
    let far: Double?

    /// Total depth of field, or `nil` when it extends to infinity.
    var total: Double? {
        far.map { $0 - near }
    }

    var isInfinite: Bool { far == nil }

    /// Calculates the depth of field for the given parameters.
    ///
    /// - Parameters:
    ///   - circleOfConfusion: Circle of confusion diameter in millimetres.
    ///   - fNumber: The aperture's f-number.
    ///   - focalLength: Lens focal length in millimetres.
    ///   - focusDistance: Distance to the focused subject in millimetres.
    /// - Returns: The depth of field, or `nil` if the inputs are not physically meaningful.
    init?(circleOfConfusion: Double, fNumber: Double, focalLength: Double, focusDistance: Double) {
        guard circleOfConfusion > 0, fNumber > 0, focalLength > 0, focusDistance > focalLength,
              [circleOfConfusion, fNumber, focalLength, focusDistance].allSatisfy(\.isFinite)
        else { return nil }

        // H' = f² / (N·c). The conventional hyperfocal distance adds one focal length: H = H' + f.
        let reducedHyperfocal = (focalLength * focalLength) / (fNumber * circleOfConfusion)
        let offset = focusDistance - focalLength

        self.hyperfocal = reducedHyperfocal + focalLength
        // Equivalent to the textbook s·(H − f) / (H + s − 2f) and s·(H − f) / (H − s).
        self.near = (reducedHyperfocal * focusDistance) / (reducedHyperfocal + offset)
        // Once the subject is at or beyond the hyperfocal distance, sharpness extends to infinity.
        self.far = offset >= reducedHyperfocal ? nil : (reducedHyperfocal * focusDistance) / (reducedHyperfocal - offset)
    }
}
