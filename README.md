# Distributed Key-Value Store

مشروع لمادة الأنظمة الموزّعة. مخزن مفاتيح وقيم موزّع على 5 عُقَد، مبني على فكرة بروتوكول Raft، مع واجهة ويب للتحكّم والمراقبة الحيّة.

## المفاهيم المطبّقة

- Leader Election (انتخاب القائد)
- Heartbeats & Failure Detection (النبضات وكشف الأعطال)
- Log / Data Replication (نسخ البيانات)
- Fault Tolerance & Network Partition (تحمّل الأعطال وانقسام الشبكة)
- Distributed Locks مع TTL و Fencing Token
- Two-Phase Commit (2PC)
- Vector Clocks
- Consistent Hashing / Sharding

## التقنيات

- الـ Backend: Node.js (Express + ws)، عنقود من 5 عُقَد تتواصل عبر RPC.
- الواجهة: Flutter Web (Clean Architecture + Cubit).

## التشغيل محلياً

الـ backend (طرفية أولى):

```bash
cd backend
npm install
npm run cluster
```

الواجهة (طرفية ثانية):

```bash
flutter pub get
flutter run -d chrome
```

## تشغيله كخدمة واحدة (مع رابط عام)

```bash
flutter build web --dart-define=GATEWAY=true
cp -r build/web/* backend/public/
cd backend && npm start
```

ثم لمشاركة رابط عام مؤقّت يُستخدم `share.bat` (عبر Cloudflare Tunnel).

## بنية المشروع

```
backend/   العنقود (Node.js): العُقَد + البوّابة + منطق Raft
lib/       تطبيق Flutter (core / features/cluster: data, domain, presentation)
```
