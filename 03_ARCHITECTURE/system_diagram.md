# E06 · Sơ đồ hệ thống (System Diagram)

---

## 1. Bối cảnh ứng dụng — tìm điểm bắt đầu khung dữ liệu

Charter mục 1: *"Khối dò mẫu đồng bộ trong dòng bit đến từ đường truyền, để biết khung dữ
liệu bắt đầu ở đâu."*

Bài toán hệ thống: một đường truyền nối tiếp gửi **dòng bit liên tục, không có ranh giới**.
Bên thu cần biết **byte bắt đầu ở bit nào**. Giải pháp phổ biến: phía phát chèn một
**mẫu đồng bộ** (sync pattern / preamble) cố định trước mỗi khung; phía thu dò mẫu đó.

```
   ┌───── PHÍA PHÁT ─────┐          ┌──────────── PHÍA THU (trong chip) ────────────┐
   │                     │          │                                               │
   │  [10110][dữ liệu]   │  dòng    │  ┌──────────┐ bit_in  ┌──────────────┐       │
   │  [10110][dữ liệu]   │─ bit ───▶│  │ Bộ khôi  │────────▶│              │       │
   │   ▲                 │  liên    │  │ phục xung│bit_valid│   ►► E06 ◄◄  │       │
   │   └ mẫu đồng bộ     │  tục     │  │ nhịp     │────────▶│  Dò '10110'  │       │
   │                     │          │  │ (đề H07) │         │              │ match │
   └─────────────────────┘          │  └──────────┘         │  4 FF cửa sổ │───┬───┼──▶
                                    │                       │  1 FF chốt   │   │   │
                                    │        overlap_en ────▶│              │   │   │
                                    │                       └──────────────┘   │   │
                                    │   ✗ nội dung thanh ghi (KHÔNG CÓ — W-1)  │   │
                                    │                                          ▼   │
                                    │                            ┌──────────────────┐
                                    │                            │ Bộ đếm/FSM khung │
                                    │                            │ · match=1 → đặt  │
                                    │                            │   lại con trỏ bit│
                                    │                            │ · đếm N bit tiếp │
                                    │                            └────────┬─────────┘
                                    │                                     ▼
                                    │                            ┌──────────────────┐
                                    │                            │ Bộ chuyển S→P    │
                                    │                            │ (đề E03)         │
                                    │                            └──────────────────┘
                                    └───────────────────────────────────────────────┘
```

**Điểm cốt lõi:** E06 **không** biết gì về khung. Nó chỉ nói *"vừa rồi có mẫu `10110`"*.
Việc biến thông tin đó thành ranh giới khung là nhiệm vụ của FSM ở tầng ngoài.

### 1.1 Vì sao cần chế độ chồng lấn / không chồng lấn

| Chế độ | Khi nào dùng | Ví dụ |
|---|---|---|
| **Chồng lấn** (`overlap_en=1`) | Dò **mọi** thể hiện của mẫu — dùng khi mẫu có thể xuất hiện dày đặc, hoặc khi cần đếm tần suất | Dò mẫu trong dữ liệu để thống kê |
| **Không chồng lấn** (`overlap_en=0`) | Mỗi mẫu đánh dấu **một khung**; sau khi tìm thấy, các bit tiếp theo là **dữ liệu**, không thể là phần của mẫu khác | Dò preamble khung — **đúng bối cảnh Charter mục 1** |

> Với bài toán "tìm điểm bắt đầu khung", chế độ **không chồng lấn** mới là đúng: sau khi
> khớp preamble, bên thu chuyển sang đọc dữ liệu và **không nên** khớp lần nữa trên các bit
> dữ liệu đó. Charter đưa cả hai vào để sinh viên thấy khác biệt phần cứng — xem
> `functional_spec.md` §4.1.

## 2. Ranh giới khối E06

```
                    ╔═══════════════════════════════════════════════╗
   clk  ───────────▶║                                               ║
   rst_n ──────────▶║            e06_detector                       ║──▶ match
   bit_valid ──────▶║   (TUẦN TỰ · 5 flip-flop · 18 cell)           ║
   bit_in ─────────▶║                                               ║   ✗ window[4:0]
   overlap_en ─────▶║   history[3:0] ◀── KHÔNG CÓ CỔNG RA (W-1)     ║     (Charter mục 4
                    ╚═══════════════════════════════════════════════╝      yêu cầu nhưng
                         5 bit vào                    1 bit ra             RTL thiếu)
                              └──── 6 bit trên ô 24 chân → còn dư 18 ────┘
```

| Thuộc **BÊN TRONG** E06 | Thuộc **TẦNG NGOÀI** |
|---|---|
| Cửa sổ trượt 4 bit (`history[3:0]`) | **Khôi phục xung nhịp** từ dòng bit (đề H07) |
| Mẫu `10110` — **nằm trong hình dạng cổng**, không trong thanh ghi | Sinh `bit_valid` đúng nhịp bit |
| Logic so sánh 5 bit (3 cổng) | Quyết định `overlap_en` |
| Chính sách xoá cửa sổ khi không chồng lấn | **Đếm độ dài khung** sau khi `match` |
| Chốt `match` (Moore, 1 FF) | Ghép bit thành byte (đề E03) |
| Reset **đồng bộ** | Xử lý khi **không** tìm thấy mẫu (timeout) |
| — | **Quan sát nội dung cửa sổ** ❌ không làm được (W-1) |

### 2.1 Nghĩa vụ hợp đồng của tầng ngoài

| # | Nghĩa vụ | Nếu vi phạm |
|---|---|---|
| O-1 | `bit_valid = 1` **đúng một chu kỳ** cho mỗi bit dữ liệu | Bit bị đếm hai lần ⟹ cửa sổ sai hoàn toàn |
| O-2 | Giữ `bit_in` ổn định quanh sườn có `bit_valid = 1` | Metastability |
| O-3 | Hiểu `match` trễ **một sườn** so với bit gây ra nó (Moore) | Tính sai vị trí ranh giới khung |
| O-4 | Giữ `overlap_en` ổn định **quanh sườn có khả năng khớp** | Hành vi lẫn lộn giữa hai chế độ |
| O-5 | Cấp ≥ 1 sườn `clk` khi `rst_n = 0` | Không reset (đồng bộ) |
| O-6 | Muốn xoá cửa sổ giữa hai phiên dò ⟹ **phải xung `rst_n`** | `bit_valid = 0` chỉ **đóng băng**, **không xoá** |

> **O-6 là bẫy dễ mắc nhất.** Đặt `bit_valid = 0` không làm sạch cửa sổ — nó chỉ dừng thời
> gian. Muốn bắt đầu một phiên dò "sạch" thì bắt buộc phải reset. Đây cũng chính là vấn đề
> **M-2** trong `corner_cases.md` §5.1: testbench tưởng các chuỗi được cô lập, thực ra
> chúng bị nối liền.

## 3. Phân rã một tầng xuống dưới

```
 e06_detector                                    18 cell · 5 FF · 182,6752 µm²
 │
 ├── CỬA SỔ TRƯỢT  ── 4 FF + ~8 cell ──
 │   ├── history[0] ← bit_valid ? bit_in : history[0]
 │   │     mux2i_1 _17_  +  nor2_1 _18_          ← 2 cell (KHÔNG cần nhánh xoá!)
 │   ├── history[1] ← o31ai_1 _19_ + o21ai_0 _20_ + a21oi_1 _21_   ← 3 cell (CÓ nhánh xoá)
 │   ├── history[2] ← o31ai_1 _22_ + o21ai_0 _23_ + a21oi_1 _24_   ← 3 cell (CÓ nhánh xoá)
 │   ├── history[3] ← o211a_1 _25_                                 ← 1 cell (KHÔNG cần xoá!)
 │   └── history[4] ← ❌ ĐÃ BỊ LOẠI BỎ (tín hiệu chết — xem functional_spec.md §0.1)
 │
 ├── SO SÁNH MẪU '10110'  ── 3 cell ──
 │   ├── nand2b_1 _14_ : ~(~history[2] & bit_valid)       ← bit '0' thứ 2 của mẫu
 │   ├── nand4b_1 _15_ : ~(~bit_in & history[0]
 │   │                      & history[1] & history[3])     ← 4 bit còn lại
 │   └── nor3_1   _16_ : gộp + rst_n  →  hit
 │
 ├── CHỐT ĐẦU RA  ── 1 FF ──
 │   └── dfxtp_1 _26_ : match ← hit
 │
 └── RESET ĐỒNG BỘ ── 1 cell ──
     └── clkinv_1 _13_ : ~rst_n, chèn vào nor3/nor2/o21ai/o211a
```

> **Đây là bảng phân rã đáng nhớ:** toàn bộ **"trí tuệ"** của khối — nhận ra mẫu `10110` —
> chỉ tốn **3 cell trên 18 = 16,7 %**. Phần còn lại là mạch dịch và chốt. Và đáng chú ý:
> `history[0]` và `history[3]` **không cần** nhánh xoá (2 và 1 cell) trong khi `history[1]`,
> `history[2]` cần (3 cell mỗi bit) — lý do ở `functional_spec.md` §4.1.1.

## 4. Sơ đồ vòng đời (Lifecycle) — RTL đến GDSII

```
 ┌─────────────┐   ┌─────────────┐   ┌──────────────┐   ┌────────────┐
 │ 01 YÊU CẦU  │──▶│ 02 ĐẶC TẢ   │──▶│03 KIẾN TRÚC  │──▶│04 HIỆN THỰC│
 │ Charter E06 │   │ cửa sổ trượt│   │ 4 FF + so    │   │ e06_       │
 │             │   │ + 2 chế độ  │   │ sánh 5 bit   │   │ detector.sv│
 └─────────────┘   └─────────────┘   └──────────────┘   └─────┬──────┘
                                                              │
        ┌─────────────────────────────────────────────────────┘
        ▼
 ┌──────────────┐   🟡 MỘT PHẦN
 │05 KIỂM CHỨNG │      · mô hình Python:  ✅ PASS
 │              │        overlap    '1011011010' → [5, 8]
 │              │        nonoverlap '1011011010' → [5]
 │              │      · mô phỏng RTL:    ❌ COMPILE_FAIL
 │              │        e06_detector_tb.sv:31 — 'getc' không được Icarus hỗ trợ
 │              │        👉 phán xử: 05_VERIFICATION/known_issues.md
 └──────┬───────┘      · golden SV:       ✅ có, nhưng KHÔNG độc lập với DUT
        ▼
 ┌──────────────┐   ✅ ĐÃ CHẠY — Yosys 0.33 + sky130_fd_sc_hd
 │ TỔNG HỢP     │      18 cell · 5 FF · 182,6752 µm²
 │ (06/synth)   │      history[4] bị LOẠI BỎ (tín hiệu chết)
 └──────┬───────┘      ⟹ chứng minh RTL hợp lệ cú pháp, dù Icarus không chạy testbench
        ▼
 ┌──────────────┐   ✅ ĐÃ CHẠY — OpenSTA 3.1.0 (clock THẬT, period 10 ns)
 │ STA          │      bit_in → _28_ (history[1]) · arrival 1,47 ns
 │ (06/sta)     │      slack 8,41 ns · WNS 0,00 · TNS 0,00
 └──────┬───────┘      hold slack nhỏ nhất 0,46 ns (history[1]→history[2])
        ▼
 ┌──────────────┐   ✅ ĐÃ CHẠY — OpenSTA
 │ CÔNG SUẤT    │      2,35e-05 W · tuần tự 92,5 % · tổ hợp 7,5 %
 │ (06/power)   │      ← NHỎ NHẤT trong ba đề E04/E05/E06
 └──────┬───────┘
        ▼
 ┌──────────────┬──────────────┬──────────────┬──────────────┐
 │ FLOORPLAN    │  PLACEMENT   │  CTS  ✅ áp  │  ROUTING     │  ⬜ CHƯA CHẠY
 │              │              │  dụng (có clk)│             │  cần LibreLane
 └──────────────┴──────────────┴──────┬───────┴──────────────┘  + PDK sky130A
                                      ▼
                           ┌──────────────────┐
                           │  DRC · LVS · GDS │                  ⬜ CHƯA CHẠY
                           └────────┬─────────┘
                                    ▼
                           ┌──────────────────┐
                           │ 07 TRUY VẾT +    │   ✅ RTM + evidence_index
                           │ KẾT LUẬN/GIỚI HẠN│      + limitations + known_issues
                           └──────────────────┘

        ─────── NGOÀI PHẠM VI (Charter mục 3) ───────
        mẫu lập trình được · nhiều mẫu cùng lúc · mẫu có ký tự đại diện
        sign-off · tape-out · chế tạo · kiểm tra sau chế tạo
```

### 4.1 Bảng trạng thái từng bước (đọc từ BRIEF)

| Bước | Trạng thái | Bằng chứng |
|---|:-:|---|
| Mô hình chuẩn Python | ✅ **PASS** | `python_reference_run.log` |
| Mô phỏng RTL | ❌ **COMPILE_FAIL** | `iverilog_compile.log` · phán xử: `known_issues.md` |
| Tổng hợp | ✅ | `synth_stat.txt` · 18 cell |
| STA | ✅ | `timing_report_max.txt` · slack 8,41 ns |
| Công suất | ✅ | `power_report.txt` |
| Mô phỏng gate-level | ⬜ | ⚠️ **chặn bởi COMPILE_FAIL** — phải sửa testbench trước |
| Floorplan / Place / CTS / Route | ⬜ | cần LibreLane + PDK sky130A |
| DRC / LVS / GDS | ⬜ | như trên |

> ⚠️ **Lưu ý về thứ tự phụ thuộc:** trong hai đề E04/E05, bước "mô phỏng gate-level" chưa
> chạy vì **thiếu thư viện mô phỏng sky130**. Với E06 còn có một rào cản **đứng trước** đó:
> **testbench không biên dịch được**. Sửa lỗi ở `known_issues.md` §4 là **điều kiện tiên
> quyết**, không phải tuỳ chọn.

> **Điểm đáng chú ý:** tổng hợp và STA **PASS** trong khi mô phỏng **FAIL**. Điều này
> **không mâu thuẫn** — Yosys chỉ đọc RTL (`e06_detector.sv`), **không** đọc testbench.
> Đây chính là bằng chứng chéo mạnh nhất cho thấy **lỗi nằm ở testbench, không ở DUT**
> (xem `known_issues.md` §5.3).

## 5. Lưu ý về bản `_explicit`

`e06_detector_explicit.sv` tách `always_comb` (next-state) khỏi `always_ff` (chốt), gán mặc
định tường minh:
```systemverilog
history_d = history;  match_d = 1'b0;      // mặc định: giữ, không khớp
if (bit_valid) begin
    if ({history[3:0],bit_in} == 5'b10110) begin
        match_d = 1'b1;
        if (overlap_en) history_d = {history[3:0],bit_in};
        else            history_d = 5'b00000;
    end else            history_d = {history[3:0],bit_in};
end
```
**Tương đương hành vi** với bản top; dễ đọc hơn vì hai chế độ chồng lấn nằm cạnh nhau.

⚠️ Bản `_explicit` **không được tổng hợp**. **Mọi số liệu (18 cell, 5 FF, 182,6752 µm²,
1,47 ns) thuộc về `e06_detector`.**

Cảnh báo `sorry: constant selects in always_* processes` xuất hiện cho **cả ba file**
(`e06_detector_explicit.sv:12`, `e06_detector.sv:13`, `e06_reference.sv:12`) — đây là
**cảnh báo, không phải lỗi**, và **không** liên quan tới COMPILE_FAIL. Bằng chứng: cùng
cảnh báo đó xuất hiện ở E04/E05 vốn mô phỏng **PASS**.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Thành phần hồ sơ bắt buộc #2 và #6.*
