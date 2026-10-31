"""
ترجمة قاعدة التمارين للعربي باستخدام Gemini المجاني.

التشغيل:
    set GEMINI_API_KEY=مفتاحك        (ويندوز)
    python tools/translate.py

- الحقول الثابتة (العضلات، الأدوات، المستوى...) تتترجم من data/dictionary_ar.json بدون ذكاء.
- الاسم وخطوات الأداء يترجمهم Gemini على دفعات.
- السكربت يكمل من حيث وقف: إذا انقطع، شغّله مرة ثانية.
- الناتج: data/exercises_ar.json
"""
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "data" / "exercises_en.json"
DICT = ROOT / "data" / "dictionary_ar.json"
OUT = ROOT / "data" / "exercises_ar.json"

API_KEY = (os.environ.get("GEMINI_API_KEY2") or os.environ.get("GEMINI_API_KEY") or "").strip()
LIMIT = int(os.environ.get("LIMIT") or 150)   # عدد التمارين بكل جزء
MODEL = os.environ.get("GEMINI_MODEL", "gemini-flash-lite-latest")
BATCH = 15           # عدد التمارين بكل طلب
PAUSE = 5            # ثواني بين الطلبات (حدود الخطة المجانية)
IMG_BASE = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/"

PROMPT = """أنت مترجم متخصص بالرياضة وكمال الأجسام.
ترجم أسماء التمارين وخطوات أدائها التالية إلى العربية الفصحى البسيطة المفهومة للاعب الجم العراقي.
- اسم التمرين: ترجمة واضحة، واترك المصطلح المشهور بالجم كما يُلفظ إذا كان أوضح (مثل: بنش بريس، سكوات، ديدلفت).
- الخطوات: نفس العدد ونفس الترتيب، جمل قصيرة وواضحة.
أرجع JSON فقط بهذا الشكل:
{"items":[{"id":"...","name_ar":"...","instructions_ar":["...","..."]}]}

التمارين:
"""


class QuotaDone(Exception):
    pass


def call_gemini(batch):
    payload = [{"id": e["id"], "name": e["name"], "instructions": e["instructions"]} for e in batch]
    body = {
        "contents": [{"parts": [{"text": PROMPT + json.dumps(payload, ensure_ascii=False)}]}],
        "generationConfig": {"responseMimeType": "application/json", "temperature": 0.2},
    }
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent"
    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json", "x-goog-api-key": API_KEY},
    )
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=300) as r:
                data = json.load(r)
            text = data["candidates"][0]["content"]["parts"][0]["text"]
            return {x["id"]: x for x in json.loads(text)["items"]}
        except urllib.error.HTTPError as e:
            if e.code in (400, 401, 403, 404):
                msg = f"خطأ {e.code} (المفتاح أو اسم الموديل): {e.read()[:500]!r}"
                log(msg)
                sys.exit(msg)
            if e.code == 429 and attempt >= 2:
                raise QuotaDone()
            wait = 30 * (attempt + 1) if e.code == 429 else 10
            log(f"  خطأ {e.code}، أنتظر {wait} ثانية...")
            time.sleep(wait)
        except Exception as e:
            log(f"  مشكلة ({type(e).__name__}: {e})، أعيد المحاولة...")
            time.sleep(10)
    return {}


def log(msg):
    print(msg, flush=True)
    with open(ROOT / "data" / "translate_log.txt", "a", encoding="utf-8") as f:
        f.write(msg + "\n")


def tr(d, key, val):
    return d[key].get(val, val) if val else None


def main():
    if not API_KEY:
        sys.exit("ضع المفتاح أولاً: set GEMINI_API_KEY=...")

    src = json.loads(SRC.read_text(encoding="utf-8"))
    d = json.loads(DICT.read_text(encoding="utf-8"))
    done = {}
    if OUT.exists():
        done = {e["id"]: e for e in json.loads(OUT.read_text(encoding="utf-8"))}

    todo = [e for e in src if e["id"] not in done][:LIMIT]
    log(f"المجموع {len(src)} | مترجم {len(done)} | هذا الجزء {len(todo)}")

    for i in range(0, len(todo), BATCH):
        batch = todo[i:i + BATCH]
        try:
            result = call_gemini(batch)
        except QuotaDone:
            log("انتهت الحصة المجانية لليوم، أوقف وأحفظ اللي خلص.")
            break
        for e in batch:
            t = result.get(e["id"])
            if not t or len(t.get("instructions_ar", [])) == 0:
                continue  # يتعاد بالتشغيل الجاي
            done[e["id"]] = {
                "id": e["id"],
                "name_en": e["name"],
                "name_ar": t["name_ar"],
                "level": tr(d, "level", e.get("level")),
                "category": tr(d, "category", e.get("category")),
                "equipment": tr(d, "equipment", e.get("equipment")),
                "force": tr(d, "force", e.get("force")),
                "mechanic": tr(d, "mechanic", e.get("mechanic")),
                "primary_muscles": [tr(d, "muscles", m) for m in e["primaryMuscles"]],
                "secondary_muscles": [tr(d, "muscles", m) for m in e["secondaryMuscles"]],
                "instructions_ar": t["instructions_ar"],
                "instructions_en": e["instructions"],
                "images": [IMG_BASE + p for p in e["images"]],
            }
        # نحفظ بعد كل دفعة حتى ما يضيع شي
        ordered = [done[e["id"]] for e in src if e["id"] in done]
        OUT.write_text(json.dumps(ordered, ensure_ascii=False, indent=1), encoding="utf-8")
        log(f"  ✓ {len(done)}/{len(src)}")
        time.sleep(PAUSE)

    log("خلصت كل التمارين ✅" if len(done) == len(src) else f"خلص الجزء: {len(done)}/{len(src)}، شغّل الجزء الجاي.")


if __name__ == "__main__":
    main()
