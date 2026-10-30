# gym-assistant
مساعد الجم: خطط تمارين وتعليم أداء التمارين بالعربي.

## البيانات
- `data/exercises_en.json`: 876 تمرين من [free-exercise-db](https://github.com/yuhonas/free-exercise-db) (ملكية عامة / Unlicense) ويّا صور الحركة.
- `data/dictionary_ar.json`: ترجمة العضلات والأدوات والمستويات.
- `tools/translate.py`: يترجم الأسماء والخطوات بـ Gemini ويطلع `data/exercises_ar.json`.
