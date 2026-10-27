# E06 · Đường dữ liệu (Datapath)

---

## 1. Datapath của E06 là một **cửa sổ trượt** — và nó cũng chính là toàn bộ trạng thái

E06 không có ranh giới rõ giữa "datapath" và "điều khiển": **4 flip-flop `history[3:0]`
vừa là dữ liệu vừa là trạng thái**. Đây là đặc điểm chung của mọi bộ dò mẫu dùng thanh ghi
dịch, và nó đối lập trực tiếp với cách làm bằng FSM (đề F04) nơi trạng thái được **mã hoá**
chứ không **chứa dữ liệu**.

```
   dòng bit vào:  … b(t-4)  b(t-3)  b(t-2)  b(t-1)  b(t) …
                     │       │       │       │       │
                  ┌──┴───┬───┴───┬───┴───┬───┴───┐   │
   cửa sổ trượt:  │  h3  │  h2   │  h1   │  h0   │   │ bit_in
                  └──────┴───────┴───────┴───────┘   │
                     ▲ đã chốt (4 FF)                ▲ ĐANG VÀO
                     │                               │ (chưa chốt!)
                     └───────────┬───────────────────┘
                                 ▼
                    so sánh 5 bit với '1 0 1 1 0'
```

> **Điểm bản chất:** bit thứ 5 của mẫu được so sánh **trên đường vào**, trước khi nó được
> chốt. Vì vậy mẫu `N` bit chỉ cần **`N−1` flip-flop**. Đây là lý do BRIEF ghi **5 FF**
> (4 cửa sổ + 1 `match`) trong khi Charter mục 10 dự đoán 6.

## 2. Bảng các đường dữ liệu

| Đường | Độ rộng | Từ | Đến | Bản chất |
|---|---:|---|---|---|
| `bit_in` | 1 | cổng vào | `nand4b_1 _15_` + `mux2i_1 _17_` | **Dữ liệu vào** — vừa được **so sánh** vừa được **chốt** |
| `history[0]` | 1 | FF `_27_` | `_15_` (so sánh), `_17_` (giữ), `_19_` (dịch lên h1) | Bit mới nhất đã chốt |
| `history[1]` | 1 | FF `_28_` | `_15_`, `_20_`, `_22_` | |
| `history[2]` | 1 | FF `_29_` | **`_14_`** (so sánh, qua chân đảo `A_N`), `_23_`, `_25_` | Bit duy nhất được so với `0` |
| `history[3]` | 1 | FF `_30_` | `_15_`, `_25_` | Bit cũ nhất trong cửa sổ |
| `history[4]` | — | — | — | ❌ **KHÔNG TỒN TẠI** trong netlist (tín hiệu chết) |
| `_06_` | 1 | `nand2b_1 _14_` | `_16_`, `_19_`, `_22_`, `_25_` | Kết quả một phần của so sánh (**fanout 4**) |
| `_07_` | 1 | `nand4b_1 _15_` | `_16_`, `_19_`, `_22_` | Kết quả một phần (**fanout 3**) ← **trên đường tới hạn** |
| `_00_` = `hit` | 1 | `nor3_1 _16_` | FF `_26_` | Tín hiệu khớp, chưa chốt |
| `match` | 1 | FF `_26_` | cổng ra | **Kết quả ra, ĐÃ CHỐT (Moore)** |
| `bit_valid` | 1 | cổng vào | `_14_`, `_17_`, `_20_`, `_21_`, `_23_`, `_24_`, `_25_` | Điều khiển "đóng băng" (**fanout 7**) |
| `overlap_en` | 1 | cổng vào | `_19_`, `_22_` **chỉ 2 nơi** | Điều khiển chế độ |
| `rst_n` | 1 | cổng vào | `_13_`, `_20_`, `_23_`, `_25_` | Reset đồng bộ |

### 2.1 `bit_in` có **hai vai** — và đó là chìa khoá của thiết kế

| Vai | Đích | Hệ quả |
|---|---|---|
| **Toán hạng so sánh** | `nand4b_1 _15_` chân `.A_N(bit_in)` | Tiết kiệm **1 flip-flop** (mẫu 5 bit chỉ cần 4 FF) |
| **Dữ liệu dịch vào** | `mux2i_1 _17_` chân `.A1(bit_in)` | Trở thành `history[0]` ở chu kỳ sau |

Chính vai thứ nhất khiến `bit_in` trở thành **startpoint của đường tới hạn** — xem §5.

## 3. Đồ thị phụ thuộc và độ sâu logic

### 3.1 Đồ thị trong một chu kỳ

```
 mức 0   bit_in ──┬──────────────────────┐    history[0..3] ──┐   bit_valid ──┐
                  │                      │         │          │    overlap_en┐│
                  ▼                      │         ▼          │              ││
 mức 1    nand4b_1 _15_ (_07_)           │   nand2b_1 _14_ (_06_) ◀──────────┘│
          fanout 3                       │   fanout 4                          │
           │    │                        │      │  │                           │
           │    └────────┬───────────────┼──────┘  │                           │
           │             ▼               │         │                           │
 mức 2     │      nor3_1 _16_ ◀── ¬rst_n │         │                           │
           │             │               │         │                           │
           │             ▼               │         │                           │
 mức 2/FF  │      ┌────────────┐         │         │                           │
           │      │ match FF   │──▶ match│         │                           │
           │      └────────────┘         │         │                           │
           │                             │         │                           │
           └────────▶ o31ai_1 _19_/_22_ ◀┴─────────┴───────────────────────────┘
 mức 2                   │  (overlap_en + h0/h1)
                         ▼
 mức 3            a21oi_1 _21_/_24_  ◀── o21ai_0 _20_/_23_ (mức 2, song song)
                         │
                         ▼
 mức 3/FF         history[1], history[2]        ← ĐÍCH đường tới hạn

 ── nhánh ngắn, KHÔNG trên đường tới hạn ──
 bit_in ──▶ mux2i_1 _17_ ──▶ nor2_1 _18_ ──▶ history[0]        (mức 2)
 history[2], bit_valid, rst_n, _06_ ──▶ o211a_1 _25_ ──▶ history[3]  (mức 2)
```

### 3.2 Độ sâu logic của từng đích

| Đích | Độ sâu từ cổng vào | Cell trên đường | Arrival (ns) |
|---|---:|---|---:|
| `history[1]` (`_28_`) | **3** | `nand4b` → `o31ai` → `a21oi` | **1,47** ← tới hạn |
| `history[2]` (`_29_`) | **3** | `nand4b` → `o31ai` → `a21oi` | **1,47** |
| `match` (`_26_`) | **2** | `nand4b` → `nor3` | 1,31 |
| `history[0]` (`_27_`) | **2** | `mux2i` → `nor2` | 1,19 |
| `history[3]` (`_30_`) | **1** | `o211a` | 1,19 |
| `match` (cổng ra) | **0** từ FF | trực tiếp `Q` | 0,26 |

**Nhận xét cốt lõi 1 — sâu nhất chỉ 3 cell.** Giống E04 và E05, và cùng lý do bản chất:
**thanh ghi cắt chuỗi phụ thuộc**. Bit `history[k]` ở chu kỳ `t` chỉ cần `history[k−1]` ở
chu kỳ `t−1`.

**Nhận xét cốt lõi 2 — `history[3]` chỉ sâu 1 cell.**
```verilog
o211a_1 _25_ (.A1(\history[3] ), .A2(bit_valid), .B1(rst_n), .C1(_06_), .X(_04_));
```
Bit cũ nhất của cửa sổ cần **ít logic nhất** — nó chỉ nhận `history[2]` (qua `_06_`), không
cần nhánh `overlap_en` (vì khi `hit`, `h2 = 0` sẵn). Một ô `o211a_1` làm đủ việc.

**Nhận xét cốt lõi 3 — `match` nông hơn `history[1]`.**
`match` (2 cell) nông hơn `history[1]` (3 cell), vì nó **không** đi qua logic
`overlap_en`. Đây là điều tốt: đầu ra ra khỏi chip là đường **nhanh nhất**, không phải chậm
nhất.

## 4. Đặc điểm phân biệt E06 với E04 và E05

| | E04 | E05 | **E06** |
|---|---|---|---|
| Kích thước | 55 cell · 13 FF | 64 cell · 17 FF | **18 cell · 5 FF** |
| Diện tích | 519,248 µm² | 646,8704 µm² | **182,6752 µm²** |
| Công suất | 6,29e-05 W | 7,72e-05 W | **2,35e-05 W** |
| FF điều khiển | 5 (38 %) | 0 | **0** |
| Trạng thái bất hợp lệ | **8** (`count ≥ 8`) | 0 | **0** |
| Có bộ đếm? | ✅ | ❌ | ❌ |
| Có khái niệm "giao dịch"? | ✅ (8 bit) | ✅ (gói) | ❌ **dòng liên tục vô hạn** |
| Startpoint tới hạn | điều khiển (`start`) | điều khiển (`data_valid`) | **DỮ LIỆU (`bit_in`)** |
| Số đường trong STA max | 10 | 10 | **6** |

> **E06 là thiết kế "thuần khiết" nhất trong ba đề:** không bộ đếm, không biến trạng thái
> điều khiển, không giao dịch, không trạng thái bất hợp lệ. Toàn bộ trạng thái **là** dữ
> liệu. Đây là hệ quả trực tiếp của việc dùng **thanh ghi dịch** thay vì FSM — và là câu
> trả lời cho Charter mục 2 câu 1 (so với F04).

## 5. Dự đoán đường tới hạn từ RTL rồi đối chiếu STA thật

### 5.1 Dự đoán trước khi xem STA

| Ứng viên | Lập luận | Dự đoán |
|---|---|---|
| (a) `bit_in → so sánh 5 bit → hit → match` | So sánh 5 bit là phép "nặng" nhất trong mạch | **Ứng viên số 1** |
| (b) `bit_in → so sánh → overlap_en → xoá → history` | Dài hơn (a) vì đi qua logic xoá | Ứng viên số 2 |
| (c) `bit_valid → mạch dịch → history[0]` | Chỉ là điều khiển đơn giản | ít ai chọn |

### 5.2 STA thật nói gì

```
Startpoint: bit_in (input port clocked by clk)
Endpoint:   _28_ = history[1]
arrival 1.47 ns · slack 8.41 ns (MET) · WNS 0.00 · TNS 0.00
```

**Dự đoán (b) ĐÚNG** — lần này dự đoán trúng, khác hẳn E04 và E05.

Lý do dự đoán (a) thua: đường tới `match` chỉ có **2 cell** (`nand4b` → `nor3`), arrival
**1,31 ns**, slack 8,62 ns. Đường tới `history[1]` có **3 cell** vì phải đi thêm qua logic
`overlap_en` (`o31ai_1 _19_`) và mạch dịch (`a21oi_1 _21_`) ⟹ **1,47 ns**.

### 5.3 Bảng đối chiếu dự đoán ↔ thực đo

| | Dự đoán từ RTL | STA thật | Nhận xét |
|---|---|---|---|
| Startpoint | `bit_in` | **`bit_in`** ✅ | ✅ Đúng |
| Endpoint | `history[1]` hoặc `match` | **`history[1]`** ✅ | ✅ Đúng — đường qua `overlap_en` dài hơn |
| Độ sâu | 3 tầng | **3 cell** ✅ | ✅ Đúng |
| Nút thắt | so sánh 5 bit | **`nand4b_1`, 0,18 ns = 38 % phần logic** ✅ | ✅ Đúng — cổng 4 đầu vào chậm |
| Delay | — | **1,47 ns** (trong đó 1,00 ns IO) | — |

> **Vì sao E06 dễ đoán hơn E04/E05?** Vì mạch **quá nhỏ**: không có tín hiệu điều khiển nào
> có fanout đủ lớn để lật ngược thứ hạng. Trong E05, `data_valid` lái **12 tải** nên đường
> điều khiển thắng đường dữ liệu; trong E06, `bit_valid` chỉ lái **7** và `overlap_en` lái
> **2**, còn `bit_in` đi qua cổng `nand4b` **4 đầu vào** vốn đã chậm sẵn.
>
> **Quy luật:** với mạch nhỏ, độ phức tạp cổng thắng; với mạch rộng, fanout thắng.

### 5.4 Phân rã con số 1,47 ns

| Thành phần | ns | % |
|---|---:|---:|
| `set_input_delay` (**giả định**, không phải logic E06) | **1,00** | **68,0 %** |
| `nand4b_1 _15_` (so sánh mẫu) | 0,18 | 12,2 % |
| `o31ai_1 _19_` (logic `overlap_en`) | 0,20 | 13,6 % |
| `a21oi_1 _21_` (mạch dịch) | 0,08 | 5,4 % |
| **Tổng** | **1,47** | 100 % |

⚠️ **Logic thật của E06 chỉ chiếm 0,47 ns = 4,7 % chu kỳ 10 ns.** Đây là thiết kế **nông
nhất** trong ba đề (E04: 0,71 ns; E05: 0,51 ns). Nói "E06 chạy được ở 680 MHz" là **sai**:
con số 1,47 ns chưa có RC dây, mới một góc PVT, và 68 % của nó là giả định biên IO.

## 6. `bit_valid` — cơ chế đóng băng, và giới hạn của nó

```verilog
mux2i_1 _17_ (.A0(\history[0] ), .A1(bit_in), .S(bit_valid), .Y(_08_));
```
Khi `bit_valid = 0`, mọi flip-flop `history` **giữ nguyên** và `match = 0`. Khối đếm theo
**số bit hợp lệ**, không theo **số chu kỳ clock**.

| Tính chất | Hệ quả |
|---|---|
| ✅ Nguồn bit có thể chậm hơn clock tuỳ ý | Không cần bộ chia tần; E06 dùng được với mọi tốc độ bit |
| ✅ Không cần đồng bộ hai miền thời gian | miễn là `bit_valid` đồng bộ với `clk` |
| ⚠️ `bit_valid = 0` **KHÔNG xoá** cửa sổ | Muốn xoá phải xung `rst_n` — xem `system_diagram.md` §2.1 O-6 |
| ⚠️ Nhánh `bit_valid = 0` **chưa bao giờ được mô phỏng** | testbench COMPILE_FAIL; và ngay cả khi chạy, lớp B-V không được phủ (`corner_cases.md` §3) |

## 7. Vì sao chỉ cần 4 flip-flop — chứng minh và tổng quát hoá

**Định lý:** bộ dò mẫu `N` bit dùng cửa sổ trượt cần đúng **`N−1`** flip-flop dữ liệu.

**Chứng minh:** cửa sổ so sánh tại chu kỳ `t` là `{b(t−N+1), …, b(t−1), b(t)}`. Bit `b(t)`
đang có trên cổng vào (`bit_in`), chưa cần chốt. `N−1` bit còn lại đã trôi qua ⟹ phải chốt.
⟹ `N−1` flip-flop. ∎

| Mẫu | FF dữ liệu | FF chốt `match` | Tổng |
|---|---:|---:|---:|
| 3 bit | 2 | 1 | 3 |
| **5 bit (`10110`) — E06** | **4** | **1** | **5** ✅ đo được |
| 8 bit | 7 | 1 | 8 |

Đối chiếu `synth_stat.txt`: `dfxtp_1 × 5` — **khớp chính xác**.

> **Lưu ý phân biệt hai nguyên nhân** (đã nêu ở `functional_spec.md` §0.2):
> 1. `history[4]` **thừa về thuật toán** — định lý trên chứng minh chỉ cần 4 FF.
> 2. `history[4]` **bị loại khỏi netlist** — vì không có cổng ra theo Charter mục 4 (W-1).
>
> Hai điều này **trùng nhau ở kết quả** (5 FF) nhưng **khác nhau về nguyên nhân**. Nếu bổ
> sung cổng ra theo Charter, sẽ có **6 FF** — trong đó `history[4]` chỉ phục vụ việc **quan
> sát**, không phục vụ việc **phát hiện**.

## 8. Cơ hội tối ưu (chỉ để thảo luận)

| Phương án | Ảnh hưởng | Vì sao không dùng |
|---|---|---|
| Dò **nhiều bit/chu kỳ** (unrolling) | Thông lượng ×k | Cần nhân bản logic so sánh k lần; và **mất tính "nối tiếp"** của đề |
| Bỏ `overlap_en`, cố định một chế độ | Tiết kiệm **≈ 0–2 cell** (`o31ai_1 _19_`, `_22_` thay bằng cổng đơn giản hơn) | Charter mục 4 yêu cầu `uio_in[1]` = "cho phép chồng lấn" ⟹ **bắt buộc có** |
| Chốt thêm `match` qua 1 FF nữa | Tách xa hơn khỏi logic tổ hợp | Không cần — `match` đã là Moore, đường reg→out chỉ 0,26 ns |
| Thêm cổng ra `window[4:0]` theo Charter | Thoả W-1; `history[4]` sống lại ⟹ **6 FF** | ✅ **Nên làm** — xem `tradeoff.md` §6 |

Với slack **8,41 ns** trên chu kỳ giả định 10 ns, **không có nhu cầu tối ưu tốc độ nào**.
E06 đã là thiết kế nhỏ nhất và nhanh nhất trong ba đề.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
