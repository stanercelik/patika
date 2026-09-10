# Kişisel İz Yol Haritası Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** F2 ve “Yolum” haritalarını gerçek path fazlarına göre biçimlenen, tek nefes saatini paylaşan, erişilebilir ve normal koşullarda 60 fps çalışan Kişisel İz tasarımına geçirmek.

**Architecture:** Gerçek path verisinin faz ve teknik sunum kuralları domain katmanında tek kaynaktan üretilecek; SwiftUI yalnızca hazırlanmış faz/konum/durum değerlerini yerleştirecek. Mevcut satır başına native `Shape` mimarisi korunacak, yalnızca aktif satırın grafik katmanı 60 Hz `TimelineView` ile güncellenecek ve F2 ile Yolum aynı `JourneyMapRow` bileşenlerini kullanmaya devam edecek.

**Tech Stack:** Swift 6, SwiftUI, Observation, native `Shape`/`Path`, `TimelineView`, SF Symbols, mevcut Metal shader ve iOS 26.0.

**Spec:** `docs/superpowers/specs/2026-09-10-personal-trace-journey-map-design.md`

## Global Constraints

- Deployment target iOS 26.0 olarak kalır; yeni üçüncü parti bağımlılık eklenmez.
- Harita tonu `Sakin`dir; emoji, ödül, streak, sayaç, konfeti, parçacık ve sonuç vaadi yoktur.
- F2 ve Yolum aynı ortak harita bileşenlerini kullanır; F1 `TrailRow` yeniden tasarlanmaz.
- Başlıklar ve teknikler yalnızca gerçek `GeneratedPath` / `ActivePath` verisinden veya belgelenmiş fallback’ten gelir.
- Gelecek adımların başlığı okunur, yalnızca içerikleri kilitlidir; kilit renk dışında ikon ve erişilebilirlik hint’iyle de anlatılır.
- Normal koşullarda tek sürekli harita saati 60 Hz’dir; kare bütçesi 16.67 ms, arka plan Metal bütçesi kare başına 2 ms’dir.
- İlk görünüş hareketleri 800 ms altındadır; mevcut F2 rota turu belgelenmiş tek uzun içerik hareketidir.
- Nefes ritmi 10 saniyedir: 4 saniye al, 0.5 saniye tut, 5.5 saniye ver.
- Reduce Motion’da trim, ölçek ve F2 turu yoktur; Reduce Transparency’de düz koyu yüzey kullanılır.
- Low Power Mode, `.serious`/`.critical` termal durum veya pasif scene sürekli hareketi durdurur.
- Dynamic Type semantiktir; AX5’te rota düz sol raya dönüşür ve dokunma hedefleri en az 44×44 pt kalır.
- Kullanıcının ham problem metni dekoratif içerik olarak gösterilmez; cinsiyet ve yaş rota biçimini değiştirmez.
- Projede test target yoktur. Her görev derleme, deterministik preview ve belirtilen simülatör senaryosuyla doğrulanır; derleme test olarak raporlanmaz.

---

## Dosya Haritası

| Dosya | Sorumluluk |
|---|---|
| `MyApp/Models/PathPlan.swift` | Gün → faz, faz başlangıcı ve fallback satırı fazı için tek domain API |
| `MyApp/Models/BlockLibrary.swift` | `blockIds` → yerelleştirilmiş gerçek teknik özeti |
| `MyApp/DesignSystem/JourneyRouteLayout.swift` | Faz duyarlı deterministik x konumları ve komşu satır birleşimleri |
| `MyApp/DesignSystem/JourneyRoutePattern.swift` | Yalnızca mevcut `JourneyStepAccess` sözleşmesini taşımaya devam eder |
| `MyApp/DesignSystem/JourneyMotionPolicy.swift` | Reduce Motion, scene, güç ve termal duruma göre tek hareket kararı |
| `MyApp/DesignSystem/Components/JourneyMapNode.swift` | Dört düğüm görünümü ve aktif grafik katmanının nefes değeri |
| `MyApp/DesignSystem/Components/JourneyPhaseThreshold.swift` | Faz başlangıcındaki sessiz eşik ve erişilebilir olmayan dekoratif bağlantı |
| `MyApp/DesignSystem/Components/JourneyMap.swift` | Satır düzeni, rota segmenti, aktif 60 Hz katmanı ve görünüş animasyonu |
| `MyApp/DesignSystem/Theme.swift` | Kişisel İz çizgi ve hareket token’ları |
| `MyApp/Features/Onboarding/FDelivery/RoadmapView.swift` | F2 gerçek/fallback satırlarını faz konumlarına bağlama; mevcut turu koruma |
| `MyApp/Features/Path/MyPathViewModel.swift` | Faz, faz başlangıcı, teknik özeti ve yeni tamamlanan adımı hazırlama |
| `MyApp/Features/Path/MyPathView.swift` | Yolum satırlarını ortak konumlara bağlama ve tamamlanma haptik tetikleme |
| `CLAUDE.md` | Uygulanan ürün kararının tarihli kaydı |
| `docs/PRD-Ek-Gorsel-Sistem-ve-Promptlar.md` | Görsel sistem karar günlüğü ve Kişisel İz davranışı |

---

### Task 1: Faz ve teknik sunum kurallarını domain katmanında birleştir

**Files:**
- Modify: `MyApp/Models/PathPlan.swift`
- Modify: `MyApp/Models/BlockLibrary.swift`
- Modify: `MyApp/Features/Path/MyPathViewModel.swift`

**Interfaces:**
- Consumes: `PathLength`, `PathPhase`, `PathPlan.Row`, `BlockLibrary.block(id:)`.
- Produces: `PathPlan.phase(on:length:) -> PathPhase?`, `PathPlan.startsPhase(on:length:) -> Bool`, `PathPlan.phase(for:length:) -> PathPhase?`, `BlockLibrary.techniqueSummary(for:) -> String?`.

- [ ] **Step 1: PathPlan için gün ve fallback satırı faz API’lerini ekle**

`PathPlan` içine aşağıdaki saf fonksiyonları ekle; faz sınırlarını View katmanında yeniden hesaplama:

```swift
static func phase(on day: Int, length: PathLength) -> PathPhase? {
    for case .phase(let phase, let range) in rows(for: length)
    where range.contains(day) {
        return phase
    }
    return nil
}

static func startsPhase(on day: Int, length: PathLength) -> Bool {
    rows(for: length).contains { row in
        guard case .phase(_, let range) = row else { return false }
        return range.lowerBound == day
    }
}

static func phase(for row: Row, length: PathLength) -> PathPhase? {
    switch row {
    case .phase(let phase, _):
        return phase
    case .measurement(let day, _):
        return phase(on: day, length: length)
    }
}
```

- [ ] **Step 2: Teknik özetini ortak kütüphane API’sine taşı**

`BlockLibrary` içine gerçek ve çözülebilen blokları kullanan API’yi ekle:

```swift
static func techniqueSummary(for blockIDs: [String]) -> String? {
    let titles = blockIDs.compactMap(block(id:)).map { String(localized: $0.title) }
    return titles.isEmpty ? nil : titles.joined(separator: " · ")
}
```

`MyPathViewModel.techniques(for:)` gövdesini bu API’ye yönlendir:

```swift
func techniques(for step: PathStepRecord) -> String? {
    BlockLibrary.techniqueSummary(for: step.blockIds)
}
```

- [ ] **Step 3: MyPathViewModel faz fonksiyonlarını tek kaynağa bağla**

Mevcut `phase(for:)` döngüsünü kaldırıp aşağıdaki domain çağrısını kullan; yeni
`startsPhase(_:)` fonksiyonunu ekle:

```swift
func phase(for step: PathStepRecord) -> PathPhase? {
    guard let length = PathLength(rawValue: steps.count) else { return nil }
    return PathPlan.phase(on: step.day, length: length)
}

func startsPhase(_ step: PathStepRecord) -> Bool {
    guard let length = PathLength(rawValue: steps.count) else { return false }
    return PathPlan.startsPhase(on: step.day, length: length)
}
```

- [ ] **Step 4: Domain değişikliklerini derle**

Run:

```bash
xcodebuild -project patika.xcodeproj -scheme MyApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: `** BUILD SUCCEEDED **`. Test target olmadığı için bu sonuç yalnızca
derleme doğrulamasıdır.

- [ ] **Step 5: Commit**

```bash
git add MyApp/Models/PathPlan.swift MyApp/Models/BlockLibrary.swift \
  MyApp/Features/Path/MyPathViewModel.swift
git commit -m "refactor: centralize journey presentation rules"
```

---

### Task 2: Faz duyarlı deterministik rota yerleşimini oluştur

**Files:**
- Create: `MyApp/DesignSystem/JourneyRouteLayout.swift`

**Interfaces:**
- Consumes: `[PathPhase?]`, satır sırası ve `usesAccessibleLayout`.
- Produces: `JourneyRoutePosition`, `JourneyRouteLayout.positions(for:usesAccessibleLayout:)`.

- [ ] **Step 1: Rota konum tipini ve faz ritimlerini ekle**

Yeni dosyada aşağıdaki arayüzü oluştur:

```swift
import Foundation

struct JourneyRoutePosition: Equatable, Sendable {
    let previousX: Double
    let currentX: Double
    let nextX: Double
}

enum JourneyRouteLayout {
    private static let accessibleX = 0.10

    private static let rhythms: [PathPhase: [Double]] = [
        .relief: [0.40, 0.58, 0.36],
        .awareness: [0.30, 0.70, 0.38, 0.76],
        .skill: [0.20, 0.80, 0.28, 0.74],
        .behavior: [0.30, 0.68, 0.38, 0.62],
        .closing: [0.46, 0.54],
    ]

    static func positions(
        for phases: [PathPhase?],
        usesAccessibleLayout: Bool
    ) -> [JourneyRoutePosition] {
        let xValues = phases.indices.map { index in
            normalizedX(
                at: index,
                phase: phases[index],
                usesAccessibleLayout: usesAccessibleLayout
            )
        }

        return xValues.indices.map { index in
            JourneyRoutePosition(
                previousX: xValues[max(index - 1, 0)],
                currentX: xValues[index],
                nextX: xValues[min(index + 1, xValues.count - 1)]
            )
        }
    }

    private static func normalizedX(
        at index: Int,
        phase: PathPhase?,
        usesAccessibleLayout: Bool
    ) -> Double {
        guard !usesAccessibleLayout else { return accessibleX }
        let rhythm = rhythms[phase ?? .awareness] ?? rhythms[.awareness]!
        return rhythm[index % rhythm.count]
    }
}
```

Rakamlar başarı eğrisi değil, yalnızca yatay konumdur. Dizi sırası sabittir;
string hash’i veya randomness ekleme.

- [ ] **Step 2: Eski görsel ritmi geçiş köprüsü olarak yerinde bırak**

Bu görevde `JourneyRoutePattern.swift` dosyasını değiştirme. F2 ve Yolum henüz
eski `JourneyMapRow` init’ini kullandığı için `JourneyRoutePattern` Task 4 boyunca
derlenebilir geçiş köprüsü olarak kalır. İki tüketici yeni position API’sine
geçtikten sonra Task 6’da kaldırılır; `JourneyStepAccess` hiçbir aşamada değişmez.

- [ ] **Step 3: Sınır koşullarını deterministik çıktı tablosuyla doğrula**

`JourneyRouteLayout.swift` sonuna yalnızca DEBUG’ta derlenen bir preview veri
kaynağı ekleme; gerçek preview Task 7’de ortak bileşenle kurulacak. Bu aşamada
şu koşulları kod incelemesiyle doğrula:

```text
[]                         -> []
[.relief]                  -> previous/current/next aynı x
AX5 herhangi bir faz dizisi -> bütün currentX değerleri 0.10
aynı faz ve sıra            -> her çağrıda aynı sonuç
```

- [ ] **Step 4: Derle**

Run the project build command from Task 1.

Expected: `** BUILD SUCCEEDED **`. Yeni layout henüz tüketilmez; mevcut ekranlar
eski rota üzerinden çalışmaya devam eder.

- [ ] **Step 5: Commit**

```bash
git add MyApp/DesignSystem/JourneyRouteLayout.swift
git commit -m "feat: add phase-aware journey route layout"
```

---

### Task 3: Tek hareket politikası ve ortak düğüm katmanını ayır

**Files:**
- Create: `MyApp/DesignSystem/JourneyMotionPolicy.swift`
- Create: `MyApp/DesignSystem/Components/JourneyMapNode.swift`
- Modify: `MyApp/DesignSystem/Components/JourneyMap.swift`
- Modify: `MyApp/DesignSystem/Theme.swift`

**Interfaces:**
- Consumes: Reduce Motion, scene aktifliği, Low Power Mode, thermal state ve `BreathCycle`.
- Produces: `JourneyMotionPolicy.pausesContinuousMotion`, `JourneyMotionValueReader`, `JourneyMapNode(node:showsLock:breath:)`.

- [ ] **Step 1: Saf hareket politikasını ekle**

```swift
import Foundation

struct JourneyMotionPolicy: Equatable {
    let reduceMotion: Bool
    let sceneIsActive: Bool
    let lowPowerMode: Bool
    let thermalState: ProcessInfo.ThermalState

    var pausesContinuousMotion: Bool {
        reduceMotion
            || !sceneIsActive
            || lowPowerMode
            || thermalState == .serious
            || thermalState == .critical
    }

    static let minimumInterval = 1.0 / 60.0
}
```

- [ ] **Step 2: Tek TimelineView okuyucusunu oluştur**

`JourneyMapNode.swift` içinde aktif grafik katmanının kullanacağı okuyucuyu
tanımla. Güç ve termal bildirimleri burada tek kez dinlenmeli:

```swift
struct JourneyMotionValueReader<Content: View>: View {
    @ViewBuilder let content: (Double) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
    @State private var thermalState = ProcessInfo.processInfo.thermalState

    var body: some View {
        let policy = JourneyMotionPolicy(
            reduceMotion: reduceMotion,
            sceneIsActive: scenePhase == .active,
            lowPowerMode: lowPowerMode,
            thermalState: thermalState
        )

        TimelineView(.animation(
            minimumInterval: JourneyMotionPolicy.minimumInterval,
            paused: policy.pausesContinuousMotion
        )) { timeline in
            content(policy.pausesContinuousMotion
                ? 0.5
                : BreathCycle.value(
                    at: timeline.date.timeIntervalSinceReferenceDate,
                    amplitude: BreathAmplitude.ambient
                ))
        }
        .onReceive(NotificationCenter.default.publisher(
            for: ProcessInfo.PowerStateDidChangeMessage.name
        )) { _ in
            lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
        .onReceive(NotificationCenter.default.publisher(
            for: ProcessInfo.ThermalStateDidChangeMessage.name
        )) { _ in
            thermalState = ProcessInfo.processInfo.thermalState
        }
    }
}
```

- [ ] **Step 3: JourneyMapNode’u ayrı dosyaya taşı**

`JourneyMap.swift` içindeki private düğüm tipini yeni dosyaya taşı ve nefes
değerini dışarıdan alacak biçime getir:

```swift
struct JourneyMapNode: View {
    let node: TrailNode
    let showsLock: Bool
    var breath: Double = 0.5
}
```

Aktif durumda yalnızca dış halkanın ölçeği `1.00...1.04`, opaklığı ve çizgi
kalınlığı değişsin. `JourneyMapNode` kendi `TimelineView`ını oluşturmamalı.
Pending/done/milestone ölçüleri 34/36/42 pt, active ölçüsü 50 pt olarak kalmalı.

- [ ] **Step 4: Hareket token’larını Theme’e ekle**

`Theme.Motion` içine şu token’ları ekle ve bileşenlerde literal süre bırakma:

```swift
static let journeyTextReveal: Double = 0.30
static let journeyPhaseReveal: Double = 0.26
static let journeyNodeReplace: Double = 0.22
static let journeyPress: Double = 0.14
```

`Theme.Line` içine rota bağlantısı için:

```swift
static let journeyConnector: CGFloat = 1
```

- [ ] **Step 5: Derle ve statik düğüm durumlarını incele**

Run the project build command from Task 1. Ardından Xcode Canvas’ta pending,
active, done ve milestone durumlarının monokrom kaldığını kontrol et.

Expected: Her durumda tek mürekkep; lock ve check SF Symbol; aktif dış halka
en fazla yüzde 4 ölçek değiştiriyor.

- [ ] **Step 6: Commit**

```bash
git add MyApp/DesignSystem/JourneyMotionPolicy.swift \
  MyApp/DesignSystem/Components/JourneyMapNode.swift \
  MyApp/DesignSystem/Components/JourneyMap.swift MyApp/DesignSystem/Theme.swift
git commit -m "refactor: centralize journey map motion"
```

---

### Task 4: JourneyMapRow’u Kişisel İz kompozisyonuna geçir

**Files:**
- Create: `MyApp/DesignSystem/Components/JourneyPhaseThreshold.swift`
- Modify: `MyApp/DesignSystem/Components/JourneyMap.swift`

**Interfaces:**
- Consumes: `JourneyRoutePosition`, `PathPhase?`, `startsPhase`, `TrailNode`.
- Produces: Yeni `JourneyMapRow` init sözleşmesi ve tek aktif grafik timeline’ı.

- [ ] **Step 1: JourneyMapRow imzasını genişlet**

```swift
struct JourneyMapRow<Content: View>: View {
    let index: Int
    let totalCount: Int
    let position: JourneyRoutePosition?
    let phase: PathPhase?
    let startsPhase: Bool
    let node: TrailNode
    var showsLock = false
    var isProminent = false
    @ViewBuilder let content: Content
}
```

Yeni initializer’da `position`, `phase` ve `startsPhase` için sırasıyla `nil`,
`nil` ve `false` default’larını ver. `position == nil` iken aşağıdaki bridge
yalnızca henüz taşınmamış tüketicileri derlenebilir tutar:

```swift
private var resolvedPosition: JourneyRoutePosition {
    if let position { return position }
    return JourneyRoutePosition(
        previousX: JourneyRoutePattern.normalizedX(
            at: index - 1,
            usesAccessibleLayout: usesAccessibleLayout
        ),
        currentX: JourneyRoutePattern.normalizedX(
            at: index,
            usesAccessibleLayout: usesAccessibleLayout
        ),
        nextX: JourneyRoutePattern.normalizedX(
            at: index + 1,
            usesAccessibleLayout: usesAccessibleLayout
        )
    )
}
```

Yeni çizim kodu `resolvedPosition` okur. AX yerleşiminin sol ray ve tam genişlik
davranışı aynı kalır. Mevcut helper imzasını Double konumları kabul edecek
biçimde güncelle:

```swift
private func resolvedNodeX(_ normalizedX: Double, in width: CGFloat) -> CGFloat {
    usesAccessibleLayout
        ? min(accessibleRailCenter, width / 2)
        : width * CGFloat(normalizedX)
}
```

- [ ] **Step 2: Rota çizgisinde faz eşiği için gerçek boşluk bırak**

`JourneyRouteSegment` üst ve alt parçaları ayrı çizebilecek biçimde genişlet.
`startsPhase && index > 0` olduğunda üst parçayı iki `trim` aralığıyla çizerek
etiketin hizasında kısa bir boşluk bırak:

```swift
let aboveSegment = JourneyRouteSegment(
    previousX: resolvedNodeX(resolvedPosition.previousX, in: geometry.size.width),
    currentX: resolvedNodeX(resolvedPosition.currentX, in: geometry.size.width),
    nextX: resolvedNodeX(resolvedPosition.nextX, in: geometry.size.width),
    nodeY: resolvedNodeY(in: geometry.size.height),
    showsAbove: index > 0,
    showsBelow: false,
    part: .above
)

if startsPhase && index > 0 {
    aboveSegment.trim(from: 0.00, to: 0.40)
    aboveSegment.trim(from: 0.58, to: 1.00)
} else {
    aboveSegment
}
```

Boşluğu mesh rengiyle kapatan maske kullanma; gerçek çizgi aralığı olmalı.

- [ ] **Step 3: Sessiz faz eşiğini ekle**

Yeni bileşen yalnızca gerçek faz başlangıcında görünür:

```swift
struct JourneyPhaseThreshold: View {
    let phase: PathPhase
    let isVisible: Bool

    var body: some View {
        Text(phase.label)
            .font(.caption.weight(Theme.Weight.emphasis))
            .foregroundStyle(Theme.textPrimary.color.opacity(0.58))
            .opacity(isVisible ? 1 : 0)
            .accessibilityHidden(true)
    }
}
```

Etiket ana adım metninin okuma sırasına katılmamalı; adımın erişilebilirlik
label’ı zaten faz bilgisini gerektirmiyor.

- [ ] **Step 4: Aktif grafik katmanını tek TimelineView altında birleştir**

Statik rota ve içerik timeline dışında kalmalı. Yalnızca aktif satırın rota
vurgusu ve düğümü `JourneyMotionValueReader` içinde çizilmeli:

```swift
@ViewBuilder
private func markerAndActiveInk(in size: CGSize) -> some View {
    if node == .active {
        JourneyMotionValueReader { breath in
            ZStack {
                JourneyRouteSegment(
                    previousX: resolvedNodeX(resolvedPosition.previousX, in: size.width),
                    currentX: resolvedNodeX(resolvedPosition.currentX, in: size.width),
                    nextX: resolvedNodeX(resolvedPosition.nextX, in: size.width),
                    nodeY: resolvedNodeY(in: size.height),
                    showsAbove: index > 0,
                    showsBelow: false,
                    part: .above
                )
                .stroke(
                    Theme.textPrimary.color.opacity(0.68 + breath * 0.10),
                    style: StrokeStyle(
                        lineWidth: Theme.Line.trail + 1,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                JourneyMapNode(node: node, showsLock: showsLock, breath: breath)
                    .position(x: resolvedNodeX(resolvedPosition.currentX, in: size.width),
                              y: resolvedNodeY(in: size.height))
            }
        }
    } else {
        JourneyMapNode(node: node, showsLock: showsLock)
            .position(x: resolvedNodeX(resolvedPosition.currentX, in: size.width),
                      y: resolvedNodeY(in: size.height))
    }
}
```

Bu timeline’ın içine `content` koyma; aksi hâlde bütün aktif kart saniyede 60 kez
yeniden hesaplanır.

- [ ] **Step 5: Metin bağlantısını ekle**

Düğümden metin kolonuna uzanan kısa bağlantıyı 1 pt tek mürekkepli `Shape`
olarak route background içinde çiz. Ok başı ekleme. `isProminent` durumda
bağlantı kart yüzeyinin kenarında sonlanmalı; AX düz rayda bağlantı yatay ve kısa
kalmalı.

```swift
private struct JourneyContentConnector: Shape {
    let nodeX: CGFloat
    let nodeY: CGFloat
    let nodeIsLeading: Bool

    func path(in rect: CGRect) -> Path {
        let direction: CGFloat = nodeIsLeading ? 1 : -1
        let start = CGPoint(x: nodeX + direction * 18, y: nodeY)
        let end = CGPoint(x: nodeX + direction * 34, y: nodeY)
        return Path { path in
            path.move(to: start)
            path.addLine(to: end)
        }
    }
}
```

Bağlantıyı `Theme.textPrimary.color.opacity(showsLock ? 0.12 : 0.24)` ve
`Theme.Line.journeyConnector` ile stroke et; `.accessibilityHidden(true)` ve
`.allowsHitTesting(false)` uygula.

- [ ] **Step 6: Görünüş ve durum animasyonlarını bağla**

- Route trim: `Theme.Motion.journeyRouteDraw` (0.44 sn).
- Satır gecikmesi: `min(index * journeyNodeStagger, 0.30)`.
- Metin: `journeyTextReveal` ve en fazla 8 pt offset.
- Faz eşiği: `journeyPhaseReveal`, ilk görünüşte bir kez.
- Node değişimi: `journeyNodeReplace`.
- Tamamlanan iz: mevcut `stepFill` (0.40 sn).

Reduce Motion’da `isRevealed` doğrudan true olmalı; offset, trim ve scale
çalışmamalı.

- [ ] **Step 7: Geçiş köprüsüyle derle**

Run the project build command from Task 1.

Expected: `** BUILD SUCCEEDED **`. F2 ve Yolum bu aşamada default `nil`
position üzerinden eski rota görünümünü korur; yeni node ve motion katmanı ortak
bileşende çalışır.

- [ ] **Step 8: Commit**

```bash
git add MyApp/DesignSystem/Components/JourneyMap.swift \
  MyApp/DesignSystem/Components/JourneyPhaseThreshold.swift
git commit -m "feat: build personal trace journey row"
```

---

### Task 5: F2 yol haritasını Kişisel İz’e bağla

**Files:**
- Modify: `MyApp/Features/Onboarding/FDelivery/RoadmapView.swift`

**Interfaces:**
- Consumes: `JourneyRouteLayout.positions`, `PathPlan.phase`, `BlockLibrary.techniqueSummary`, yeni `JourneyMapRow` init’i.
- Produces: Gerçek generated steps ve fallback rows için aynı faz duyarlı rota.

- [ ] **Step 1: Dynamic Type ve generated faz dizisini hazırla**

`RoadmapView` içine Dynamic Type environment’ını ekle. Generated map için:

```swift
private var generatedPhases: [PathPhase?] {
    generatedSteps.map { PathPlan.phase(on: $0.day, length: flow.pathLength) }
}

private var generatedPositions: [JourneyRoutePosition] {
    JourneyRouteLayout.positions(
        for: generatedPhases,
        usesAccessibleLayout: dynamicTypeSize.isAccessibilitySize
    )
}
```

Fallback için `rows.map { PathPlan.phase(for:length:) }` ile ayrı bir konum
dizisi üret.

- [ ] **Step 2: Generated satırları yeni init’e geçir**

Her satıra aynı index’teki `generatedPositions[index]`, gerçek faz ve başlangıç
bilgisini ver:

```swift
let phase = PathPlan.phase(on: step.day, length: flow.pathLength)
JourneyMapRow(
    index: index,
    totalCount: generatedSteps.count,
    position: generatedPositions[index],
    phase: phase,
    startsPhase: PathPlan.startsPhase(on: step.day, length: flow.pathLength),
    node: isFirst ? .active : (isMeasurement ? .milestone : .pending),
    showsLock: !isFirst,
    isProminent: false
) {
    generatedStepContent(step, isMeasurement: isMeasurement)
}
```

`generatedMap` ve `fallbackMap` içindeki dış koleksiyonu `VStack` yerine
`LazyVStack(alignment: .leading, spacing: 0)` yap; satır kimlikleri değişmesin.

- [ ] **Step 3: Gerçek teknik özetini yalnızca varsa göster**

`generatedStepContent` içinde başlığın altında:

```swift
if let techniques = BlockLibrary.techniqueSummary(for: step.blockIds) {
    Text(verbatim: techniques)
        .font(.caption.weight(Theme.Weight.body))
        .foregroundStyle(Theme.textPrimary.color.opacity(step.day == 1 ? 0.68 : 0.48))
}
```

Çözülemeyen block ID için fallback metin veya ikon üretme.

- [ ] **Step 4: Fallback satırlarını aynı konum sistemine geçir**

`PathPlan.Row` sırası korunmalı; her satır `fallbackPositions[index]` ve
`PathPlan.phase(for:length:)` almalı. Faz satırında `startsPhase` true,
measurement satırında false verilmeli.

- [ ] **Step 5: Mevcut F2 yapısal kararlarını koru**

Aşağıdaki alanların diff’te değişmediğini doğrula:

```text
illustration-f2-path-ready yüksekliği: 208 pt
HoldToStartButton davranışı: 1.4 sn
rota turu: 1.10 / 1.50 / 0.55 / 1.20 sn
dokununca turun iptali
F2’de geri butonu olmaması
F2’de paywall olmaması
```

- [ ] **Step 6: Derle ve F2’yi çalıştır**

```bash
xcodebuild -project patika.xcodeproj -scheme MyApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath /tmp/patika-personal-trace-dd build
xcrun simctl install booted \
  /tmp/patika-personal-trace-dd/Build/Products/Debug-iphonesimulator/MyApp.app
xcrun simctl launch booted devplaceholder.X9RQKIJ8.MyApp \
  -patika-debug-step f2
```

Expected: Gerçek adımlar varsa tüm başlıklar gerçek veriden gelir; ilk adım
aktif, gelecekler kilitli, ölçüm günleri çift halkalıdır. Tur sırasında CTA
başından beri kullanılabilir ve ilk dokunuş turu keser.

- [ ] **Step 7: Commit**

```bash
git add MyApp/Features/Onboarding/FDelivery/RoadmapView.swift
git commit -m "feat: apply personal trace map to onboarding"
```

---

### Task 6: Yolum’u bağla ve tamamlanma mikro hareketini ekle

**Files:**
- Modify: `MyApp/Features/Path/MyPathViewModel.swift`
- Modify: `MyApp/Features/Path/MyPathView.swift`
- Modify: `MyApp/DesignSystem/Components/JourneyMap.swift`
- Modify: `MyApp/DesignSystem/JourneyRoutePattern.swift`

**Interfaces:**
- Consumes: `JourneyRouteLayout.positions`, ViewModel faz/teknik API’leri ve `completedAt`.
- Produces: `recentlyCompletedStepID: UUID?`, faz duyarlı Yolum haritası ve tek soft haptik.

- [ ] **Step 1: Yeni tamamlanan adımı ViewModel’de güvenli biçimde yakala**

`MyPathViewModel` içine ekle:

```swift
private(set) var recentlyCompletedStepID: UUID?
```

Mevcut guard binding’ini `activePath` adıyla açık hâle getir:

```swift
guard let activePath = try await services.backend.activePath(accessToken: token),
      !activePath.steps.isEmpty
else {
    recentlyCompletedStepID = nil
    state = .empty
    return
}
```

`load()` başında eski path’i state’i `.loading` yapmadan önce sakla:

```swift
let previousPath = path
state = .loading
```

Backend guard’ı başarılı olduktan sonra, `state = .ready(activePath)` satırından
önce yalnızca önceki path gerçekten varsa farkı hesapla:

```swift
let previousCompleted = Set(previousPath?.steps.compactMap {
    $0.completedAt == nil ? nil : $0.id
} ?? [])
let newCompleted = activePath.steps.filter { $0.completedAt != nil }
let newlyCompleted = newCompleted.filter { !previousCompleted.contains($0.id) }
recentlyCompletedStepID = previousPath == nil
    ? nil
    : newlyCompleted.max(by: { $0.day < $1.day })?.id
state = .ready(activePath)
```

İlk uygulama açılışında eski tamamlamaları yeniden kutlama. Hata veya empty
state’te `recentlyCompletedStepID = nil` yap.

Mevcut token alma, `activePath(accessToken:)` çağrısı ve hata yakalama akışı
aynen kalır.

- [ ] **Step 2: Yolum rota konumlarını gerçek fazlardan üret**

`MyPathView` içindeki `trail` bölümünde:

```swift
let steps = viewModel?.steps ?? []
let phases = steps.map { viewModel?.phase(for: $0) }
let positions = JourneyRouteLayout.positions(
    for: phases,
    usesAccessibleLayout: dynamicTypeSize.isAccessibilitySize
)
```

`trail` koleksiyonunu `LazyVStack(alignment: .leading, spacing: 0)` ile çiz;
mevcut `.id(step.id)` değerlerini koru ki sıradaki adıma otomatik kaydırma
çalışmaya devam etsin.

Her `PathStepRow` için aynı index’teki position, phase ve
`viewModel.startsPhase(step)` değerini geçir.

- [ ] **Step 3: PathStepRow’u yeni JourneyMapRow init’ine geçir**

`PathStepRow` yeni alanları alsın:

```swift
let position: JourneyRoutePosition
let phase: PathPhase?
let startsPhase: Bool
let isNewlyCompleted: Bool
```

Ardından `JourneyMapRow` çağrısında bu değerleri geçir. Kilitli satırın
`.disabled(isLocked)` ve `Copy.Path.lockedAccessibility` hint’i değişmemeli.

- [ ] **Step 4: Aktif kartı mürekkep yüzeyine sadeleştir**

Mevcut blur’suz yüzeyi koru fakat kartın rotadan kopuk görünmesini azalt.
`PathStepRow` içine `@Environment(\.accessibilityReduceTransparency)` ekle:

```swift
RoundedRectangle(cornerRadius: 16, style: .continuous)
    .fill(
        reduceTransparency
            ? Color.black.opacity(isExpanded ? 0.86 : 0)
            : Color.white.opacity(isExpanded ? 0.075 : 0)
    )
    .overlay {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(
                Theme.textPrimary.color.opacity(isExpanded ? 0.14 : 0),
                lineWidth: Theme.Line.journeyConnector
            )
    }
```

Material, shadow veya yeni renk ekleme. Açılma `Theme.Motion.pathExpand`, Reduce
Motion açılma ise `Theme.Motion.crossFade` kullanmaya devam etmeli.

Adım butonunun action’ında kilitli olmayan dokunuş için toggle’dan hemen önce
tek haptik üret:

```swift
Theme.softHaptic(intensity: 0.25)
```

Kilitli satır disabled olduğu için bu action’a ulaşmamalı.

- [ ] **Step 5: Tamamlanma hareketini ve haptik tetiklemeyi bağla**

`JourneyMapRow` node değişiminde iz için 0.40 sn ve symbol için 0.22 sn kullanır.
`MyPathView` yeni tamamlanan ID’yi gözlemleyip yalnızca bir soft haptik üretir:

```swift
.onChange(of: viewModel?.recentlyCompletedStepID) { _, newID in
    guard newID != nil else { return }
    Theme.softHaptic(intensity: 0.55)
}
```

Ses, konfeti veya ikinci haptik ekleme.

- [ ] **Step 6: Yolum senaryolarını çalıştır**

İki tüketici de artık explicit `JourneyRoutePosition` verdiği için
`JourneyMapRow.position` alanını non-optional yap, initializer default’unu ve
`resolvedPosition` bridge’ini kaldır. Ardından `JourneyRoutePattern.swift`
içindeki yalnızca `JourneyRoutePattern` enum’unu kaldır; `JourneyStepAccess`
aynı imzayla kalır.

```bash
xcrun simctl launch booted devplaceholder.X9RQKIJ8.MyApp \
  -patika-debug-step yolum -patika-debug-expand 5
```

Expected:

```text
sıradaki adım varsayılan açık
tamamlanan adım tekrar açılabilir
gelecek başlık okunur fakat kontrol disabled
faz eşiği yalnızca gerçek fazın ilk gününde görünür
ölçüm günü çift halka
tamamlama dönüşünde bir dolum ve bir soft haptik
ilk load sırasında eski tamamlamalar animasyon/haptik üretmez
```

- [ ] **Step 7: Commit**

```bash
git add MyApp/Features/Path/MyPathViewModel.swift MyApp/Features/Path/MyPathView.swift \
  MyApp/DesignSystem/Components/JourneyMap.swift \
  MyApp/DesignSystem/JourneyRoutePattern.swift
git commit -m "feat: apply personal trace map to active path"
```

---

### Task 7: Erişilebilirlik ve durum preview matrisi ekle

**Files:**
- Modify: `MyApp/DesignSystem/Components/JourneyMap.swift`
- Modify: `MyApp/DesignSystem/Components/JourneyMapNode.swift`
- Modify: `MyApp/Features/Onboarding/FDelivery/RoadmapView.swift`
- Modify: `MyApp/Features/Path/MyPathView.swift`

**Interfaces:**
- Consumes: Bütün yeni Kişisel İz bileşenleri.
- Produces: Normal, AX5, Reduce Motion ve Reduce Transparency için deterministik preview senaryoları.

- [ ] **Step 1: Dört düğüm durumunu tek preview’de göster**

`JourneyMapNode.swift` sonuna DEBUG preview ekle:

```swift
#Preview("Journey node states") {
    HStack(spacing: 24) {
        JourneyMapNode(node: .done, showsLock: false)
        JourneyMapNode(node: .active, showsLock: false, breath: 0.75)
        JourneyMapNode(node: .pending, showsLock: true)
        JourneyMapNode(node: .milestone, showsLock: true)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
```

- [ ] **Step 2: JourneyMapRow normal ve AX5 preview’lerini ekle**

Aynı üç satırlık örneği normal ve `.accessibility5` boyutlarında çiz. Preview
metni yalnızca geliştirme fixture’ıdır; production path’e girmemeli.

```swift
.environment(\.dynamicTypeSize, .accessibility5)
```

Expected: Normalde faz duyarlı kıvrım, AX5’te bütün düğümler aynı sol rayda;
başlıklar kırpılmıyor ve kart rota üstüne binmiyor.

- [ ] **Step 3: Reduce Motion ve Reduce Transparency preview’lerini ekle**

```swift
.environment(\.accessibilityReduceMotion, true)
.environment(\.accessibilityReduceTransparency, true)
```

Expected: Rota tamamlanmış statik hâlde, aktif düğüm sabit, kart düz koyu
yüzeyde ve otomatik tur çalışmıyor.

- [ ] **Step 4: VoiceOver sırasını simülatörde kontrol et**

F2 ve Yolum’da VoiceOver açarak şu sırayı doğrula:

```text
gün -> gerçek başlık -> varsa teknik -> ölçüm notu -> kilit hint’i
```

Rota, bağlantı çizgisi, dekoratif faz etiketi ve düğüm çizimi ayrı öğe olarak
okunmamalı. Kilitli satır için hint tam olarak `Henüz açılmadı` olmalı.

- [ ] **Step 5: Commit**

```bash
git add MyApp/DesignSystem/Components/JourneyMap.swift \
  MyApp/DesignSystem/Components/JourneyMapNode.swift \
  MyApp/Features/Onboarding/FDelivery/RoadmapView.swift \
  MyApp/Features/Path/MyPathView.swift
git commit -m "test: add journey map accessibility previews"
```

---

### Task 8: 60 fps, görsel regresyon ve ürün belgesi doğrulaması

**Files:**
- Modify: `CLAUDE.md`
- Modify: `docs/PRD-Ek-Gorsel-Sistem-ve-Promptlar.md`

**Interfaces:**
- Consumes: Tamamlanan Kişisel İz uygulaması ve onaylı spec.
- Produces: Ölçülmüş performans sonucu ve tarihli ürün karar kaydı.

- [ ] **Step 1: Temiz final build al**

```bash
xcodebuild -project patika.xcodeproj -scheme MyApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath /tmp/patika-personal-trace-final build
```

Expected: `** BUILD SUCCEEDED **`. Çıktıda yeni warning oluşmamalı.

- [ ] **Step 2: Normal boyut görsel kontrolünü yap**

F2 ve Yolum’da aşağıdakileri kontrol et:

```text
uzun TR başlık
uzun EN başlık
7 / 14 / 21 / 28 adımlı rota
done / active / pending / milestone durumları
faz eşiklerinin rota boşluğuyla hizası
aktif kart açık ve kapalı durum
F2 turuna dokunarak anında müdahale
```

Kontrastı hareketli mesh’in tek karesinde değil, en az beş farklı zaman
noktasında kontrol et.

- [ ] **Step 3: Erişilebilirlik matrisini gerçek simülatör ayarlarıyla çalıştır**

Her iki ekranı şu dört durumda ayrı ayrı incele:

```text
normal Dynamic Type
AX5
Reduce Motion açık
Reduce Transparency açık
```

Expected: Kırpılma, taşma, rota/metin çakışması ve 44 pt altı dokunma hedefi
yok. Reduce Motion’da F2 turu başlamıyor.

- [ ] **Step 4: Instruments ile 60 fps kabul ölçümü yap**

Gerçek cihazda Release’e yakın build ile Core Animation/Animation Hitches ve
Metal System Trace kaydı al:

```text
10 saniye aktif düğüm açık ve ekran sabit
10 saniye Yolum boyunca sürekli kaydırma
aktif kartı üç kez açma/kapatma
F2 otomatik rota turu
oturum tamamlamasından Yolum’a dönüş
```

Kabul:

```text
normal koşullarda 60 Hz görsel güncelleme
tekrarlayan missed frame yok
ana thread’de kare başına state/geometri yazımı yok
mesh GPU süresi kare başına <= 2 ms
harita eklenince uzun hitch oluşmuyor
```

Low Power Mode ve ciddi termal durum performans başarısızlığı sayılmaz; bu
durumlarda spesifikasyona uygun olarak sürekli hareketin durduğu doğrulanır.

- [ ] **Step 5: Ürün karar kayıtlarını güncelle**

`CLAUDE.md` F bölümü ve görsel sistem §14/karar günlüğüne 2026-09-10 tarihli
şunları kaydet:

```text
Kişisel İz onaylandı ve uygulandı.
Rota PathPhase verisine göre deterministik biçimleniyor.
F2 ve Yolum aynı bileşenleri kullanıyor.
Aktif düğüm ve aktif iz tek 60 Hz nefes saatini paylaşıyor.
Yeni raster varlık ve üçüncü parti bağımlılık eklenmedi.
Ölçülen cihaz/senaryo ve gerçek performans sonucu.
```

Ölçüm yapılmadıysa 60 fps’i doğrulanmış gibi yazma; hangi kontrolün eksik
kaldığını açıkça kaydet.

- [ ] **Step 6: Diff ve belge tutarlılığını kontrol et**

```bash
git diff --check
git status --short
rg -n "Kişisel İz|60 Hz|PathPhase" CLAUDE.md \
  docs/PRD-Ek-Gorsel-Sistem-ve-Promptlar.md
```

Expected: Whitespace hatası yok; yalnızca bu planın dosyaları değişmiş.

- [ ] **Step 7: Final commit**

```bash
git add CLAUDE.md docs/PRD-Ek-Gorsel-Sistem-ve-Promptlar.md
git commit -m "docs: record personal trace journey map"
```

---

## Final Handoff Checklist

- [ ] Bütün görev commit’leri mevcut ve çalışma ağacı temiz.
- [ ] Final `xcodebuild` sonucu gerçek çıktısıyla raporlandı.
- [ ] Test target bulunmadığı açıkça belirtildi; build test diye sunulmadı.
- [ ] F2, Yolum, AX5, Reduce Motion ve Reduce Transparency görsel kontrolleri raporlandı.
- [ ] Gerçek cihaz Instruments ölçümü yapıldıysa cihaz ve sonuç yazıldı; yapılmadıysa eksik doğrulama olarak belirtildi.
- [ ] Kullanıcının gerçek path başlıkları/teknikleri dışında yeni içerik üretilmedi.
- [ ] İlgisiz kullanıcı değişiklikleri commit’lere alınmadı.
