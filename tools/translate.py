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

API_KEY = os.environ.get("GEMINI_API_KEY", "").strip()
MODEL = os.environ.get("GEMINI_MODEL", "gemini-flash-latest")
BATCH = 8            # عدد التمارين بكل طلب
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
            with urllib.request.urlopen(req, timeout=120) as r:
                data = json.load(r)
            text = data["candidates"][0]["content"]["parts"][0]["text"]
            return {x["id"]: x for x in json.loads(text)["items"]}
        except urllib.error.HTTPError as e:
            wait = 30 * (attempt + 1) if e.code == 429 else 10
            print(f"  خطأ {e.code}، أنتظر {wait} ثانية...")
            time.sleep(wait)
        except (KeyError, ValueError, urllib.error.URLError) as e:
            print(f"  رد غير صالح ({e})، أعيد المحاولة...")
            time.sleep(10)
    return {}


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

    todo = [e for e in src if e["id"] not in done]
    print(f"المجموع {len(src)} | مترجم {len(done)} | باقي {len(todo)}")

    for i in range(0, len(todo), BATCH):
        batch = todo[i:i + BATCH]
        result = call_gemini(batch)
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
        print(f"  ✓ {len(done)}/{len(src)}")
        time.sleep(PAUSE)

    print("خلصت ✅" if len(done) == len(src) else "باقي تمارين، شغّل السكربت مرة ثانية.")


if __name__ == "__main__":
    main()
