---
description: Elite Flutter Animation command. Dịch mô tả lời người dùng → animation keyword → research thư viện → implement animation hiện đại, 3D-feel, cinematic, không lỗi UI/pixel.
tools: web_search, web_fetch, edit_file, read_file
---

Dùng skill `hau-flutter-animate` tại `skills/hau-animate/SKILL.md` cho toàn bộ tác vụ này.

---

## ⚠️ MANDATORY PIPELINE — KHÔNG ĐƯỢC BỎ QUA BƯỚC NÀO

### BƯỚC 1 — DỊCH MÔ TẢ → ANIMATION KEYWORD

Phân tích prompt người dùng → xác định:
- **Loại animation**: entrance / exit / scroll / gesture / transition / idle / state-change
- **Cảm giác**: spring / smooth / dramatic / subtle / playful / premium / 3D
- **Đối tượng**: widget nào, context nào trong UI
- **Trigger**: on load / on tap / on scroll / on state change / loop

Bảng dịch nhanh:
```
"như 3D"           → perspective transform / Matrix4 depth / parallax layers
"mượt trôi"        → spring simulation / ease-out-cubic / physics scroll
"bung ra đẹp"      → scale+fade reveal / hero expand / container transform
"loading xịn"      → shimmer skeleton / lottie loader / pulse + scale
"nút đẹp khi bấm" → press scale / morph button / ripple custom
"chuyển màn xịn"  → shared axis / container transform / fade-through
"có chiều sâu"     → parallax scroll / layered depth / 3D tilt on gesture
"hạt pháo"         → confetti particle / rive celebration
"số đếm động"      → rolling digit / odometer / counter tween
"text xuất hiện"   → typewriter / staggered char / slide+fade
"card xuất hiện"   → staggered entrance / cascade reveal / slide+fade+scale
```

### BƯỚC 2 — WEB SEARCH BẮT BUỘC

```
web_search("flutter [animation_keyword] package pub.dev 2024")
web_search("flutter [animation_keyword] implementation example")
web_search("pub.dev [package_name] flutter animation latest version")
web_search("flutter animation [use_case] performance best practice")
```

PHẢI output rõ:
> "Sau khi search, tôi tìm thấy [package X vY.Z] phù hợp vì [lý do]. Pattern từ [nguồn]."

Nếu không search thật → output không đạt tiêu chuẩn.

### BƯỚC 3 — CHỌN CÔNG CỤ

Ưu tiên theo thứ tự:
1. **`flutter_animate`** — 80% case, chain syntax clean
2. **`animations` (Google)** — page transition, container morph
3. **`rive`** — illustration / icon / loader phức tạp
4. **`lottie`** — After Effects animation
5. **`shimmer`** — skeleton loading
6. **`confetti`** — celebration particle
7. **`AnimationController` + custom** — khi thư viện không đủ
8. **`CustomPainter` + `Canvas`** — wave, path, morph tay

### BƯỚC 4 — IMPLEMENT PIXEL-SAFE

Checklist bắt buộc khi code:

**Animation không phá layout:**
- [ ] Widget có kích thước xác định trước animate
- [ ] `SlideTransition` bọc trong `ClipRect`
- [ ] `Hero` tag unique
- [ ] `RepaintBoundary` cho animation nặng
- [ ] `dispose()` mọi `AnimationController`
- [ ] Không animate trong `initState` chưa xong build

**Không lỗi UI:**
- [ ] SafeArea không bị che
- [ ] Scroll vẫn hoạt động sau animate
- [ ] Keyboard không làm layout nhảy
- [ ] Không overflow
- [ ] Spacing / padding đúng hệ thống
- [ ] Border radius nhất quán

**Performance:**
- [ ] `AnimatedBuilder` để giới hạn rebuild scope
- [ ] `child` param cho widget tĩnh trong `AnimatedBuilder`
- [ ] Không heavy computation trong `build()`

### BƯỚC 5 — SELF-REVIEW

- [ ] Animation đạt đúng cảm giác người dùng mô tả?
- [ ] Mượt 60fps, không jank?
- [ ] Không phá UI (layout, spacing, overflow)?
- [ ] Curve đủ đẹp (không dùng Curves.linear thô)?
- [ ] Duration hợp lý (entrance 300–600ms, transition 250–400ms)?
- [ ] Không quá nhiều animation concurrent (max 2–3)?

---

## Curve & Duration Cheat Sheet

```dart
// Entrance — dùng nhiều nhất
Curves.easeOutCubic       // ✅ chuẩn nhất
Curves.easeOutQuart       // êm hơn
Curves.fastOutSlowIn      // Material standard

// Spring
Curves.elasticOut         // nảy nhẹ

// Transition page/modal
Curves.easeInOutCubic

// Loop ambient
Curves.easeInOut

// Duration
200.ms   // button press
300.ms   // icon / chip
400.ms   // card reveal
500.ms   // section entrance
350.ms   // page push
600.ms   // full screen / dramatic
3.seconds // ambient background
```

---

## Ví Dụ Dịch Prompt

**"khi vào màn home, các card hiện ra như 3D"**
→ staggered entrance + slideY + fadeIn + subtle scale (depth feel)
→ Tool: `flutter_animate`, delay 80ms stagger
→ Curve: `easeOutCubic`, duration: 500ms

**"nút submit biến thành loading rồi thành tick xanh"**
→ morph button: width collapse → circle → spinner → checkmark draw
→ Tool: `AnimatedContainer` + `CustomPainter` cho checkmark path

---

## Tuyệt Đối Không Làm

- ❌ Code ngay mà không search
- ❌ Search giả, không dùng insight thật
- ❌ `Curves.linear` cho animation visible
- ❌ `setState` trong animation loop
- ❌ `AnimationController` không `dispose()`
- ❌ `SlideTransition` không có `ClipRect`
- ❌ Nhiều hơn 3 animation concurrent không có lý do
- ❌ Duration quá dài (> 800ms) cho micro interaction
- ❌ Animation làm layout jump hoặc overflow

---

## Output Format Chuẩn

```
## 🔍 Animation Research
[Search thật — thư viện, version, pattern]

## 🎯 Keyword Translation
[Mô tả người dùng → keyword kỹ thuật]

## 📦 Packages
[Tên + version + pubspec.yaml snippet]

## 💻 Implementation
[Code Flutter hoàn chỉnh]

## ⚡ Performance Notes
[Tối ưu gì, lưu ý gì]

## ✅ Pixel & Animation Review
[Checklist pass/fail]
```

---

## Tiêu Chí Thành Công

1. ✅ Đã web search thật, có insight thật
2. ✅ Animation đúng cảm giác người dùng mô tả
3. ✅ Không lỗi UI / pixel / layout / overflow
4. ✅ Performance đúng (dispose, AnimatedBuilder, RepaintBoundary)
5. ✅ Curve + duration đẹp, không thô
6. ✅ Integrate được ngay vào project thật

Xử lý yêu cầu animation theo tiêu chuẩn cao nhất.