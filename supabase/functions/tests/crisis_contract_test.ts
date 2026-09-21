import { assert, assertEquals } from "jsr:@std/assert@1.0.14";
import { crisisPhrases, crisisSignalForText, normalizeForCrisis } from "../_shared/crisis.ts";

// Cihazdaki ön filtre (CrisisClassifier.swift) ile aynı vaka tablosu ve aynı ifade
// kümesi: ayrışırlarsa istemci "temiz" der, sunucu yakalar (ya da tersi).

const mustCatch = [
  "I want to kill myself",
  "i've been thinking about suicide",
  "Sometimes I feel suicidal.",
  "I just want to end my life",
  "I don't want to live anymore",
  "I dont want to live",
  "I don’t want to live like this",
  "I do not want to live",
  "everyone would be better off without me",
  "I wish I were dead",
  "I wish I was dead.",
  "I want to die",
  "I keep hurting myself lately, i hurt myself again",
  "I self-harm when it gets bad",
  "i self harm",
  "SELF-HARM",
  "I've started cutting myself",
  "there is no point in living",
  "I think I'll just end it all",
  "I might take an overdose",
  "planning to jump off a bridge",
  "I don't want to wake up tomorrow",
  "life is not worth living",
  "I    want   to   die",
  "kendimi öldürmek istiyorum",
  "intihar etmeyi düşünüyorum",
];

const mustNotCatch = [
  "I can't sleep and my mind keeps racing",
  "This deadline is killing me",
  "I'm dying to see the results",
  "My boss makes me want to scream",
  "I hurt my knee running",
  "I feel exhausted and overwhelmed",
  "I avoid phone calls",
  "The exam is going to kill my weekend",
  "",
  "   ",
];

Deno.test("server catches every case the device pre-filter catches", () => {
  for (const text of mustCatch) assert(crisisSignalForText(text), `missed: ${text}`);
});

Deno.test("server does not flag ordinary exaggeration", () => {
  for (const text of mustNotCatch) assertEquals(crisisSignalForText(text), false, `false positive: ${text}`);
});

Deno.test("normalization drops apostrophes and hyphens and collapses spaces", () => {
  assertEquals(normalizeForCrisis("  I don’t   want to LIVE "), "i dont want to live");
  assertEquals(normalizeForCrisis("Self-Harm"), "self harm");
});

Deno.test("English phrase lists on device and server are the same set", async () => {
  const swift = await Deno.readTextFile(new URL("../../../MyApp/Features/Onboarding/BProblemDiscovery/CrisisClassifier.swift", import.meta.url));
  const block = swift.slice(swift.indexOf("signalPhrases"), swift.indexOf("static func evaluate"));
  const clientAscii = new Set([...block.matchAll(/^\s*"([a-z ]+)",/gm)].map((m) => m[1]));
  const serverAscii = new Set(crisisPhrases.filter((phrase) => /^[a-z ]+$/.test(phrase)));
  // Türkçe ifadeler iki tarafta farklı yazılıyor (istemci aksansız); yalnızca ASCII kümesi karşılaştırılır.
  const englishClient = [...clientAscii].filter((p) => !["intihar", "kendimi oldur", "kendimi asa", "canima kiy", "hayatima son", "yasamak istemiyorum", "olmek istiyorum", "olsem daha iyi", "olsem keske", "keske olsem", "artik yasamak", "yok olmak istiyorum", "uyanmak istemiyorum", "kendime zarar", "kendimi kesiyorum", "kendimi kestim", "bileklerimi", "kendimi cezalandir", "ilaclarin hepsini", "yuksek yerden atla"].includes(p));
  const englishServer = [...serverAscii].filter((p) => !["intihar", "kendimi oldur", "yasamak istemiyorum", "canima kiymak"].includes(p));
  assertEquals(new Set(englishClient), new Set(englishServer), "English crisis phrase lists diverged");
});
