import SwiftUI

/// C3'ün yan yana karşılaştırması: solda tanıdık başarısızlık, sağda bizim yapı.
///
/// ## Neden sütun, neden grafik değil
///
/// Burada önce bir eğri vardı. İki yaklaşımın farkını zaman ekseninde çizmek,
/// istemeden bir **sonuç** eğrisi gibi okunuyordu; altına eklenen "bu bir vaat
/// değil" notu da ekranın en uzun cümlesi hâline geliyordu. İki sütun aynı farkı
/// tek bakışta ve hiçbir sayı ima etmeden gösteriyor (ürün sahibi kararı,
/// 2026-09-08).
///
/// ## Satırlar eşleşir
///
/// Aynı indeksteki iki metin aynı satırda durur ve aynı şeyin iki hâlini anlatır
/// ("Yüzlerce başlık" ↔ "Tek bir yol"). Hizayı `Grid` garantiler: iki sütundan
/// hangisi iki satıra sarsa da karşılığı onunla aynı yükseklikte kalır.
///
/// ## Tek mürekkep
///
/// Kırmızı/yeşil karşıtlığı yok (Görsel Sistem §5). Ayrım üç sinyalle birden
/// yapılır — sütun başlığındaki işaret (`xmark` / `checkmark`), metin parlaklığı ve
/// metin ağırlığı. Renk körlüğünde de, gri tonlamalı ekran görüntüsünde de okunur.
struct ComparisonColumns: View {
    let theirsTitle: LocalizedStringResource
    let oursTitle: LocalizedStringResource
    let theirs: [LocalizedStringResource]
    let ours: [LocalizedStringResource]
    /// Satırların `sequentialReveal` sırasındaki ilk indeksi. Bir satırın iki
    /// yanı **aynı anda** belirir: karşılaştırma çiftin birlikte görülmesiyle
    /// kuruluyor, teker teker belirirse okuma sırası bozuluyor.
    var revealStartIndex: Int = 0

    /// Erişilebilir boyutlarda iki sütun her biri ekranın yarısına sıkışıyor ve
    /// tek kelimelik satırlar bile üç satıra sarıyor. O boyutlarda karşılaştırma
    /// alt alta iki bloğa dönüşür — aynı bilgi, kırılmayan yerleşim.
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.patikaInk) private var ink

    private var pairs: [(theirs: LocalizedStringResource, ours: LocalizedStringResource)] {
        zip(theirs, ours).map { ($0, $1) }
    }

    var body: some View {
        if typeSize.isAccessibilitySize {
            stacked
        } else {
            grid
        }
    }

    // MARK: - Varsayılan: yan yana

    private var grid: some View {
        Grid(alignment: .topLeading, horizontalSpacing: 12, verticalSpacing: 12) {
            // `GridRow` bir görünüm değil, yerleşim bildirimidir; değiştirici
            // kabul etmez. Bu yüzden beliriş sırası satıra değil hücrelere
            // veriliyor — aynı indeks iki hücreye de verildiği için çift yine
            // aynı anda beliriyor.
            GridRow {
                columnTitle(theirsTitle, symbol: "xmark", isPrimary: false)
                    .statementReveal(revealStartIndex)
                columnTitle(oursTitle, symbol: "checkmark", isPrimary: true)
                    .statementReveal(revealStartIndex)
            }

            ForEach(Array(pairs.enumerated()), id: \.offset) { index, pair in
                GridRow {
                    cell(pair.theirs, isPrimary: false)
                        .statementReveal(revealStartIndex + 1 + index)
                    cell(pair.ours, isPrimary: true)
                        .statementReveal(revealStartIndex + 1 + index)
                }
            }
        }
        .overlay(alignment: .center) {
            // İki sütunun arasındaki ince çizgi. Sağ sütuna dolgu vermek yerine
            // ayırıcı koyuyoruz: `Grid` sütun genişliğini dışarı vermiyor, dolgu
            // ancak tahminle çizilebilirdi. Çizgi tam ortada duruyor çünkü iki
            // sütun da genişliği eşit paylaşıyor.
            Rectangle()
                .fill(ink.primary.opacity(0.14))
                .frame(width: 1)
                .padding(.vertical, 2)
        }
        .accessibilityElement(children: .contain)
    }

    private func columnTitle(
        _ title: LocalizedStringResource,
        symbol: String,
        isPrimary: Bool
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.caption.weight(Theme.Weight.action))
            Text(title)
                .font(.subheadline.weight(Theme.Weight.action))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(ink.primary.opacity(isPrimary ? 1.0 : 0.55))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func cell(_ text: LocalizedStringResource, isPrimary: Bool) -> some View {
        Text(text)
            .font(.subheadline.weight(isPrimary ? Theme.Weight.emphasis : Theme.Weight.body))
            .foregroundStyle(ink.primary.opacity(isPrimary ? 0.95 : 0.58))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Erişilebilir boyutlar: alt alta

    private var stacked: some View {
        VStack(alignment: .leading, spacing: 18) {
            block(title: theirsTitle, symbol: "xmark", lines: theirs, isPrimary: false)
                .statementReveal(revealStartIndex)
            block(title: oursTitle, symbol: "checkmark", lines: ours, isPrimary: true)
                .statementReveal(revealStartIndex + 1)
        }
    }

    private func block(
        title: LocalizedStringResource,
        symbol: String,
        lines: [LocalizedStringResource],
        isPrimary: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            columnTitle(title, symbol: symbol, isPrimary: isPrimary)
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                cell(line, isPrimary: isPrimary)
            }
        }
        .padding(isPrimary ? 14 : 0)
        .background {
            if isPrimary {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.07))
            }
        }
    }
}

#Preview {
    ZStack {
        WoodlandStyle.background.ignoresSafeArea()
        ComparisonColumns(
            theirsTitle: Copy.Onboarding.libraryComparisonTheirsTitle,
            oursTitle: Copy.Onboarding.libraryComparisonOursTitle,
            theirs: Copy.Onboarding.libraryComparisonTheirs,
            ours: Copy.Onboarding.libraryComparisonOurs
        )
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }
    .preferredColorScheme(.dark)
}
