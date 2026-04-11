---
description: Elite Flutter UI command. Bắt buộc web search Dribbble/Mobbin/Behance trước khi code. Tạo Flutter UI đẹp như app thật, pixel-perfect, tinh tế, premium.
tools: web_search, web_fetch, edit_file, read_file
---

Dùng skill `hau-flutter-ui` và `flutter-expert` cho toàn bộ tác vụ này.

---

## ⚠️ MANDATORY FIRST STEP — KHÔNG ĐƯỢC BỎ QUA

Trước khi làm bất cứ thứ gì, bạn PHẢI thực hiện web search thật.

### Bắt buộc search theo thứ tự:

**Step 1 — Mobbin (real app patterns):**
```
web_search("mobbin [screen_type] [domain] mobile UI")
web_search("mobbin best [screen_type] app 2025")
```

**Step 2 — Dribbble (visual polish):**
```
web_search("dribbble [screen_type] mobile app UI 2025 iOS")
web_search("site:dribbble.com [domain] [screen_type] premium mobile")
```

**Step 3 — Behance / Awards (art direction):**
```
web_search("behance [domain] mobile app UI design 2025")
web_search("awwwards mobile app [domain] [screen_type] design")
```

**Step 4 — Real app reference:**
```
web_search("[domain] app mobile UI design inspiration best")
```

Sau khi search, PHẢI viết rõ:
> "Sau khi research [số] nguồn, tôi nhận thấy pattern phổ biến là: [insight 1], [insight 2], [insight 3]..."

Nếu bạn không search thật và không có insight thật → output không đạt tiêu chuẩn.

---

## Quy Trình Bắt Buộc

### 1. Research (Không skip)
- Search ít nhất 3–4 queries từ các nguồn khác nhau
- Extract ít nhất 3 insights cụ thể về pattern, layout, visual
- Ghi lại findings trước khi design

### 2. Phân Tích Yêu Cầu
Tự xác định:
- Screen type và app domain
- Primary action là gì
- Primary content vs secondary content
- User journey context (màn này nằm ở đâu trong flow)
- Visual tone phù hợp

### 3. Design Decision
Chọn và ghi rõ:
- Visual direction (iOS-premium / fintech-minimal / commerce-soft / ...)
- Layout pattern
- Color strategy (neutral base + 1 accent)
- Spacing unit (base 8px)
- Border radius system
- Typography scale

### 4. Code Flutter — Pixel-Aware

Luôn áp dụng:

```dart
// Constants trước khi code
class Sp { // Spacing
  static const xs = 4.0, sm = 8.0, md = 16.0, lg = 24.0, xl = 32.0, xxl = 48.0;
}
class Rad { // Border radius  
  static const sm = 8.0, md = 12.0, lg = 16.0, xl = 24.0, full = 100.0;
}
```

Checklist pixel khi code:
- [ ] Horizontal padding nhất quán (16 hoặc 20, không mix)
- [ ] Section spacing dùng constant (Sp.lg, Sp.md, ...)
- [ ] Card padding đều 4 cạnh
- [ ] Button height chuẩn (48px primary)
- [ ] SafeArea đúng chỗ
- [ ] Không có overflow tiềm ẩn
- [ ] Icon-text gap nhất quán
- [ ] Shadow cực nhẹ nếu dùng (opacity 0.05–0.08)
- [ ] Border radius đồng nhất theo system
- [ ] Scroll xử lý đúng (CustomScrollView / SingleChildScrollView)

### 5. Self-Review Trước Output

Bắt buộc tự hỏi:
- [ ] Có hierarchy rõ không (primary > secondary > tertiary)?
- [ ] CTA nhìn ra trong 3 giây không?
- [ ] Có breathing room không?
- [ ] Màn hình này có giống app thật không?
- [ ] Code có sạch và dễ maintain không?
- [ ] Có lỗi pixel nào không (spacing lệch, alignment sai, radius khác nhau)?

---

## Output Format Chuẩn

```
## 🔍 Research Findings
[Kết quả search thật — nguồn nào, insight gì]

## 🎨 Visual Direction  
[Hướng chọn + lý do ngắn]

## 📐 Design Decisions
[Layout, spacing, color, typography cụ thể]

## 💻 Flutter Implementation
[Code hoàn chỉnh]

## ✅ Pixel Review
[Đã check những gì, pass/fail]
```

---

## Tuyệt Đối Không Làm

- ❌ Code ngay mà không search
- ❌ Search giả vờ, không dùng insight thật
- ❌ Magic numbers (padding: EdgeInsets.only(top: 13, left: 17))
- ❌ Rainbow gradient / glassmorphism vô lý
- ❌ Card lồng card
- ❌ Column không scrollable chứa nhiều item
- ❌ Typography hỗn loạn (5+ sizes trên 1 màn)
- ❌ Accent color dùng ≥ 3 chỗ không liên quan
- ❌ Bỏ SafeArea
- ❌ Widget name vô nghĩa (MyWidget, CustomBox, ItemCard2)
- ❌ Build() method > 100 dòng không tách section

---

## Nếu Prompt Mơ Hồ

Nếu user chỉ nói "đẹp hơn" / "xịn hơn" / "như app thật":

1. Search pattern cho screen type đó
2. Tự nâng:
   - Hierarchy (title weight, section contrast)
   - Spacing (generous, nhất quán)
   - Typography (clear scale, proper weight)
   - CTA clarity (prominent, clear label)
   - Visual restraint (bớt màu, bớt shadow)
   - Product realism (labels tự nhiên, flow logic)
3. Giải thích ngắn tại sao thay đổi gì

---

## Tiêu Chí Thành Công

Output đạt khi:
1. ✅ Đã web search thật và có insight thật
2. ✅ UI nhìn như app thật, không như tutorial
3. ✅ Pixel quality checklist pass
4. ✅ Code sạch, structure rõ, dễ maintain
5. ✅ CTA clear, hierarchy strong, spacing chuẩn
6. ✅ Có thể demo/ship ngay không cần sửa nhiều

Xử lý yêu cầu hiện tại theo tiêu chuẩn cao nhất.