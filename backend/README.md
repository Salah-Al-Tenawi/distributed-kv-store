# Backend — Distributed KV Store Cluster

عنقود من 5 عُقَد (Node.js) يطبّق مفاهيم الأنظمة الموزّعة (mini-Raft).

## التشغيل

```bash
cd backend
npm install        # أول مرة فقط
npm run cluster    # يشغّل العُقَد الخمسة (المنافذ 4001..4005)
```

لتشغيل عقدة واحدة فقط:

```bash
npm run node            # node-1 افتراضياً
node src/index.js node-3
```

## نقاط الوصول لكل عقدة

- `GET  http://localhost:<port>/health` — حالة العقدة (JSON)
- `ws://localhost:<port>` — بثّ الحالة لحظياً (يستهلكه تطبيق Flutter)

## البنية

```
src/
├── index.js              نقطة الدخول: تشغّل عقدة واحدة
├── config.js             إعدادات العنقود (العُقَد، المنافذ، المهلات)
├── node/
│   ├── Node.js           كلاس العقدة (الحالة)
│   └── states.js         FOLLOWER | CANDIDATE | LEADER
└── transport/
    └── dashboard.js      سيرفر HTTP + WebSocket لبثّ الحالة
scripts/
└── start-cluster.js      يشغّل العُقَد الخمسة دفعة واحدة
```

> الحالة الحالية: **Phase 0** (هيكل + اتصال). المنطق الموزّع يُضاف تدريجياً (انتخاب، نبضات، نسخ، أقفال) — انظر `../ROADMAP.md`.
