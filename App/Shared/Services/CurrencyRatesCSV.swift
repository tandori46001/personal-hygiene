import Foundation

/// Round-21 slice T3.18: pure helper that turns a list of `CurrencyConversion`
/// rows into a CSV table copy-pasteable into a spreadsheet. Header is fixed
/// English so the CSV remains machine-readable regardless of UI locale.
public enum CurrencyRatesCSV {

    public static func render(
        amount: Double,
        from base: String,
        conversions: [CurrencyConversion]
    ) -> String {
        var lines = ["base,target,rate,converted"]
        let upperBase = base.uppercased()
        for conversion in conversions {
            let line = String(
                format: "%@,%@,%.6f,%.2f",
                upperBase,
                conversion.to,
                conversion.rate,
                conversion.amountConverted
            )
            lines.append(line)
        }
        _ = amount // included in the per-row converted value already
        return lines.joined(separator: "\n")
    }
}
