# 🗄️ Distributed Key-Value Store — مخزن مفاتيح-قيم موزّع

> مشروع مادة **الأنظمة الموزّعة (Distributed Systems)** — جامعة دمشق، كلية هندسة تقنية المعلومات.
> نواة بروتوكول **Raft** مع لوحة تحكّم ومراقبة حيّة، يطبّق **٨ مفاهيم** أساسية في الأنظمة الموزّعة.

## 🌐 العرض الحيّ (Live Demo)

> الرابط: _(يُضاف بعد النشر على Render)_ — افتحه وجرّب كل الأزرار بنفسك.

---

## 🎯 المفاهيم المطبّقة (8 Concepts)

| # | المفهوم | الوصف |
|---|---------|-------|
| 1 | **Leader Election** (انتخاب القائد) | انتخاب قائد واحد لامركزياً عبر مؤقّتات عشوائية وأغلبية (Raft) |
| 2 | **Heartbeats & Failure Detection** | نبضات دورية + كشف موت العُقَد وتمييزها OFFLINE |
| 3 | **Log / Data Replication** | نسخ السجلّ للأغلبية ثم التثبيت (Committed) — مخزن KV قوي التناسق |
| 4 | **Fault Tolerance & Network Partition** | تحمّل الأعطال + حماية Split-Brain + Election Restriction |
| 5 | **Distributed Locks** | إقصاء متبادل + مهلة TTL + رمز حماية (Fencing Token) |
| 6 | **Two-Phase Commit (2PC)** | معاملة موزّعة ذرّية (الكل يلتزم أو الكل يلغي) |
| 7 | **Vector Clocks** | تتبّع السببية وتمييز الأحداث المتزامنة |
| 8 | **Consistent Hashing / Sharding** | توزيع المفاتيح على حلقة تجزئة مع إعادة توزيع أدنى |

التفاصيل الكاملة والأكواد في **[REPORT.md](REPORT.md)**، وخطة العمل في **[ROADMAP.md](ROADMAP.md)**.

---

## 🏗️ البنية المعمارية

```
        ┌──────────────────────────────┐
        │   Flutter Web Dashboard       │  ← لوحة تحكّم ومراقبة حيّة
        └───────────────┬──────────────┘
                        │  WebSocket (الحالة) + HTTP (الأوامر)
        ┌───────────────┴──────────────┐
        │   Aggregator Gateway (Node)   │  ← خدمة واحدة عامة
        │   تخدم الواجهة + توجّه للعُقَد   │
        └───────────────┬──────────────┘
        ┌───────────────┴──────────────┐
        │   Cluster: 5 Nodes (Node.js)  │  ← node-1 .. node-5
        └──────────────────────────────┘
```

- **Backend:** Node.js (Express + ws) — عنقود من ٥ عُقَد، لكل منها HTTP + WebSocket، تتواصل عبر RPC.
- **Frontend:** Flutter Web بمعمارية **Clean Architecture + Cubit (Bloc)**.
- **Gateway:** يجمع كل شيء خلف منفذ عام واحد ليُنشَر كخدمة واحدة.

---

## ▶️ التشغيل محلياً (Local Development)

**المتطلّبات:** Node.js 20+ و Flutter 3+.

```bash
# 1) الـ backend (العنقود) — طرفية أولى
cd backend
npm install
npm run cluster          # يشغّل 5 عُقَد على المنافذ 4001..4005

# 2) الواجهة — طرفية ثانية
flutter pub get
flutter run -d chrome    # يتصل بالعُقَد على localhost مباشرةً
```

### تشغيل عبر البوّابة (كما في النشر)
```bash
flutter build web --dart-define=GATEWAY=true   # بناء الواجهة بوضع البوّابة
cp -r build/web/* backend/public/              # نسخها لمجلّد البوّابة
cd backend && npm start                        # خدمة واحدة على :8080
# افتح http://localhost:8080
```

---

## 🚀 النشر (Deployment)

خدمة واحدة على **Render** (راجع [render.yaml](render.yaml)):
- `rootDir: backend` · `build: npm install` · `start: npm start`
- البوّابة تشغّل العُقَد الخمسة وتخدم الواجهة من `backend/public/` وتوجّه WS/HTTP.

> ملاحظة: على الطبقة المجانية قد "تنام" الخدمة عند الخمول؛ أوّل فتحة بعد الخمول أبطأ قليلاً.

---

## 📂 بنية المشروع

```
backend/                  العنقود + البوّابة (Node.js)
  src/
    index.js              تشغيل عقدة واحدة
    gateway.js            البوّابة (نشر بخدمة واحدة)
    config.js             إعدادات العنقود والمهلات
    node/                 election · replication · twoPhaseCommit · vectorClock · ...
    transport/            peerRpc · dashboard · clientApi · lockApi · txnApi · vcApi · admin
    store/kvStore.js      آلة الحالة (State Machine)
  public/                 واجهة Flutter المبنيّة (تُخدَم عبر البوّابة)
lib/                      تطبيق Flutter (Clean Architecture)
  core/                   network · di · util (consistent hash ring) · constants
  features/cluster/       data · domain · presentation (Cubit + widgets)
```

---

## 📜 الترخيص

مشروع أكاديمي لأغراض تعليمية.
