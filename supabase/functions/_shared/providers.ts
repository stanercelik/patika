import {
  approvedBlockIdsFor,
  type GeneratePathRequest,
  type PathPlanDTO,
  validatePlan,
} from "./schema.ts";

const crisisPatterns = [
  /intihar/i, /kendimi oldur/i, /kendimi öldür/i, /yasamak istemiyorum/i,
  /yaşamak istemiyorum/i, /canima kiymak/i, /canıma kıymak/i, /self[ -]?harm/i,
  /kill myself/i, /suicide/i,
];

export type CrisisResult = { signal: boolean; source: "rule" | "gemini" | "none" };

export function crisisSignalForText(text: string): boolean {
  return crisisPatterns.some((pattern) => pattern.test(text));
}

export function ruleBasedCrisisCheck(input: GeneratePathRequest): CrisisResult {
  const text = `${input.problemText}\n${input.avoidanceText ?? ""}`;
  return crisisSignalForText(text)
    ? { signal: true, source: "rule" }
    : { signal: false, source: "none" };
}

export function fallbackPlan(input: GeneratePathRequest): PathPlanDTO {
  const primary = input.categories[0] ?? "unnamed";
  const isTurkish = input.locale.toLowerCase().startsWith("tr");
  const titleByCategoryTR: Record<string, string> = {
    sleep: "Akşamı yavaşlatma yolu",
    anxiety: "Gerginliği fark etme yolu",
    burnout: "Yükü sadeleştirme yolu",
    focus: "Dikkati toplama yolu",
    social: "Sınırları fark etme yolu",
    selfcrit: "Kendi sesini duyma yolu",
    grief: "Yasa alan açma yolu",
    anger: "Yoğunluğu düzenleme yolu",
    exam: "Baskı altında durma yolu",
    unnamed: "Durup fark etme yolu",
  };
  const titleByCategoryEN: Record<string, string> = {
    sleep: "A path for slowing down at night",
    anxiety: "A path for noticing tension",
    burnout: "A path for making the load smaller",
    focus: "A path for gathering attention",
    social: "A path for noticing your boundaries",
    selfcrit: "A path for hearing your own voice",
    grief: "A path for making room for loss",
    anger: "A path for creating space before reacting",
    exam: "A path for staying with pressure",
    unnamed: "A path for pausing and noticing",
  };
  const opening = isTurkish
    ? (input.problemText
      ? "Yazdığın duruma bugün kısa ve sakin bir yerden yaklaşacağız."
      : "Bugün kısa ve sakin bir başlangıç yapacağız.")
    : (input.problemText
      ? "Today, we will approach what you described from a quiet, manageable place."
      : "Today, we will begin quietly and keep it manageable.");
  const blockIds = approvedBlockIdsFor(input.locale);
  const steps = Array.from({ length: 21 }, (_, index) => ({
    day: index + 1,
    title: isTurkish
      ? (index < 3 ? "Nefesi fark etmek" : index < 7 ? "Bedene dönmek" : index < 14 ? "Örüntüyü görmek" : "Küçük bir adım seçmek")
      : (index < 3 ? "Noticing the breath" : index < 7 ? "Returning to the body" : index < 14 ? "Seeing the pattern" : "Choosing one small step"),
    blockIds: [blockIds[index % blockIds.length]],
    slotCopy: {
      step_opening: index === 0
        ? opening
        : (isTurkish ? "Bugün bir önceki adımdan kalan yerden, acele etmeden devam edeceğiz." : "Today, we will continue gently from where the last step ended."),
      technique_bridge: isTurkish
        ? "Şimdi dikkati zorlamadan bu adıma getirebilirsin."
        : "You can bring your attention to this step without forcing it.",
      step_closing: isTurkish ? "Bugünlük burada durabiliriz." : "We can stop here for today.",
    },
    question: index === 20 ? null : fallbackQuestion(input.locale, primary),
  }));
  return validatePlan({
    kind: "personalized",
    title: isTurkish
      ? (titleByCategoryTR[primary] ?? titleByCategoryTR.unnamed)
      : (titleByCategoryEN[primary] ?? titleByCategoryEN.unnamed),
    templateId: `${primary}.three_weeks.v1`,
    lengthDays: 21,
    summary: `${primary}; ${input.duration ?? "unspecified"}; ${input.timing ?? "unspecified"}`.slice(0, 400),
    steps,
  });
}

function fallbackQuestion(locale: string, category: string): string {
  if (!locale.toLowerCase().startsWith("tr")) {
    const english: Record<string, string> = {
      sleep: "When did your mind feel busiest today?",
      focus: "When was it hardest to bring your attention back today?",
      burnout: "Which part of the day felt heaviest?",
      exam: "When did the pressure feel closest today?",
      social: "Which moment asked the most of you today?",
      anger: "What happened just before the intensity rose today?",
      selfcrit: "When was your inner voice hardest on you today?",
      grief: "Which moment felt most present today?",
      anxiety: "When did the tension feel strongest today?",
      unnamed: "What did you notice most clearly today?",
    };
    return english[category] ?? english.unnamed;
  }
  const turkish: Record<string, string> = {
    sleep: "Bugün zihnin en çok hangi anda hızlandı?",
    focus: "Bugün dikkatini geri getirmek en çok ne zaman zorlaştı?",
    burnout: "Günün hangi kısmı daha ağır geldi?",
    exam: "Bugün baskı en çok ne zaman yakındı?",
    social: "Bugün en çok hangi an seni zorladı?",
    anger: "Bugün yoğunluk yükselmeden hemen önce ne oldu?",
    selfcrit: "Bugün iç sesin en çok ne zaman sertleşti?",
    grief: "Bugün en belirgin gelen an hangisiydi?",
    anxiety: "Bugün gerginlik en çok ne zaman yükseldi?",
    unnamed: "Bugün en net neyi fark ettin?",
  };
  return turkish[category] ?? turkish.unnamed;
}

/// Path planını üreten çağrı.
///
/// ## İki denemeli: önce şemayla, sonra şemasız
///
/// Yapılandırılmış çıktı sağlayıcı tarafında reddedilebiliyor (model sürümü,
/// şema alt kümesi, hesap yetkisi — hepsi aynı `400 INVALID_ARGUMENT` ile
/// dönüyor). Tek denemeli sürüm bu durumda **sessizce yedek plana** düşüyordu:
/// ürün çalışıyor görünüyor ama her kullanıcı aynı yolu alıyor, yani
/// kişiselleştirme iddiası görünmeden çürüyor. İkinci deneme şemayı bırakıp
/// yalnızca JSON istiyor; çıktı zaten `validatePlan`dan geçtiği için model
/// var olmayan blok uyduramıyor, sınırların hiçbiri gevşemiyor.
export async function generateWithGemini(input: GeneratePathRequest): Promise<PathPlanDTO | null> {
  if (Deno.env.get("PATIKA_AI_LIVE_ENABLED") !== "true") return null;
  const key = Deno.env.get("GEMINI_API_KEY");
  if (!key) throw new Error("gemini_configuration_missing");

  try {
    return await attempt(input, key, true);
  } catch (error) {
    const message = error instanceof Error ? error.message : "";
    // Reddi sağlayıcının güvenlik kararı verdiği durum: yeniden denenmez,
    // kriz sinyali olarak yukarı taşınır (sinyal tek yönlüdür).
    if (message === "gemini_refusal") throw error;
    if (!message.startsWith("gemini_request_failed_400")) throw error;
    console.error("gemini_schema_rejected", message.slice(0, 120));
    return await attempt(input, key, false);
  }
}

/// Geçici sağlayıcı hatalarında (429/503) tek bir kısa yeniden deneme.
///
/// "Model şu an yoğun" cevabı yedek plan üretmek için yeterli sebep değil:
/// yedek çalışıyor görünüyor ama kullanıcıya kişiselleştirilmemiş bir yol
/// veriyor ve bu sessizce oluyor. Bir saniyelik bekleme, F1'in zaten sürdüğü
/// bekleyişin içinde kayboluyor.
async function attempt(
  input: GeneratePathRequest,
  key: string,
  usesSchema: boolean,
): Promise<PathPlanDTO> {
  try {
    return await callGemini(input, key, usesSchema);
  } catch (error) {
    const message = error instanceof Error ? error.message : "";
    const isTransient = message.startsWith("gemini_request_failed_503")
      || message.startsWith("gemini_request_failed_429")
      || message.startsWith("gemini_request_failed_500");
    if (!isTransient) throw error;
    console.error("gemini_transient", message.slice(0, 120));
    await new Promise((resolve) => setTimeout(resolve, 1_200));
    return await callGemini(input, key, usesSchema);
  }
}

async function callGemini(
  input: GeneratePathRequest,
  key: string,
  usesSchema: boolean,
): Promise<PathPlanDTO> {
  const model = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.5-flash";
  const fallback = fallbackPlan(input);
  const controller = new AbortController();
  // 20 sn yetmiyordu: 21 adımlık Türkçe plan düşünme süresiyle birlikte
  // bunun üstüne çıkıyor ve istek yarıda kesilip sessizce yedeğe düşüyordu.
  const timeout = setTimeout(() => controller.abort(), 45_000);
  const lengthDays = deterministicLengthDays(input);
  const schema = planJsonSchemaFor(input.locale, lengthDays);
  // Dil **açıkça** söylenir. Bloklar locale'e göre seçildiği hâlde model
  // metinleri İngilizce yazıyordu: Türkçe blok kimlikleriyle İngilizce açılış
  // cümlesi, oturumun ortasında dil değiştiren bir ses demekti.
  const isTurkishOutput = input.locale.toLowerCase().startsWith("tr");
  const language = isTurkishOutput ? "Turkish" : "English";
  // Marka sesi istemin parçası: model varsayılan olarak Türkçede "siz" diye
  // hitap ediyordu. Gece 2'de uyuyamayan birine resmî hitap, ürünün "yanında"
  // olma iddiasını ilk cümlede bozuyor (Ton eki §1).
  const voice = isTurkishOutput
    ? "Voice: calm, honest, alongside the reader. Address them informally (Turkish 'sen', never 'siz'). Almost never use exclamation marks."
    : "Voice: calm, honest, alongside the reader. Second person, plain language. Almost never use exclamation marks.";
  // Başlıklar cümle düzeninde yazılır: model varsayılan olarak Başlık
  // Düzeni ("Güne Veda Etmek") üretiyordu, arayüzün geri kalanı cümle
  // düzeninde ve iki stil yan yana durunca liste iki farklı üründen
  // toplanmış gibi görünüyor.
  const casing = "Write titles in sentence case, capitalising only the first word and proper nouns.";
  const bans = "Never promise an outcome, never claim therapy or clinical proof, never diagnose, never write celebratory praise, never mention streaks or other users.";
  try {
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`, {
      method: "POST",
      signal: controller.signal,
      headers: { "Content-Type": "application/json", "x-goog-api-key": key },
      body: JSON.stringify({
        systemInstruction: {
          parts: [{
            text: usesSchema
              ? `Write every user-visible string (title, step titles, slotCopy, question) in ${language}. ${voice} ${casing} ${bans} Produce exactly ${lengthDays} steps, numbered day 1 to ${lengthDays}. Select only approved block IDs. Do not recommend medication or add therapeutic exposure. Return JSON only.`
              : `Write every user-visible string (title, step titles, slotCopy, question) in ${language}. ${voice} ${casing} ${bans} Produce exactly ${lengthDays} steps, numbered day 1 to ${lengthDays}. Select only approved block IDs. Do not recommend medication or add therapeutic exposure. Return JSON only, matching this schema exactly: ${JSON.stringify(schema)}`,
          }],
        },
        contents: [{ role: "user", parts: [{ text: JSON.stringify({ language, safeSummary: fallback.summary, categories: input.categories, duration: input.duration, timing: input.timing, sessionMinutes: input.sessionMinutes, tone: input.tone, approvedBlockIds: approvedBlockIdsFor(input.locale) }) }] }],
        generationConfig: {
          responseMimeType: "application/json",
          ...(usesSchema ? { responseSchema: schema } : {}),
          temperature: 0.2,
        },
      }),
    });
    if (!response.ok) {
      // Sağlayıcının kendi hata kodu taşınıyor (gövde değil): "geçersiz model"
      // ile "geçersiz anahtar" aynı hata olarak görünürse üretim sessizce
      // yedeğe düşüyor ve bunu kimse fark etmiyor.
      const detail = await response.json().catch(() => null);
      const reason = detail?.error?.status ?? detail?.error?.code ?? "unknown";
      const message = Deno.env.get("PATIKA_AI_DEBUG") === "true"
        ? ` ${String(detail?.error?.message ?? "").slice(0, 200)}`
        : "";
      throw new Error(`gemini_request_failed_${response.status}_${reason}${message}`);
    }
    const payload = await response.json();
    const candidate = payload?.candidates?.[0];
    if (!candidate || candidate.finishReason === "SAFETY" || candidate.finishReason === "RECITATION") {
      throw new Error("gemini_refusal");
    }
    const text = candidate.content?.parts?.map((part: { text?: string }) => part.text ?? "").join("");
    if (!text) throw new Error("invalid_provider_response");
    const plan = validatePlan(JSON.parse(text));
    // Uzunluk sözleşme: model başka bir sayı döndürdüyse plan kabul edilmiyor.
    // Kısaltmak ya da doldurmak, eksik günü uydurmak olurdu.
    if (plan.steps.length !== lengthDays || plan.lengthDays !== lengthDays) {
      throw new Error("plan_length_mismatch");
    }
    return plan;
  } finally {
    clearTimeout(timeout);
  }
}

// TTS artık burada değil: `_shared/tts.ts`, aracısız ElevenLabs v3.
// fal.ai kuyruğu ve webhook imza doğrulaması kaldırıldı — doğrudan çağrı
// senkron ve zincirde bir veri işleyici daha az (PRD-Ek Oturum Motoru §3.3).

/// Gemini'nin yapılandırılmış çıktı şeması.
///
/// **`responseSchema` kullanılıyor, `responseJsonSchema` değil.** İkincisi
/// isteği `400 INVALID_ARGUMENT` ile reddettiriyordu ve `generate-path` sessizce
/// yedek plana düşüyordu. Bu, OpenAPI alt kümesi: tamsayı `enum` desteklemiyor
/// (bu yüzden `lengthDays` aralıkla yazılı) ve `additionalProperties` yok.
///
/// **Şema sade tutulur.** Önceki sürüm `additionalProperties` (hem `false` hem
/// şema olarak) ve `anyOf` kullanıyordu; sağlayıcı isteğin tamamını
/// `400 INVALID_ARGUMENT` ile reddediyor, `generate-path` sessizce yedek plana
/// düşüyordu — yani her kullanıcı aynı yolu alıyordu ve kişiselleştirme iddiası
/// görünmeden çürüyordu. Yuvalar artık tek tek yazılı; zaten dört tane ve
/// `schema.ts` de aynı dördünü doğruluyor.
/// Path uzunluğu **modelin takdiri değil**.
///
/// PRD-Ek Path Üretimi: sekiz adımın üçünde AI yok ve path uzunluğu bunlardan
/// biri. Model seçmesine izin verildiğinde aynı girdiye 7 günlük de 21 günlük de
/// yol üretiyordu; "ölçülen ve biten program" iddiası, süreyi bir modelin
/// belirlediği üründe anlamını kaybediyor.
///
/// Bugünkü kural tek değer: 21 gün (PRD §9.3'ün standart arkı). Şiddete göre
/// uzunluk seçimi geldiğinde **yalnızca burası** değişir.
export function deterministicLengthDays(_input: GeneratePathRequest): number {
  return 21;
}

function planJsonSchemaFor(locale: string, lengthDays: number) {
  return {
    type: "object",
    required: ["kind", "title", "templateId", "lengthDays", "summary", "steps"],
    properties: {
      kind: { type: "string", enum: ["personalized"] },
      title: { type: "string", maxLength: 120 },
      templateId: { type: "string", maxLength: 100 },
      lengthDays: { type: "integer", minimum: lengthDays, maximum: lengthDays },
      summary: { type: "string", maxLength: 400 },
      steps: {
        type: "array",
        minItems: lengthDays,
        maxItems: lengthDays,
        items: {
          type: "object",
          required: ["day", "title", "blockIds", "slotCopy"],
          properties: {
            day: { type: "integer", minimum: 1, maximum: 28 },
            title: { type: "string", maxLength: 120 },
            blockIds: {
              type: "array",
              minItems: 1,
              maxItems: 12,
              items: { type: "string", enum: approvedBlockIdsFor(locale) },
            },
            slotCopy: {
              type: "object",
              required: ["step_opening", "technique_bridge", "step_closing"],
              properties: {
                step_opening: { type: "string", maxLength: 520 },
                technique_bridge: { type: "string", maxLength: 520 },
                mid_bridge: { type: "string", maxLength: 520 },
                step_closing: { type: "string", maxLength: 520 },
              },
            },
            question: { type: "string", maxLength: 120 },
          },
        },
      },
    },
  };
}
