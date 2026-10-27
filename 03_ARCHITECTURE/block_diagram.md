# E06 · Sơ đồ khối bên trong (Block Diagram)

> Vẽ theo **đúng `04_IMPLEMENTATION/rtl/e06_detector.sv`**, đối chiếu **từng cổng** với
> `06_GDSII/synthesis/netlist.v`. E06 chỉ có **18 cell**, nên đây là đề duy nhất trong ba
> đề E04/E05/E06 mà ta có thể **khai triển toàn bộ netlist** trong một tài liệu.

---

## 1. Sơ đồ khối bên trong — mức RTL

```
   bit_in ──────────────────────────────────────────────┬───────────┐
                                                        │           │
   bit_valid ─────────┬────────────────────────────┐    │           │
                      │                            │    │           │
        ┌─────────────▼────────────┐               │    │           │
        │  CỬA SỔ TRƯỢT 4 bit      │               │    │           │
        │                          │               │    │           │
        │  ┌────┐ ┌────┐ ┌────┐ ┌────┐             │    │           │
   ┌───▶│  │ h3 │◀│ h2 │◀│ h1 │◀│ h0 │◀────────────┼────┘           │
   │    │  └─┬──┘ └─┬──┘ └─┬──┘ └─┬──┘   bit_in    │                │
   │    │    │      │      │      │                │                │
   │    └────┼──────┼──────┼──────┼────────────────┘                │
   │         │      │      │      │                                 │
   │  ✗ history[4] ĐÃ BỊ LOẠI BỎ (tín hiệu chết — W-1)             │
   │         │      │      │      │                                 │
   │         ▼      ▼      ▼      ▼                                 ▼
   │    ╔═════════════════════════════════════════════════════════════╗
   │    ║        SO SÁNH VỚI MẪU  '1 0 1 1 0'                         ║
   │    ║        h3=1 · h2=0 · h1=1 · h0=1 · bit_in=0                 ║
   │    ║                                                             ║
   │    ║   nand2b_1 _14_ : ~(~h2 & bit_valid)          ← bit '0'     ║
   │    ║   nand4b_1 _15_ : ~(~bit_in & h0 & h1 & h3)   ← 4 bit khác  ║
   │    ║   nor3_1   _16_ : ~(~rst_n | _14_ | _15_)  = hit            ║
   │    ╚════════════════════════════╤════════════════════════════════╝
   │                                 │ hit
   │         ┌───────────────────────┼──────────────────┐
   │         │ (khi !overlap_en:     │                  ▼
   │         │  ép h1, h2 về 0)      │           ┌─────────────┐
   └─────────┘◀── overlap_en ────────┘           │ match FF _26_│──▶ match
                                                 └─────────────┘
```

## 2. Khai triển **toàn bộ** netlist — 18 cell

Vì E06 chỉ có 18 cell, ta khai triển đầy đủ. Đây là tài liệu tham chiếu để đối chiếu mọi
khẳng định trong hồ sơ.

### 2.1 Nhóm RESET (1 cell)

| Cell | Hàm | Ghi chú |
|---|---|---|
| `clkinv_1 _13_` | `_05_ = ¬rst_n` | Được chèn vào **5 cổng khác** để gộp reset đồng bộ |

### 2.2 Nhóm SO SÁNH MẪU (3 cell) — "phần thông minh"

| Cell | Kết nối | Hàm |
|---|---|---|
| `nand2b_1 _14_` | `.A_N(history[2])`, `.B(bit_valid)` | `_06_ = ¬(¬h2 ∧ bit_valid)` |
| `nand4b_1 _15_` | `.A_N(bit_in)`, `.B(h0)`, `.C(h1)`, `.D(h3)` | `_07_ = ¬(¬bit_in ∧ h0 ∧ h1 ∧ h3)` |
| `nor3_1 _16_` | `.A(_05_)`, `.B(_06_)`, `.C(_07_)` | `_00_ = rst_n ∧ bit_valid ∧ ¬h2 ∧ ¬bit_in ∧ h0 ∧ h1 ∧ h3` |

**Kiểm chứng:** `_00_ = hit` phải đúng khi `{h3,h2,h1,h0,bit_in} = 10110`:
`h3=1 ✓ · h2=0 ✓(¬h2) · h1=1 ✓ · h0=1 ✓ · bit_in=0 ✓(¬bit_in)` — **khớp chính xác**. ✅

> **Chi tiết đáng dạy:** Yosys dùng các ô có **đầu vào đảo sẵn** (`_N`) — `nand2b` cho `¬h2`
> và `nand4b` cho `¬bit_in`. Nhờ vậy, so sánh 5 bit với hằng số `10110` chỉ tốn **3 cell**,
> **không** cần một cổng đảo riêng nào. Đếm cổng từ cú pháp RTL (`==` 5 bit → "5 XNOR +
> 1 AND5" = 6 cổng) sẽ cho ước lượng **sai gấp đôi**.

### 2.3 Nhóm CỬA SỔ TRƯỢT (9 cell + 4 FF)

**`history[0]` — chỉ 2 cell (rẻ nhất):**
```verilog
mux2i_1 _17_ (.A0(\history[0] ), .A1(bit_in), .S(bit_valid), .Y(_08_));  // _08_ = ¬(bit_valid ? bit_in : h0)
nor2_1  _18_ (.A(_05_), .B(_08_),                            .Y(_01_));  // _01_ = rst_n ∧ (bit_valid ? bit_in : h0)
```
⚠️ **Không có nhánh xoá!** Lý do: khi `hit` đúng thì `bit_in = 0` (bit cuối của mẫu là `0`),
nên giá trị dịch vào `history[0]` **đã** bằng 0. Yosys tự phát hiện điều này.

**`history[1]` — 3 cell (có nhánh xoá):**
```verilog
o31ai_1 _19_ (.A1(overlap_en), .A2(_06_), .A3(_07_), .B1(\history[0] ), .Y(_09_));
o21ai_0 _20_ (.A1(bit_valid),  .A2(\history[1] ),    .B1(rst_n),        .Y(_10_));
a21oi_1 _21_ (.A1(bit_valid),  .A2(_09_),            .B1(_10_),         .Y(_02_));
```
`_09_ = ¬((overlap_en ∨ ¬hit_core) ∧ h0)` ⟹ giá trị dịch vào là `h0` **trừ khi**
`(¬overlap_en ∧ hit)` thì bị ép `0`. ✅ Đây là **nơi duy nhất** (cùng với `_22_`) mà chế độ
không-chồng-lấn tốn cell.

**`history[2]` — 3 cell (đối xứng với `history[1]`):**
```verilog
o31ai_1 _22_ (.A1(overlap_en), .A2(_06_), .A3(_07_), .B1(\history[1] ), .Y(_11_));
o21ai_0 _23_ (.A1(bit_valid),  .A2(\history[2] ),    .B1(rst_n),        .Y(_12_));
a21oi_1 _24_ (.A1(bit_valid),  .A2(_11_),            .B1(_12_),         .Y(_03_));
```

**`history[3]` — chỉ 1 cell (rẻ nhất):**
```verilog
o211a_1 _25_ (.A1(\history[3] ), .A2(bit_valid), .B1(rst_n), .C1(_06_), .X(_04_));
```
⚠️ **Không có nhánh `overlap_en`!** Lý do: `history[3]` nhận `history[2]`, và khi `hit`
đúng thì `h2 = 0` (bit thứ hai của mẫu `10110` là `0`) ⟹ giá trị dịch vào **đã** bằng 0.

### 2.4 Nhóm FLIP-FLOP (5 cell)

| Cell | `Q` | `D` |
|---|---|---|
| `dfxtp_1 _26_` | `match` | `_00_` (= `hit`) |
| `dfxtp_1 _27_` | `history[0]` | `_01_` |
| `dfxtp_1 _28_` | `history[1]` | `_02_` ← **đích đường tới hạn** |
| `dfxtp_1 _29_` | `history[2]` | `_03_` |
| `dfxtp_1 _30_` | `history[3]` | `_04_` |

**Tổng: 1 + 3 + 9 + 5 = 18 cell** ✅ khớp `synth_stat.txt`.

### 2.5 `history[4]` — tín hiệu **không tồn tại** trong netlist

```verilog
// Toàn bộ khai báo history trong netlist.v:
  wire \history[0] ;
  wire \history[1] ;
  wire \history[2] ;
  wire \history[3] ;
// KHÔNG CÓ \history[4]
```

RTL khai báo `logic [4:0] history` (5 bit) và gán `history <= next_window` (5 bit), nhưng
`history[4]` **chỉ được ghi, không bao giờ được đọc**: biểu thức duy nhất dùng `history` là
`next_window = {history[3:0], bit_in}` — chỉ lấy `[3:0]`.

⟹ Yosys chạy phân tích **dead-code elimination** và loại bỏ hoàn toàn cả flip-flop lẫn
logic next-state của nó. Đây là hành vi **đúng đắn**, không phải lỗi.

| | Charter mục 10 | RTL khai báo | **Netlist** |
|---|---:|---:|---:|
| Ô nhớ dịch | 5 | 5 | **4** |
| Chốt đầu ra | 1 | 1 | 1 |
| Tổng | **6** | 6 | **5** |

> **Nguyên nhân gốc là W-1**: Charter mục 4 yêu cầu `uo_out[5:1]` = "nội dung thanh ghi";
> nếu RTL có cổng ra đó, `history[4]` sẽ **được đọc** và không bị loại ⟹ **6 FF** đúng như
> Charter dự đoán. Xem `functional_spec.md` §0.1.

## 3. Bảng ánh xạ cấu trúc RTL → phần cứng

| Cấu trúc RTL (dòng) | Ý nghĩa | Phần cứng | Cell |
|---|---|---|---:|
| `logic [4:0] history` (9) | cửa sổ trượt | `dfxtp_1` `_27_`…`_30_` — **chỉ 4, không phải 5** | 4 |
| `next_window = {history[3:0], bit_in}` (14) | dịch trái, nạp bit mới | `mux2i_1 _17_` + logic từng bit | (trong 9) |
| `next_window == 5'b10110` (15) | so sánh mẫu | `nand2b_1 _14_` + `nand4b_1 _15_` | 2 |
| `hit = bit_valid && (...)` (15) | gộp điều kiện hợp lệ | gộp vào `_14_` (`.B(bit_valid)`) và `nor3_1 _16_` | 1 |
| `if (hit && !overlap_en) history <= 0` (25–26) | xoá cửa sổ | `o31ai_1 _19_`, `_22_` — **chỉ 2 bit cần**, xem §2.3 | 2 |
| `else history <= next_window` (27–28) | dịch bình thường | `o21ai_0 _20_/_23_` + `a21oi_1 _21_/_24_` + `o211a_1 _25_` + `nor2_1 _18_` | 6 |
| `match <= hit` (29) + `match <= 1'b0` (23) | chốt đầu ra 1 chu kỳ | `dfxtp_1 _26_` | 1 |
| `if (!rst_n)` (19) | **reset đồng bộ** | `clkinv_1 _13_` + gộp vào 5 cổng khác | 1 |
| `output logic match` (7) | cổng ra | `Q` của `_26_`, **không cần buffer** | 0 |
| | | **Tổng** | **18** ✅ |

## 4. Khối con nào nằm trên đường tới hạn?

```
Startpoint: bit_in (input port clocked by clk)
Endpoint:   _28_  ← chính là history[1]

  bit_in ──▶ _15_ (nand4b_1)  fanout 3, slew 0.12, delay 0.18 ──▶ 1.18 ns
         ──▶ _19_ (o31ai_1)              slew 0.18, delay 0.20 ──▶ 1.38 ns
         ──▶ _21_ (a21oi_1)              slew 0.05, delay 0.08 ──▶ 1.47 ns
         ──▶ _28_/D (dfxtp_1)                                     1.47 ns
                                              slack = 8.41 ns (MET)
```

| Khối con | Trên đường tới hạn? | Ghi chú |
|---|:-:|---|
| **So sánh mẫu** (`nand4b_1 _15_`) | ✅ **CÓ** — cell chậm nhất (0,18 / 0,47 = **38 %** phần logic) | ⚠️ **Khác E04/E05!** |
| **Logic xoá không-chồng-lấn** (`o31ai_1 _19_`) | ✅ **CÓ** | 0,20 ns |
| **Mạch dịch** (`a21oi_1 _21_`) | ✅ **CÓ** | 0,08 ns |
| `history[1]` FF (`_28_`) | ✅ đích | |
| Chốt `match` (`_26_`) | ❌ Không — arrival 1,31 ns, slack **8,62 ns** | nhanh hơn |
| `history[0]` (`_27_`), `history[3]` (`_30_`) | ❌ Không — arrival 1,19 ns, slack **8,70 ns** | chỉ 2 và 1 cell |

### 4.1 E06 khác E04/E05 ở điểm nào — và vì sao

Đây là điểm so sánh đắt giá nhất giữa ba đề:

| Đề | Startpoint | **Loại tín hiệu** | Fanout | Cell chậm nhất |
|---|---|---|---:|---|
| E04 | `start` | **điều khiển** | 3 → `_45_` fanout **11** | `nor2_1` (0,39 ns, tải nặng) |
| E05 | `data_valid` | **điều khiển** | **12** → `_077_` fanout 8 | `nor2_1` (0,29 ns, tải nặng) |
| **E06** | **`bit_in`** | **DỮ LIỆU** | **2** | **`nand4b_1`** (0,18 ns, **4 đầu vào**) |

**Vì sao E06 khác?** Hai lý do:

1. **Mạch quá nhỏ.** 18 cell, cửa sổ chỉ 4 bit ⟹ **không có tín hiệu điều khiển nào có
   fanout rộng**. `bit_valid` chỉ lái 5 cổng; `overlap_en` chỉ lái 2. Trong E05, `data_valid`
   lái **12** vì datapath rộng 8 bit.
2. **Cổng so sánh có 4 đầu vào.** `nand4b_1` chậm hơn cổng 2 đầu vào vì nhiều transistor nối
   tiếp — 0,18 ns dù fanout chỉ 3.

> **Quy luật rút ra:** nút thắt của mạch tuần tự nhỏ là **fanout của tín hiệu điều khiển**,
> **trừ khi** datapath quá hẹp — khi đó nó chuyển sang **độ phức tạp của cổng logic**. E06
> nằm ở ngưỡng chuyển đổi đó.

### 4.2 Toàn bộ 6 đường trong báo cáo STA

E06 nhỏ tới mức `timing_report_max.txt` chỉ có **6 đường** (E04 và E05 mỗi đề có 10).

| # | Startpoint | Endpoint | Arrival (ns) | Slack (ns) |
|---:|---|---|---:|---:|
| 1 | `bit_in` | `_28_` = `history[1]` | **1,47** | **8,41** ← xấu nhất |
| 2 | `bit_in` | `_29_` = `history[2]` | 1,47 | 8,41 |
| 3 | `bit_in` | `_26_` = `match` | 1,31 | 8,62 |
| 4 | `bit_valid` | `_27_` = `history[0]` | 1,19 | 8,70 |
| 5 | `bit_valid` | `_30_` = `history[3]` | 1,19 | 8,70 |
| 6 | `_26_` = `match` | `match` (cổng ra) | 0,26 | 8,74 |

**Quan sát:** 5/6 đường là **in→reg**, 1/6 là **reg→out**. **Không có đường reg→reg nào**
trong báo cáo max. Lý do: mọi flip-flop đều có next-state phụ thuộc `bit_in` hoặc
`bit_valid` (cổng vào), và với `set_input_delay 1.0` thì đường từ cổng vào **luôn** xấu hơn
đường từ flip-flop. OpenSTA báo đường **xấu nhất cho mỗi endpoint**, nên các đường reg→reg
bị che khuất.

⚠️ **Hệ quả:** `arrival = 1,47 ns` gồm **1,00 ns là giả định IO = 68 %**. Phần logic thật
chỉ **0,47 ns = 4,7 % chu kỳ 10 ns**. Muốn biết logic nội bộ nhanh chậm thật, phải chạy lại
với `set_input_delay 0`.

### 4.3 Đường min (hold)

```
Startpoint: _28_ (history[1]) → _22_ (o31ai_1) → _24_ (a21oi_1) → _29_ (history[2])
arrival 0.40 ns · required −0.06 ns · hold slack = 0.46 ns (MET)
```

Đây là **một mắt của chuỗi dịch** — đường ngắn nhất trong thiết kế (2 cổng), nhạy nhất với
skew sau CTS. Biên 0,46 ns đo với **clock lý tưởng** (`clock network delay (ideal)`).

## 5. Phân bố cell theo chức năng

| Nhóm chức năng | Cell | % trong 18 |
|---|---:|---:|
| Ô nhớ (`dfxtp_1` × 5) | **5** | 27,8 % |
| Cửa sổ trượt (logic next-state) | **9** | 50,0 % |
| **So sánh mẫu `10110`** | **3** | **16,7 %** |
| Reset (`clkinv_1`) | 1 | 5,6 % |
| Cổng ra `match` | **0** | 0 % |

Trong 9 cell của cửa sổ trượt, chỉ **2** (`o31ai_1 _19_`, `_22_`) là chuyên cho chế độ
**không chồng lấn** — và chúng **thay thế** cổng vốn cần cho mạch dịch, nên chi phí gia tăng
của tính năng này gần **bằng 0**.

> **Ba con số cần nhớ:**
> **16,7 %** — tỷ lệ cell dành cho việc nhận ra mẫu (3/18).
> **≈ 0 cell** — chi phí gia tăng của chế độ chồng lấn/không chồng lấn.
> **92,5 %** — tỷ lệ công suất thuộc nhóm Sequential, dù FF chỉ chiếm 27,8 % số cell.

E06 là **thiết kế nhỏ nhất** trong ba đề: 18 cell so với 55 (E04) và 64 (E05); 182,6752 µm²
so với 519,248 và 646,8704 µm². Công suất cũng thấp nhất: 2,35e-05 W.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
