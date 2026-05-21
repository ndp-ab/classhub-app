# FRONTEND_FUND_PROGRESS

Tiến độ Flutter `classhub_app` cho 3 phân hệ: **Chi tiết lớp**, **Quỹ lớp**, **Sự kiện**.
Cập nhật lần cuối: 2026-05-16 — sau khi áp dụng GP1 (Member báo đã CK).

---

## 1. Đã làm

### Màn hình đã tạo
- `lib/screens/classroom_detail_screen.dart` — TabBar 4 tab: **Tổng quan / Khoản thu / Khoản chi / Sự kiện**.
- `lib/screens/fund/fund_tab.dart` — list đợt thu + section "Khoản của bạn" cho Member (kèm nút "Xem QR").
- `lib/screens/fund/payment_qr_screen.dart` — hiển thị QR + polling status mỗi 5s, dispose timer khi thoát màn, dừng polling khi confirmed.
- `lib/screens/fund/collection_payments_screen.dart` — Admin xem ai đóng/chưa + nút **Xác nhận** (có confirm dialog).
- `lib/screens/fund/create_collection_screen.dart` — form tạo đợt thu (title, amount, deadline picker).
- `lib/screens/fund/expenses_screen.dart` — list khoản chi + tổng chi.
- `lib/screens/fund/create_expense_screen.dart` — form tạo khoản chi (title, amount, reason).
- `lib/screens/events/events_tab.dart` — Member đăng ký/huỷ; Admin tạo + xem participants.
- `lib/screens/events/create_event_screen.dart` — form sự kiện với date + time picker.
- `lib/screens/events/event_participants_screen.dart` — Admin xem & check-in (có confirm dialog).

### Màn hình đã sửa
- `lib/screens/home_screen.dart` — bấm card lớp → mở `ClassroomDetailScreen`.

### Service đã tạo
- `lib/services/fund_service.dart` — 9 endpoint Fund.
- `lib/services/event_service.dart` — 7 endpoint Event.

### Service đã sửa
- `lib/services/classroom_service.dart` — bỏ `X-User-Id`, dùng `Authorization: Bearer` (đồng bộ với BE B1).
- `lib/services/fund_service.dart` & `event_service.dart` — bỏ `X-User-Id`, chỉ Bearer.

### Model
- `lib/models/fund_collection.dart` — `FundCollection`.
- `lib/models/payment.dart` — `Payment` (parse `amount`, `deadline`, `confirmedByName` sau B3).
- `lib/models/expense.dart` — `Expense`.
- `lib/models/event.dart` — `ClassEvent` + `EventParticipant` (parse `eventId`, `checkedByName` sau B4).

### Lần này (polish UX)
- Thêm **confirm dialog** trước khi admin xác nhận thanh toán (chống lỡ tay).
- Thêm **confirm dialog** trước khi admin check-in sinh viên.

### GP1 — Member tự báo đã chuyển khoản (2026-05-16)
- `PaymentQrScreen`: thêm nút **"Tôi đã chuyển khoản"** dưới QR (chỉ hiện khi UNPAID). Confirm dialog trước khi gọi API.
- `PaymentQrScreen`: status box 3 màu — orange (UNPAID), blue (PENDING_VERIFICATION), green (CONFIRMED).
- `FundTab` section "Khoản của bạn": nhóm thành **3 nhóm** (Chưa CK / Đã báo / Đã xác nhận) — counter `Chưa CK: X • Đã báo: Y • Đã xác nhận: Z`.
- `CollectionPaymentsScreen` (Admin): nhóm payments thành **3 section** với heading màu (PENDING ở trên cùng để admin ưu tiên xử lý).
- Model `Payment` thêm enum `PaymentStatus { unpaid, pendingVerification, confirmed }` + getter convenience (`isUnpaid`, `isPending`, `isConfirmed`).
- Service `fund_service.dart` thêm `markPaymentAsPaid(paymentId, userId)`.

---

## 2. Luồng hiện tại

```
Login → Home (danh sách lớp)
         │
         └─ Tap card lớp → ClassroomDetailScreen (4 tab)
                            │
                            ├─ Tổng quan: tên lớp, khoa, khóa, vai trò, mã mời (copy)
                            │
                            ├─ Khoản thu (FundTab)
                            │   ├─ Member:
                            │   │     "Khoản của bạn" → Xem QR
                            │   │              → PaymentQrScreen (polling 5s)
                            │   │              → khi CONFIRMED: hiện "Đã thanh toán & được xác nhận"
                            │   └─ Admin:
                            │         FAB "Tạo đợt thu" → CreateCollectionScreen
                            │         Tap card đợt thu → CollectionPaymentsScreen
                            │               → confirm dialog → "Xác nhận"
                            │
                            ├─ Khoản chi (ExpensesScreen)
                            │   └─ Admin: FAB "Thêm khoản chi"
                            │
                            └─ Sự kiện (EventsTab)
                                ├─ Member: nút Đăng ký / Huỷ đăng ký
                                └─ Admin: FAB "Tạo sự kiện"
                                          "Người tham gia" → confirm dialog → Check-in
```

---

## 3. API đã tích hợp

| API | Màn hình sử dụng | Trạng thái | Ghi chú |
|---|---|---|---|
| `POST /api/auth/register` | `SignupScreen` | ✅ | |
| `POST /api/auth/login` | `LoginScreen` | ✅ | Trả JWT, FE lưu vào SharedPreferences |
| `GET /api/classrooms/my` | `HomeScreen` | ✅ | Gửi Bearer (sau B1) |
| `POST /api/classrooms/create` | `CreateClassroomScreen` | ✅ | |
| `POST /api/classrooms/join` | `JoinClassroomScreen` | ✅ | BE B6: tự sinh payment bổ sung |
| `GET /api/fund/collections/{classroomId}` | `FundTab` | ✅ | requireMember |
| `POST /api/fund/collections` | `CreateCollectionScreen` | ✅ | requireAdmin; amount validate >= 0.01 |
| `GET /api/fund/collections/{collectionId}/payments` | `CollectionPaymentsScreen` | ✅ | requireAdmin |
| `PUT /api/fund/payments/{paymentId}/confirm` | `CollectionPaymentsScreen` | ✅ | Idempotent: confirm 2 lần báo lỗi |
| `POST /api/fund/payments/{paymentId}/mark-paid` (GP1) | `PaymentQrScreen` | ✅ | Member tự báo đã CK — chuyển sang PENDING_VERIFICATION |
| `GET /api/fund/payments/my/{classroomId}` | `FundTab` ("Khoản của bạn") | ✅ | Hiển thị amount + deadline (B3 bonus) |
| `GET /api/fund/payments/{paymentId}/qr` | `PaymentQrScreen` | ✅ | Chỉ chủ payment mới được xem |
| `GET /api/fund/payments/{paymentId}/status` | `PaymentQrScreen` (polling) | ✅ | 5s/lần, dừng khi CONFIRMED |
| `GET /api/fund/expenses/{classroomId}` | `ExpensesScreen` | ✅ | requireMember |
| `POST /api/fund/expenses` | `CreateExpenseScreen` | ✅ | requireAdmin |
| `GET /api/events/{classroomId}` | `EventsTab` | ✅ | requireMember |
| `POST /api/events` | `CreateEventScreen` | ✅ | requireAdmin; `eventTime` gửi ISO không có `Z` |
| `POST /api/events/{eventId}/volunteer` | `EventsTab` | ✅ | BE chặn đăng ký trùng |
| `DELETE /api/events/{eventId}/volunteer` | `EventsTab` | ✅ | BE chặn huỷ khi đã check-in |
| `GET /api/events/{eventId}/participants` | `EventParticipantsScreen` | ✅ | requireAdmin |
| `PUT /api/events/{eventId}/checkin/{userId}` | `EventParticipantsScreen` | ✅ | Lưu `checkedBy` (B4) |
| `GET /api/events/my/{classroomId}` | `EventsTab` | ✅ | Match đã đăng ký qua `eventId` (sau B4) |

---

## 4. File đã tạo/sửa

| File | Mục đích |
|---|---|
| `lib/models/fund_collection.dart` | Tạo — model đợt thu |
| `lib/models/payment.dart` | Tạo — parse amount/deadline/confirmedByName (cập nhật theo B3) |
| `lib/models/expense.dart` | Tạo — model khoản chi |
| `lib/models/event.dart` | Tạo — `ClassEvent` + `EventParticipant` (eventId/checkedByName theo B4) |
| `lib/services/fund_service.dart` | Tạo — 9 API Fund, gửi Bearer |
| `lib/services/event_service.dart` | Tạo — 7 API Event, gửi Bearer |
| `lib/services/classroom_service.dart` | Sửa — bỏ `X-User-Id`, dùng Bearer |
| `lib/screens/classroom_detail_screen.dart` | Tạo — 4 tab |
| `lib/screens/fund/fund_tab.dart` | Tạo — list + section "Khoản của bạn" hiện amount/deadline |
| `lib/screens/fund/payment_qr_screen.dart` | Tạo — QR + polling 5s |
| `lib/screens/fund/collection_payments_screen.dart` | Tạo — Admin xác nhận (có confirm dialog) |
| `lib/screens/fund/create_collection_screen.dart` | Tạo — form tạo đợt thu |
| `lib/screens/fund/expenses_screen.dart` | Tạo — list khoản chi |
| `lib/screens/fund/create_expense_screen.dart` | Tạo — form tạo khoản chi |
| `lib/screens/events/events_tab.dart` | Tạo — Member volunteer / Admin tạo |
| `lib/screens/events/create_event_screen.dart` | Tạo — form sự kiện (date+time picker) |
| `lib/screens/events/event_participants_screen.dart` | Tạo — Admin check-in (có confirm dialog) |
| `lib/screens/home_screen.dart` | Sửa — tap card mở `ClassroomDetailScreen` |

---

## 5. Phần còn thiếu / TODO

### Backend chưa có API → FE đang phải bỏ
- ❌ **Tab Thành viên** — BE chưa có `GET /api/classrooms/{id}/members`. Đã bỏ tab này (4 tab thay vì 5).
- ❌ **Dashboard / Thống kê quỹ** — BE chưa có `GET /api/classrooms/{id}/fund-statistics`. Slide demo sẽ thiếu số liệu tổng quan.
- ❌ **Admin assign participant** — BE chưa có `POST /api/events/{id}/assign`. Hiện chỉ có Member tự đăng ký, không có flow Admin chỉ định.
- ❌ **Sửa/xoá** collection / event / expense — BE chưa có `PUT/DELETE`. Tạo nhầm thì stuck.

### Role
- ✅ **Đã giải quyết:** BE trả `role` (`ADMIN`/`MEMBER`) trong `/api/classrooms/my`. FE truyền qua constructor `ClassroomDetailScreen.role`, check `_isAdmin = role == 'ADMIN' || role == 'OWNER'`.
- ⚠️ Nếu BE sau này thêm cấp `OWNER` thì FE đã forward-compat.

### QR response
- ✅ **Đã rõ:** BE trả `qrUrl` (VietQR), `amount`, `paymentCode`, `collectionTitle`, `deadline`. FE hiển thị đầy đủ.
- ⚠️ `qrUrl` từ `img.vietqr.io` — cần thiết bị có internet công cộng (không phải mạng nội bộ).

### Expense UI
- ✅ **Đã xong:** list + tổng chi + FAB tạo khoản chi (chỉ Admin).
- ⚠️ Chưa có sửa/xoá (BE chưa hỗ trợ).

### Event
- ✅ **Đã làm xong** sau khi BE confirm có Event API. 7/7 endpoint tích hợp.

### UI polish chưa làm (optional)
- Format tiền bằng `intl` package thay vì hardcode (hiện format thủ công `"50.000 đ"`).
- Badge số khoản nợ chưa đóng trên card lớp ở Home.
- Loading skeleton thay `CircularProgressIndicator`.
- Test thiết bị thật / emulator Android (đổi `baseUrl` → `http://10.0.2.2:8080/api`).

---

## 6. Bug / rủi ro hiện tại

| # | Rủi ro | Mức độ | Ghi chú |
|---|---|---|---|
| 1 | **Token** đã lưu đúng ở `SharedPreferences` (key `jwt_token`). Tất cả service gửi `Authorization: Bearer`. | ✅ OK | Không còn `X-User-Id` |
| 2 | **Role check** hard-code `'ADMIN'` / `'OWNER'`. BE hiện chỉ trả `'ADMIN'` hoặc `'MEMBER'`. | ✅ OK | Nhưng nếu BE đổi case (`'admin'`) thì sai |
| 3 | **Response JSON không khớp model** — Lombok+Jackson có thể serialize `isPaid` thành `paid`. | ✅ Đã xử lý | `Payment.fromJson` parse cả 2: `json['isPaid'] ?? json['paid']` |
| 4 | **Polling QR 5s** — đã `dispose()` timer khi thoát màn. Mất mạng → fail silent (không update state). | ⚠️ Chấp nhận được | Không gây crash; chỉ không update |
| 5 | **`eventTime` format** — gửi ISO không có `Z` (`2026-05-20T18:00:00`). BE nhận `LocalDateTime` (no TZ). | ⚠️ | Thiết bị test khác múi giờ có thể lệch giờ |
| 6 | **`qrUrl` `Image.network`** — nếu mất mạng → có `errorBuilder` fallback "Không tải được QR" | ✅ OK | |
| 7 | **Confirm dialog** đã thêm cho 2 action destructive (xác nhận / check-in) | ✅ OK | Chống lỡ tay |
| 8 | **Lỗi 401** từ BE (token hết hạn) — service chỉ hiện "Bạn không có quyền (401)". FE không tự động redirect về Login. | ⚠️ | Để post-demo |
| 9 | **`baseUrl` hardcode** `http://localhost:8080/api` ở 4 service. | ⚠️ | Phải đổi tay khi test emulator/device |

---

## 7. Hướng dẫn test nhanh

### Chạy BE
```bash
cd D:/big_dream/classhub-api
./mvnw spring-boot:run
```
BE chạy ở `http://localhost:8080`. MySQL phải đang chạy (`classhub_db`).

### Chạy app
```bash
cd D:/big_dream/classhub_app
flutter pub get
flutter run
```

### Đổi `baseUrl` tuỳ thiết bị test
4 file phải đổi cùng nhau:
- `lib/services/auth_service.dart`
- `lib/services/classroom_service.dart`
- `lib/services/fund_service.dart`
- `lib/services/event_service.dart`

Tuỳ thiết bị:
| Thiết bị | baseUrl |
|---|---|
| Chrome web / Windows desktop | `http://localhost:8080/api` |
| Android emulator | `http://10.0.2.2:8080/api` |
| Thiết bị Android thật (cùng LAN) | `http://<IP-máy-tính>:8080/api` (vd `192.168.1.5`) |

> Trong code có sẵn dòng comment `http://192.168.1.5:8080/api` để switch nhanh.

### Tài khoản test
Chưa có seed. **Tự tạo 2 tài khoản** qua màn `signup_screen`:
- User A — sẽ là Admin (tạo lớp)
- User B — sẽ là Member (join lớp)

### Luồng test đề xuất

**Phân hệ Quỹ:**
1. A đăng ký → đăng nhập → "Tạo lớp" → copy mã mời (vd `ABC123`).
2. Logout. B đăng ký → đăng nhập → "Tham gia" → nhập `ABC123`.
3. Logout. A đăng nhập → tap card lớp → tab Khoản thu → FAB "Tạo đợt thu" (vd 50.000đ, deadline hôm sau).
4. Logout. B đăng nhập → tap card lớp → tab Khoản thu → thấy "Khoản của bạn" với "50.000 đ • Hạn: dd/mm/yyyy".
5. B bấm "Xem QR" → QR hiển thị, status "Đang chờ admin xác nhận...".
6. Logout. A đăng nhập → tap card lớp → tab Khoản thu → tap card đợt thu → thấy danh sách (B chưa đóng).
7. A bấm "Xác nhận" → confirm dialog → bấm "Xác nhận" lần 2 → snackbar xanh "Đã xác nhận thanh toán".
8. Logout. B đăng nhập → vẫn ở màn QR (nếu mở) → trong ≤5s status đổi sang **"Đã thanh toán & được xác nhận"** ✅

**Phân hệ Khoản chi:**
9. A: tab Khoản chi → FAB "Thêm khoản chi" → thấy hiện trong list + tổng chi cập nhật.

**Phân hệ Sự kiện:**
10. A: tab Sự kiện → FAB "Tạo sự kiện" → chọn ngày giờ → tạo.
11. B: tab Sự kiện → bấm "Đăng ký" → chip "Đã đăng ký" hiện ra.
12. A: tab Sự kiện → tap "Người tham gia" → thấy B → bấm "Check-in" → confirm dialog → snackbar xanh.
13. B: tab Sự kiện → reload → counter "Check-in: 1" tăng lên.

### Test BE bằng Postman (smoke test 401)
1. `POST /api/auth/register` → lấy `token`.
2. `GET /api/classrooms/my` **không kèm** header `Authorization` → phải trả JSON 401:
   ```json
   {"status":401,"message":"Chưa đăng nhập hoặc token không hợp lệ"}
   ```
3. `GET /api/classrooms/my` **kèm** `Authorization: Bearer <token>` → 200, body `[]`.

Nếu 401 trả HTML hoặc 200 cho cả 2 case → BE chưa hoạt động đúng.
