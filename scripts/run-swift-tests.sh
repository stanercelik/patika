#!/bin/bash
# Elle derlenen Swift testlerinin hepsini koşturur (test hedefi yok).
#   bash scripts/run-swift-tests.sh            # hepsi
#   bash scripts/run-swift-tests.sh Pacing     # adında geçenler
#
# Metinler `Localizable.xcstrings`te ve Xcode'un ürettiği semboller elle `swiftc`te
# yok: `Tests/Support/StringSymbolsShim.swift` katalogdan üretilir ve gerekenlere
# eklenir. Katalog değişince: python3 scripts/generate-string-symbol-shim.py
set -u
cd "$(dirname "$0")/.."
python3 scripts/generate-string-symbol-shim.py >/dev/null || exit 1
SHIM=Tests/Support/StringSymbolsShim.swift
M=MyApp
FILTER="${1:-}"
FAIL=0

run() { # name, files...
  local name="$1"; shift
  if [ -n "$FILTER" ] && [[ "$name" != *"$FILTER"* ]]; then return; fi
  local out="/tmp/swifttest-$name"
  if ! swiftc -o "$out" "$@" 2>/tmp/swifttest-$name.log; then
    echo "BUILD FAIL  $name"; grep -m3 "error" /tmp/swifttest-$name.log; FAIL=1; return
  fi
  if "$out" >/tmp/swifttest-$name.out 2>&1; then echo "ok          $name: $(tail -1 /tmp/swifttest-$name.out | cut -c1-100)"
  else echo "FAIL        $name"; tail -3 /tmp/swifttest-$name.out; FAIL=1; fi
}

run MeasurementScoring $M/Content/Tone.swift $M/Models/DomainEnums.swift $M/Models/MeasurementLibrary.swift $M/Models/MeasurementScoring.swift $SHIM Tests/MeasurementScoringTests/main.swift
run BadgeCatalog $M/Content/Tone.swift $M/Models/DomainEnums.swift $M/Models/ProfileRecord.swift $M/Models/ProfileSnapshot.swift \
  $M/Models/BadgeCatalog.swift $M/Models/WeeklyRhythm.swift $M/Models/PathPlan.swift $M/Models/SessionManifest.swift \
  $M/Features/Session/SessionPacing.swift $M/Models/MeasurementLibrary.swift $M/Models/MeasurementScoring.swift \
  $M/Infrastructure/Backend/RetryPolicy.swift $M/Infrastructure/Backend/BackendError.swift $M/Infrastructure/Backend/AudioStatus.swift $M/Infrastructure/Backend/BackendClient.swift \
  $M/Features/Onboarding/OnboardingDraft.swift $SHIM Tests/BadgeCatalogTests/main.swift
run SessionPacing $M/Models/SessionManifest.swift $M/Features/Session/SessionTimeline.swift $M/Features/Session/SessionPacing.swift \
  $M/Features/Session/SessionSegment.swift $M/Features/Session/SessionManifestScript.swift Tests/SessionPacingTests/main.swift
run SessionTimeline $M/Models/SessionManifest.swift $M/Features/Session/SessionTimeline.swift $M/Features/Session/SessionPacing.swift Tests/SessionTimelineTests/main.swift
run SessionScheduler $M/Models/SessionManifest.swift $M/Features/Session/SessionTimeline.swift $M/Features/Session/SessionPacing.swift \
  $M/Features/Session/SessionScheduler.swift Tests/SessionSchedulerTests/main.swift
run DiscoverLibrary $M/Features/Discover/DiscoverLibrary.swift $M/Features/Discover/DiscoverCatalog.swift $M/Features/Discover/DiscoverSection.swift \
  $M/Content/Discover/DiscoverCopy.swift $M/Models/DomainEnums.swift $M/Models/SessionManifest.swift $M/Content/Tone.swift \
  $M/Features/Session/SessionPacing.swift $M/Features/Session/SessionTimeline.swift $M/Features/Session/SessionSegment.swift \
  $M/Features/Session/SessionManifestScript.swift $SHIM Tests/DiscoverLibraryTests/main.swift
run CrisisClassifier $M/Features/Onboarding/BProblemDiscovery/CrisisClassifier.swift Tests/CrisisClassifierTests/main.swift
run LocalizationCatalog $M/Content/Tone.swift Tests/LocalizationCatalogTests/main.swift
run SessionEnvelope $M/Features/Session/SessionEnvelope.swift Tests/SessionEnvelopeTests/main.swift
run RetryPolicy $M/Infrastructure/Backend/RetryPolicy.swift $M/Infrastructure/Backend/BackendError.swift Tests/RetryPolicyTests/main.swift
run AudioReadiness $M/Infrastructure/Backend/AudioStatus.swift $M/Features/Session/AudioReadiness.swift Tests/AudioReadinessTests/main.swift
run ExpectationCurveModel $M/DesignSystem/Components/ExpectationCurveModel.swift Tests/ExpectationCurveModelTests/main.swift
run OnboardingInteraction $M/Content/Tone.swift $M/Models/DomainEnums.swift \
  $M/Features/Onboarding/AIdentity/AgeSelection.swift $SHIM Tests/OnboardingInteractionTests/main.swift
run Contrast $M/DesignSystem/RGB.swift Tests/ContrastTests/main.swift
# JourneyRoutePatternTests bayat: JourneyRoutePattern tipi artık kodda yok (bu işten önce de böyleydi).
exit $FAIL
