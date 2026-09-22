import SwiftUI

/// The primary result for a manual field measurement.
/// This belongs with fieldkit screens rather than the shared app chrome.
struct FieldReadout: View {
    let label: String
    let value: String
    var unit: String?
    var context: String?
    var note: String?

    var body: some View {
        HStack(alignment: .top, spacing: AppMetrics.contentSpacing) {
            RoundedRectangle(cornerRadius: AppMetrics.hairlineWidth, style: .continuous)
                .fill(AppTheme.accent)
                .frame(width: AppMetrics.readoutAccentWidth)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .textCase(.uppercase)

                HStack(alignment: .lastTextBaseline, spacing: AppMetrics.tightSpacing) {
                    Text(value)
                        .font(.system(size: AppMetrics.readoutValueSize, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)

                    if let unit {
                        Text(unit)
                            .font(.headline)
                            .foregroundStyle(AppTheme.textMono)
                    }
                }

                if let context {
                    Text(context)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                }

                if let note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .cardSurface(padding: AppMetrics.readoutPadding)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ScreenScaffold {
        FieldReadout(
            label: "Grade",
            value: "4.8",
            unit: "%",
            context: "North fence · 18.5 m baseline",
            note: "Planning estimate from typed tape and angle."
        )
    }
}
