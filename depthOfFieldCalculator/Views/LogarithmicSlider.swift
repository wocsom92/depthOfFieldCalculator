//
//  LogarithmicSlider.swift
//  depthOfFieldCalculator
//
//  A slider whose travel is logarithmic, so short focal lengths and close focus
//  distances get fine control while long ones remain reachable.
//

import SwiftUI

struct LogarithmicSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    /// Rounds the raw slider value to a displayable number.
    let rounding: (Double) -> Double
    let label: LocalizedStringKey

    private var logarithmicValue: Binding<Double> {
        Binding(
            get: { log10(min(max(value, range.lowerBound), range.upperBound)) },
            set: { value = rounding(pow(10, $0)) }
        )
    }

    var body: some View {
        Slider(value: logarithmicValue, in: log10(range.lowerBound)...log10(range.upperBound)) {
            Text(label)
        }
    }

    /// Rounds to a small number of significant digits so the value reads cleanly.
    static func significantDigits(_ digits: Int) -> (Double) -> Double {
        { value in
            guard value > 0 else { return value }
            let magnitude = floor(log10(value))
            let step = pow(10, magnitude - Double(digits - 1))
            return (value / step).rounded() * step
        }
    }
}
