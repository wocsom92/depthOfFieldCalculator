//
//  CalculatorView.swift
//  depthOfFieldCalculator
//
//  The single screen of the app: an illustration of the scene, lens inputs,
//  and the sharp-zone results with the near and far limits as the headline.
//

import SwiftUI

struct CalculatorView: View {
    @State private var model = CalculatorModel()

    var body: some View {
        NavigationStack {
            Form {
                sceneSection
                lensSection
                resultsSection
            }
            .navigationTitle("Depth of Field")
            .navigationSubtitle(model.sensor.name)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    optionsMenu
                }
            }
        }
    }

    // MARK: - Toolbar

    private var optionsMenu: some View {
        Menu {
            Picker("Sensor", selection: $model.sensor) {
                ForEach(SensorFormat.all) { sensor in
                    Text(sensor.name).tag(sensor)
                }
            }
            .pickerStyle(.inline)

            Divider()

            Button("Reset to Defaults", systemImage: "arrow.counterclockwise") {
                withAnimation(.snappy) { model.resetToDefaults() }
            }
        } label: {
            Label("Options", systemImage: "ellipsis")
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var sceneSection: some View {
        if let result = model.depthOfField {
            Section {
                DepthOfFieldScene(result: result, focus: model.focusDistanceInMillimeters) { model.formatted(millimeters: $0) }
                    .listRowInsets(EdgeInsets())
            }
        }
    }

    private var lensSection: some View {
        Section("Lens & Focus") {
            Picker("Aperture", selection: $model.aperture) {
                ForEach(Aperture.standard) { aperture in
                    Text(aperture.label).tag(aperture)
                }
            }
            .pickerStyle(.menu)
            VStack(spacing: 6) {
                LabeledContent("Focal Length") {
                    valueText(model.formattedFocalLength)
                }
                LogarithmicSlider(
                    value: $model.focalLength,
                    range: CalculatorModel.focalLengthRange,
                    rounding: { max(1, $0.rounded()) },
                    label: "Focal length"
                )
            }
            VStack(spacing: 6) {
                LabeledContent("Focus Distance") {
                    valueText(model.formatted(millimeters: model.focusDistanceInMillimeters))
                }
                LogarithmicSlider(
                    value: $model.focusDistance,
                    range: model.focusDistanceRange,
                    rounding: LogarithmicSlider.significantDigits(3),
                    label: "Focus distance"
                )
            }
            Picker("Unit", selection: $model.unit) {
                ForEach(DistanceUnit.allCases) { unit in
                    Text(unit.symbol).tag(unit)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Distance unit")
        }
    }

    @ViewBuilder
    private var resultsSection: some View {
        Section {
            if let result = model.depthOfField {
                HStack(spacing: 12) {
                    limitTile("Near Limit", systemImage: "arrow.left.to.line", millimeters: result.near)
                    limitTile("Far Limit", systemImage: "arrow.right.to.line", millimeters: result.far)
                }
                .padding(.bottom, 12)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                resultRow("Total Depth of Field", millimeters: result.total)
                    .fontWeight(.semibold)
                resultRow("Hyperfocal Distance", millimeters: result.hyperfocal)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ContentUnavailableView(
                    "Enter Valid Values",
                    systemImage: "camera.aperture",
                    description: Text("The focus distance must be greater than the focal length.")
                )
                .listRowBackground(Color.clear)
            }
        } header: {
            Text("Sharp Zone")
        } footer: {
            if model.depthOfField?.isInfinite == true {
                Text("The subject is at or beyond the hyperfocal distance, so everything from the near limit to infinity is acceptably sharp.")
            }
        }
    }

    // MARK: - Components

    private func limitTile(_ title: LocalizedStringKey, systemImage: String, millimeters: Double?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(model.formatted(millimeters: millimeters))
                .font(.title.weight(.semibold))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.snappy, value: millimeters)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func valueText(_ text: String) -> some View {
        Text(text)
            .monospacedDigit()
            .fontWeight(.medium)
            .contentTransition(.numericText())
            .animation(.snappy, value: text)
    }

    private func resultRow(_ title: LocalizedStringKey, millimeters: Double?) -> some View {
        LabeledContent(title) {
            Text(model.formatted(millimeters: millimeters))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy, value: millimeters)
        }
    }
}

#Preview {
    CalculatorView()
}
