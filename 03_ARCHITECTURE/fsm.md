# E06 · Máy trạng thái (FSM)

---

## 1. Kết luận: E06 **KHÔNG có FSM điều khiển**, nhưng **CÓ** một otomat nhận dạng ẩn

E06 là đề mà câu hỏi "có FSM không" đáng được trả lời kỹ nhất, vì **toàn bộ đề tài** là về
sự khác biệt giữa hai cách hiện thực **cùng một otomat**: bằng **thanh ghi dịch** (E06) hay
bằng **FSM mã hoá tay** (đề F04).

| Khái niệm | E06 có? | Bằng chứng |
|---|:-:|---|
| **FSM điều khiển** (trạng thái quyết định *thao tác nào*) | ❌ **KHÔNG** | Bảng thao tác (`control.md` §2.3) không có cột "trạng thái điều khiển"; netlist: cả 3 tín hiệu điều khiển đi thẳng từ cổng vào |
| **Otomat nhận dạng** (trạng thái = tiến độ khớp mẫu) | ✅ **CÓ** — nhưng **mã hoá bằng dữ liệu** | `history[3:0]` — 16 trạng thái, chính là 4 bit gần nhất |
| **Ô nhớ tuần tự** | ✅ CÓ — 5 FF | `synth_stat.txt`; công suất Sequential **92,5 %** |

### 1.1 Bằng chứng E06 **không có** FSM điều khiển

**Bằng chứng 1 — không có biến trạng thái nào trong RTL.**
`e06_detector.sv` khai báo đúng ba tín hiệu nội bộ: `history` (dữ liệu), `next_window`
(tổ hợp), `hit` (tổ hợp). **Không có `state`, không có `enum`, không có `case`.**

**Bằng chứng 2 — tín hiệu điều khiển không qua flip-flop.**
```verilog
sky130_fd_sc_hd__nand2b_1 _14_ (.A_N(\history[2] ), .B(bit_valid), .Y(_06_));
sky130_fd_sc_hd__o31ai_1  _19_ (.A1(overlap_en), .A2(_06_), .A3(_07_), .B1(\history[0] ), .Y(_09_));
```
`bit_valid` và `overlap_en` — hai tín hiệu quyết định thao tác — đi **thẳng từ cổng vào**.
Trong E04, tín hiệu tương ứng (`_17_`, `_20_`, `_16_`) đều chứa `busy` hoặc `count`, tức
đầu ra flip-flop.

**Bằng chứng 3 — `match` không quay lại.**
Trong netlist, `match` xuất hiện đúng hai lần: `output match;` và `.Q(match)` của `_26_`.
**Không instance nào dùng nó làm đầu vào** ⟹ nó là **đầu ra**, không phải biến trạng thái.

### 1.2 Nhưng E06 **hiện thực** một otomat hữu hạn

Otomat nhận dạng mẫu `10110` (Knuth–Morris–Pratt / Aho–Corasick tối thiểu) có **6 trạng
thái**: `S0` (chưa khớp gì) … `S5` (khớp đủ). E06 hiện thực otomat đó **bằng cách nhớ
nguyên văn 4 bit gần nhất** thay vì mã hoá tiến độ khớp.

| | **FSM mã hoá tay** (F04) | **Thanh ghi dịch** (E06) |
|---|---|---|
| Trạng thái biểu diễn gì | **Tiến độ khớp** (đã khớp bao nhiêu bit của mẫu) | **Nội dung** 4 bit gần nhất |
| Số trạng thái tối thiểu | **6** (mẫu 5 bit) | **16** (`2⁴`) |
| Số bit trạng thái | 3 (nhị phân) hoặc 6 (one-hot) | **4** |
| Logic next-state | bảng chuyển phức tạp, phải tính tay | **dịch — tầm thường** |
| Logic đầu ra | so sánh trạng thái với `S5` | **so sánh 5 bit với hằng** |
| Trạng thái bất hợp lệ | **có** (nếu 3 bit: 8 − 6 = 2) | **KHÔNG CÓ** — cả 16 đều hợp lệ |
| Đổi mẫu | phải tính lại **toàn bộ** bảng chuyển | chỉ đổi **hằng so sánh** |
| Mở rộng mẫu `N` bit | số trạng thái ≈ `N+1`, bảng chuyển phình | `N−1` FF, tuyến tính |

> **Đây là đánh đổi trung tâm của đề E06** (Charter mục 2 câu 1 và mục 9): thanh ghi dịch
> dùng **nhiều trạng thái hơn** (16 so với 6) nhưng **logic đơn giản hơn nhiều**. Xem
> `tradeoff.md` §1 cho số liệu thật so với F04.

## 2. Otomat nhận dạng — sơ đồ trạng thái

### 2.1 Sơ đồ mức **tiến độ khớp** (cách FSM nhìn bài toán)

Đây là otomat tối thiểu cho `10110`, gồm 6 trạng thái. E06 **không** hiện thực nó trực
tiếp, nhưng nó là **ngữ nghĩa** mà E06 phải tuân theo:

```
        b=0                b=0            b=1
     ┌──────┐           ┌──────┐       ┌──────┐
     ▼      │           ▼      │       ▼      │
  ╔══════╗ b=1  ╔══════╗ b=0 ╔══════╗ b=1 ╔══════╗ b=1 ╔══════╗ b=0 ╔══════╗
  ║  S0  ║─────▶║  S1  ║────▶║  S2  ║────▶║  S3  ║────▶║  S4  ║────▶║  S5  ║
  ║ ---- ║      ║  1   ║     ║  10  ║     ║ 101  ║     ║ 1011 ║     ║10110 ║
  ╚══════╝      ╚══════╝     ╚══════╝     ╚══════╝     ╚══════╝     ╚══╤═══╝
     ▲             ▲            │            ▲            │  b=0       │
     │             │            │ b=1        │            └──────┐     │ MATCH = 1
     │             └────────────┘            │  b=1              ▼     │
     │                                       └────────────────────┐    │
     └───────────────────────────────────────────────────────────┐│    │
                                                                 ││    │
   overlap_en=1 → về S3 (dùng lại '10' của '10110')  ◀───────────┘│    │
   overlap_en=0 → về S0 (xoá sạch)                   ◀────────────┘◀───┘
```

**Cung lùi (back edges)** là phần khó nhất khi viết FSM tay: từ `S4` (`1011`) nếu nhận `b=1`
thì không về `S0` mà về `S3` (`101` — vì `1011`+`1` = `10111`, hậu tố `1` khớp tiền tố mẫu…
thực ra phải tính KMP cẩn thận). **Đây chính là chỗ sinh viên viết FSM hay sai**, và là chỗ
thanh ghi dịch **không thể sai** — vì nó không cần tính cung lùi nào cả.

### 2.2 Sơ đồ mức **thanh ghi dịch** (cách E06 thực sự làm)

```
   ╔════════════════════════════════════════════════════════════════╗
   ║   16 TRẠNG THÁI = mọi giá trị của history[3:0] (0000 … 1111)   ║
   ║   Mỗi trạng thái có ĐÚNG 2 cung ra (bit_in = 0 hoặc 1)         ║
   ╚════════════════════════════════════════════════════════════════╝

   Hàm chuyển: history_next = { history[2:0], bit_in }     ← DỊCH TRÁI
                                                             (tầm thường!)

   Đầu ra:     match = ( {history[3:0], bit_in} == 5'b10110 )
                     = ( history == 4'b1011  AND  bit_in == 0 )

   Trạng thái ĐẶC BIỆT duy nhất:  history = 1011  ("sắp khớp")
        ┌──────────┐  bit_in=0   ┌──────────┐
        │   1011   │────────────▶│   0110   │  + MATCH=1   (overlap_en=1)
        │          │             └──────────┘
        │          │  bit_in=0   ┌──────────┐
        │          │────────────▶│   0000   │  + MATCH=1   (overlap_en=0)
        │          │             └──────────┘
        │          │  bit_in=1   ┌──────────┐
        │          │────────────▶│   0111   │  (không khớp)
        └──────────┘             └──────────┘
```

> **Toàn bộ "độ thông minh" của otomat nằm trong MỘT phép so sánh**, không nằm trong bảng
> chuyển. Bảng chuyển chỉ là phép dịch — cùng một phép cho mọi mẫu. Đây là lý do cách làm
> bằng thanh ghi dịch **mạnh về kỹ thuật**: nó chuyển độ phức tạp từ **bảng chuyển** (khó,
> dễ sai) sang **hàm so sánh** (dễ, không thể sai).

## 3. Bảng chuyển trạng thái đầy đủ (16 trạng thái × 2 cung)

Chế độ **chồng lấn** (`overlap_en = 1`), `bit_valid = 1`, `rst_n = 1`:

| `history` | `bit_in=0` → | `match`? | `bit_in=1` → | `match`? |
|---|---|:-:|---|:-:|
| `0000` | `0000` | | `0001` | |
| `0001` | `0010` | | `0011` | |
| `0010` | `0100` | | `0101` | |
| `0011` | `0110` | | `0111` | |
| `0100` | `1000` | | `1001` | |
| `0101` | `1010` | | **`1011`** | |
| `0110` | `1100` | | **`1101`** | |
| `0111` | `1110` | | `1111` | |
| `1000` | `0000` | | `0001` | |
| `1001` | `0010` | | `0011` | |
| `1010` | `0100` | | `0101` | |
| **`1011`** | **`0110`** | ✅ **MATCH** | `0111` | |
| `1100` | `1000` | | `1001` | |
| **`1101`** | `1010` | | **`1011`** | |
| `1110` | `1100` | | `1101` | |
| `1111` | `1110` | | `1111` | |

Chế độ **không chồng lấn** (`overlap_en = 0`): **một ô duy nhất đổi** —
`1011` + `bit_in=0` → **`0000`** thay vì `0110`, vẫn `match = 1`.

> **32 cung, chỉ 1 cung khác nhau giữa hai chế độ.** Đó là lý do chi phí phần cứng của
> `overlap_en` chỉ là **2 cổng `o31ai_1`** (`control.md` §2.4).

### 3.1 Vì sao chỉ **một** trạng thái sinh `match`

`match` cần `{history, bit_in} = 10110` ⟹ `history = 1011` **và** `bit_in = 0`. Chỉ **một**
trong 16 trạng thái, với **một** trong hai giá trị `bit_in` ⟹ **1/32 cung**.

Đối chiếu netlist: cổng `nand4b_1 _15_` có đúng 4 đầu vào (`¬bit_in`, `h0`, `h1`, `h3`) và
`nand2b_1 _14_` thêm `¬h2` — gộp lại xác định **đúng một điểm** trong không gian 32 tổ hợp. ✅

## 4. Mealy hay Moore

**E06 là FSM kiểu MOORE.**

| Bằng chứng | Chi tiết |
|---|---|
| `match` là đầu ra **trực tiếp** của flip-flop `_26_` | `dfxtp_1 _26_ (.CLK(clk), .D(_00_), .Q(match))` — không có cổng nào giữa `Q` và cổng ra |
| `match` **không** phụ thuộc `bit_in` tại cùng thời điểm | `bit_in` ảnh hưởng `_00_` = `D`, nhưng `D` chỉ có hiệu lực ở **sườn kế tiếp** |
| Đường reg→out chỉ **0,26 ns** (`timing_report_max.txt` đường #6) | không có logic tổ hợp nào ở đầu ra |

**Hệ quả thực tế:**

| Tính chất | Hệ quả |
|---|---|
| ✅ `match` **không glitch** theo `bit_in` | Quan trọng vì `match` là chân đi **ra khỏi chip** |
| ✅ Đường reg→out cực ngắn (0,26 ns) | Dễ đáp ứng `set_output_delay` |
| ⚠️ `match` **trễ 1 chu kỳ** so với bit gây ra nó | Tầng ngoài phải trừ đi 1 khi tính vị trí ranh giới khung |

> **Đề F04 so sánh trực tiếp Mealy và Moore** trên cùng bài toán phát hiện chuỗi. E06 chọn
> **Moore**, và đó là lựa chọn đúng cho một khối có đầu ra đi ra ngoài chip: đổi **1 chu kỳ
> trễ** lấy **đầu ra sạch, không glitch**.

## 5. Mã hoá trạng thái

| Đặc điểm | E06 |
|---|---|
| Kiểu mã hoá | **Mã hoá bằng dữ liệu** (data-encoded) — trạng thái *chính là* 4 bit gần nhất |
| Số bit trạng thái | **4** (`history[3:0]`) + 1 (`match`, đầu ra) |
| Trạng thái đạt tới được | **16/16** |
| Trạng thái bất hợp lệ | **0** |
| Trạng thái sinh `match` | **1** (`1011` với `bit_in = 0`) |

So sánh ba cách mã hoá cùng otomat `10110`:

| Mã hoá | Số FF | Logic next-state | Logic đầu ra | Trạng thái bất hợp lệ |
|---|---:|---|---|---:|
| **Thanh ghi dịch (E06)** | **4** | **dịch — 9 cell đo được** | so sánh 5 bit — **3 cell** | **0** |
| FSM nhị phân 6 trạng thái | **3** | bảng chuyển 6×2, phải tính KMP | 1 cổng so sánh | **2** |
| FSM one-hot 6 trạng thái | **6** | rất đơn giản | 1 dây | nhiều |

> **Thanh ghi dịch tốn nhiều FF hơn FSM nhị phân (4 so với 3)** nhưng **logic next-state
> đơn giản hơn hẳn** — và quan trọng hơn: **không có trạng thái bất hợp lệ**, **không cần
> tính bảng chuyển KMP bằng tay**. Với mẫu dài hơn, ưu thế này lớn dần.

## 6. Xử lý trạng thái bất hợp lệ

| Câu hỏi | Trả lời cho E06 |
|---|---|
| Có trạng thái bất hợp lệ không? | **KHÔNG.** Cả 16 giá trị của `history[3:0]` đều là "4 bit gần nhất của một dòng bit nào đó" ⟹ đều hợp lệ và đạt tới được. |
| Mạch có thể "kẹt" không? | **KHÔNG.** Mỗi trạng thái có 2 cung ra; hàm dịch là **toàn ánh** trên 16 trạng thái. |
| Nếu SEU lật một bit `history`? | Mạch chuyển sang một trạng thái **hợp lệ khác**. Hậu quả: có thể **bỏ sót** hoặc **báo nhầm** một mẫu, nhưng **tự phục hồi hoàn toàn sau 4 bit** (cửa sổ được thay mới hoàn toàn). |
| Cần logic tự phục hồi không? | **KHÔNG** — tính tự phục hồi là **nội tại** của cấu trúc thanh ghi dịch. |

> **Đây là ưu điểm cấu trúc lớn nhất của cách làm bằng thanh ghi dịch**, và là điểm đối lập
> mạnh nhất với E04 (8 trạng thái `count` bất hợp lệ, có thể làm `busy` kẹt 16 chu kỳ) và
> với một FSM mã hoá tay 3 bit (2 trạng thái bất hợp lệ, có thể kẹt vĩnh viễn nếu không có
> nhánh `default`).
>
> **Tự phục hồi sau đúng `N−1` = 4 bit** — con số này chứng minh được, không cần thí nghiệm.

## 7. Lưu ý về bản `_explicit`

`e06_detector_explicit.sv` tách `always_comb` khỏi `always_ff`:
```systemverilog
history_d = history;  match_d = 1'b0;            // mặc định
if (bit_valid) begin
    if ({history[3:0],bit_in} == 5'b10110) begin
        match_d = 1'b1;
        if (overlap_en) history_d = {history[3:0],bit_in};
        else            history_d = 5'b00000;
    end else            history_d = {history[3:0],bit_in};
end
```

| So sánh | `e06_detector` (top) | `e06_detector_explicit` |
|---|---|---|
| Phong cách | một `always_ff` + `always_comb` tính `hit` | tách rõ next-state |
| Hai chế độ chồng lấn | nằm trong một `if` lồng | **nằm cạnh nhau**, dễ đối chiếu |
| Tương đương hành vi | — | ✅ |
| Được tổng hợp trong hồ sơ | ✅ (là top) | ❌ **không** |
| Icarus | cảnh báo `sorry:` dòng 13 | cảnh báo `sorry:` dòng 12 |

⚠️ **Mọi số liệu (18 cell, 5 FF, 182,6752 µm², 1,47 ns) thuộc về `e06_detector`.**

## 8. Ghi chú về trạng thái kiểm chứng

⚠️ **Bảng chuyển §3 và các chứng minh ở §6 KHÔNG được xác nhận bằng mô phỏng** — testbench
không biên dịch được (xem
[`../05_VERIFICATION/known_issues.md`](../05_VERIFICATION/known_issues.md)).

Chúng dựa trên:
1. **Đọc RTL** (`e06_detector.sv`).
2. **Khai triển đại số netlist** (18 cell, khai triển đầy đủ ở `block_diagram.md` §2).
3. **Mô hình Python đã chạy PASS**: `detect("1011011010", True) == [5, 8]` và
   `detect("1011011010", False) == [5]` — xác nhận **ngữ nghĩa** của otomat, dù không xác
   nhận RTL.

Ba nguồn này nhất quán với nhau, nhưng **không thay thế** được một lần chạy mô phỏng RTL.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
