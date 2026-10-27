# E06 · Phần điều khiển (Control)

---

## 1. E06 có **0 flip-flop điều khiển** — điều khiển hoàn toàn tổ hợp

| Thành phần | Ô nhớ | Vai trò |
|---|---:|---|
| `history[3:0]` | 4 FF | **Dữ liệu** (cửa sổ trượt), không phải điều khiển |
| `match` | 1 FF | **Đầu ra đã chốt**, không phải biến trạng thái |
| **Biến trạng thái điều khiển** | **0 FF** | Không có |

**Chứng minh `match` không phải biến trạng thái:** trong `netlist.v`, tên `match` xuất hiện
đúng **hai lần** — một lần ở `output match;` và một lần ở `.Q(match)` của `dfxtp_1 _26_`.
**Không instance nào dùng `match` làm đầu vào.** ⟹ nó không quay lại logic next-state.

So sánh ba đề:

| | E04 | E05 | **E06** |
|---|---:|---:|---:|
| FF điều khiển | **5** (`count` 4 + `busy` 1) | 0 | **0** |
| FF dữ liệu | 8 | 16 | **4** |
| FF đầu ra | 0 | 1 (`done`) | **1** (`match`) |
| **Tổng** | 13 | 17 | **5** |

## 2. Bảng tín hiệu điều khiển và tác dụng

### 2.1 Tín hiệu điều khiển từ cổng vào

| Tín hiệu | Tác dụng | Fanout (netlist) | Cell nó đi vào |
|---|---|---:|---|
| `rst_n` | Xoá `history` và `match` về 0 (đồng bộ) | **4** | `_13_`, `_20_`, `_23_`, `_25_` |
| `bit_valid` | **Đóng băng/cho chạy** toàn bộ khối | **7** | `_14_`, `_17_`, `_20_`, `_21_`, `_23_`, `_24_`, `_25_` |
| `overlap_en` | Chọn giữ hay **xoá** cửa sổ sau khi khớp | **2** | `_19_`, `_22_` |

> Cả ba đều đi **thẳng từ cổng vào** tới logic tổ hợp, **không qua flip-flop nào**. Đó là
> định nghĩa của "điều khiển tổ hợp".

### 2.2 Tín hiệu nội bộ

| Tín hiệu | Cell | Hàm | Fanout |
|---|---|---|---:|
| `_05_` = `¬rst_n` | `clkinv_1 _13_` | đảo reset | 1 |
| `_06_` | `nand2b_1 _14_` | `¬(¬history[2] ∧ bit_valid)` — **một phần so sánh, gộp sẵn `bit_valid`** | **4** |
| `_07_` | `nand4b_1 _15_` | `¬(¬bit_in ∧ h0 ∧ h1 ∧ h3)` — **phần còn lại của so sánh** | 3 |
| `_00_` = `hit` | `nor3_1 _16_` | `rst_n ∧ ¬_06_ ∧ ¬_07_` | 1 (vào FF `_26_`) |

### 2.3 Bảng giải mã — 3 thao tác trên `history`

| `rst_n` | `bit_valid` | `hit` | `overlap_en` | Thao tác `history` | `match` kế tiếp |
|:-:|:-:|:-:|:-:|---|:-:|
| **0** | × | × | × | **← `0000`** | 0 |
| 1 | **0** | — | × | **giữ nguyên** (đóng băng) | 0 |
| 1 | 1 | 0 | × | **dịch**: `← {h[2:0], bit_in}` | 0 |
| 1 | 1 | **1** | **1** | **dịch** (chồng lấn): `← 0110` | **1** |
| 1 | 1 | **1** | **0** | **xoá**: `← 0000` | **1** |

Toàn bộ bảng này chỉ phụ thuộc **đầu vào hiện tại + giá trị cửa sổ** — không có cột "trạng
thái điều khiển". Đây là lý do E06 **không có FSM điều khiển** (xem `fsm.md`).

### 2.4 Trả lời Charter mục 2 câu 2 — hai chế độ khác nhau thế nào trong phần cứng

> *"Cho phép chồng lấn và không chồng lấn khác nhau thế nào trong phần cứng?"*

**Khác biệt duy nhất: hai cổng `o31ai_1`.**

```verilog
sky130_fd_sc_hd__o31ai_1 _19_ (.A1(overlap_en), .A2(_06_), .A3(_07_), .B1(\history[0] ), .Y(_09_));
sky130_fd_sc_hd__o31ai_1 _22_ (.A1(overlap_en), .A2(_06_), .A3(_07_), .B1(\history[1] ), .Y(_11_));
```

Khai triển `_19_`: `_09_ = ¬((overlap_en ∨ _06_ ∨ _07_) ∧ history[0])`.
Vì `(_06_ ∨ _07_) = ¬hit_core`, giá trị dịch vào `history[1]` là `history[0]` **trừ khi**
`(¬overlap_en ∧ hit)` — khi đó nó bị ép về `0`. ✅

| Chỉ số | Giá trị |
|---|---:|
| Cell **chuyên** cho `overlap_en` | **2** (`_19_`, `_22_`) = **11,1 %** của 18 cell |
| Flip-flop thêm | **0** |
| Chi phí **gia tăng** thật | **≈ 0–2 cell** — hai `o31ai_1` này **thay thế** cổng vốn cần cho mạch dịch, không cộng thêm |
| Chân vào thêm | 1 (`overlap_en`) |

#### 2.4.1 ⚠️ Vì sao chỉ **2 trong 4** bit cần logic xoá?

Chế độ không chồng lấn phải xoá **cả 4 bit** `history` về 0. Nhưng chỉ `history[1]` và
`history[2]` có cổng `o31ai`. Bit 0 và bit 3 thì sao?

| Bit | Cell | Có nhánh xoá? | **Vì sao không cần** |
|---|---|:-:|---|
| `history[0]` | `mux2i_1 _17_` + `nor2_1 _18_` | ❌ | Giá trị dịch vào là **`bit_in`**, và khi `hit` thì `bit_in = 0` (bit cuối của mẫu `10110` là `0`) ⟹ **đã bằng 0** |
| `history[1]` | `o31ai_1 _19_` + 2 cell | ✅ | Nhận `history[0]`, mà khi `hit` thì `h0 = 1` (bit thứ 4 của mẫu) ⟹ **phải ép về 0** |
| `history[2]` | `o31ai_1 _22_` + 2 cell | ✅ | Nhận `history[1]`, khi `hit` thì `h1 = 1` ⟹ **phải ép** |
| `history[3]` | `o211a_1 _25_` | ❌ | Nhận `history[2]`, khi `hit` thì `h2 = 0` (bit thứ 2 của mẫu) ⟹ **đã bằng 0** |

> **Đây là một trong những tối ưu đẹp nhất trong cả ba đề.** Yosys **kết hợp điều kiện kích
> hoạt với giá trị dữ liệu**: nó biết rằng *khi `hit` đúng, cửa sổ phải bằng `10110`*, nên
> hai vị trí vốn đã bằng `0` **không cần mạch xoá**. Người viết RTL viết
> `history <= 5'b00000` cho cả 5 bit; công cụ nhận ra 2 bit là thừa.
>
> Chỉ **đọc netlist** mới thấy được điều này. Đây là lý do SPEC §3 bước 5 bắt buộc đọc
> netlist.

## 3. Quan hệ điều khiển ↔ datapath

```
   rst_n ──────┬──▶ clkinv _13_ ──┐
               │                  │
               ├──────────────────┼────────┬──────────┬──────────┐
               │                  │        │          │          │
   bit_valid ──┼──▶ nand2b _14_ ──┼──▶ _06_┼──────────┼──────────┤
               │       ▲          │   (fanout 4)      │          │
               │       │ h2       │        │          │          │
   bit_in ─────┼───▶ nand4b _15_ ─┼──▶ _07_┤          │          │
               │       ▲  ▲  ▲    │   (fanout 3)      │          │
               │       │  │  │    ▼        ▼          ▼          ▼
               │    h0 h1 h3   nor3 _16_  o31ai _19_ o31ai _22_ o211a _25_
               │                  │        ▲          ▲          │
   overlap_en ─┼──────────────────┼────────┴──────────┘          │
               │                  │ hit    │          │          │
               │                  ▼        ▼          ▼          ▼
               │           ┌──────────┐  ┌────┐    ┌────┐    ┌────┐
               │           │ match FF │  │ h1 │    │ h2 │    │ h3 │
               │           └────┬─────┘  └─┬──┘    └─┬──┘    └─┬──┘
               │                ▼          │         │         │
               │             match         └─────────┴─────────┴──▶ hồi tiếp
               │                                                     vào _14_/_15_
               └──▶ mux2i _17_ ──▶ nor2 _18_ ──▶ h0 ──────────────────┘
                        ▲
                     bit_in
```

**Đặc điểm quan trọng:** có **hồi tiếp** từ datapath (`history`) về logic so sánh — nhưng
đó là **hồi tiếp dữ liệu**, không phải hồi tiếp điều khiển. Không có tín hiệu nào từ
`match` quay lại ảnh hưởng thao tác kế tiếp.

> **Hệ quả: E06 là mạch "phản ứng thuần tuý" (purely reactive).** Nó không nhớ mình đã tìm
> thấy bao nhiêu mẫu, không nhớ đang ở giai đoạn nào. Mỗi chu kỳ nó chỉ trả lời một câu hỏi:
> *"5 bit gần nhất có phải `10110` không?"*
>
> Chi phí trả cho sự đơn giản đó: việc **đếm số mẫu tìm thấy** hoặc **xác định ranh giới
> khung** phải do tầng ngoài làm.

## 4. Chế độ không chồng lấn — vì sao "xoá về 0" là **đủ** ở đây

Mô hình Python đặt `window = ""` (cửa sổ **rỗng**); RTL đặt `history = 0` (cửa sổ **toàn
số 0**). Hai cái **khác nhau về khái niệm** nhưng cho cùng kết quả với mẫu `10110`.

**Chứng minh:** sau khi xoá, với `k < 5` bit mới vào, cửa sổ RTL là `0…0 b₁…b_k` (có `5−k`
số `0` dẫn đầu). Muốn khớp `10110` thì bit trái nhất phải bằng `1` — nhưng nó là `0`.
⟹ **không thể khớp giả**. Từ bit thứ 5 trở đi, cửa sổ hoàn toàn do bit mới quyết định. ∎

### 4.1 ⚠️ Nhưng tính chất này **không tổng quát** — bẫy kinh điển

Nếu mẫu bắt đầu bằng `0`, ví dụ `01101`:

| Sau khi xoá, nạp | Cửa sổ RTL | Khớp `01101`? | Mô hình Python (cửa sổ rỗng) |
|---|---|:-:|:-:|
| 4 bit `1101` | `01101` | ✅ **KHỚP GIẢ** | ❌ không (cửa sổ chỉ 4 ký tự) |

⟹ **RTL sẽ báo khớp sau chỉ 4 bit mới**, trong khi định nghĩa đúng đòi hỏi 5 bit mới.

| Cách sửa cho mẫu bắt đầu bằng `0` | Chi phí |
|---|---|
| Thêm cờ **"cửa sổ chưa đầy"** — chặn `match` trong 4 chu kỳ đầu sau khi xoá | +1 bộ đếm 3 bit (~3 FF) hoặc +1 thanh ghi dịch cờ 4 bit (~4 FF) |
| Xoá cửa sổ về một giá trị **không thể là tiền tố của mẫu** | 0 FF nhưng cần phân tích riêng cho từng mẫu |

> **Charter mục 10 cảnh báo đúng vùng này:** *"Nhầm hai chế độ chồng lấn: sau khi khớp, chế
> độ không chồng lấn phải xoá thanh ghi."* Cảnh báo đó **đúng** nhưng **chưa đủ** — xoá
> thanh ghi là cần, nhưng chỉ **an toàn** khi bit đầu của mẫu bằng `1`. Đây là điều đáng
> dạy nhất của E06.

E06 **may mắn** có mẫu `10110` bắt đầu bằng `1`, nên cách làm đơn giản nhất lại đúng. Sinh
viên nào chép cách này sang một mẫu khác **sẽ sai**.

## 5. Điều khiển KHÔNG có ở đây — nằm ở tầng ngoài

| Chức năng | E06 có? | Ai làm | Hệ quả |
|---|:-:|---|---|
| **Khôi phục xung nhịp** từ dòng bit | ❌ | Đề **H07** | E06 cần `bit_valid` sạch |
| **Đếm số mẫu** tìm thấy | ❌ | Tầng ngoài | E06 chỉ báo từng lần |
| **Xác định ranh giới khung** sau `match` | ❌ | FSM tầng ngoài | E06 không biết gì về khung |
| **Timeout** khi không tìm thấy mẫu | ❌ | Tầng ngoài | E06 dò mãi mãi |
| **Xoá cửa sổ giữa hai phiên dò** | ⚠️ chỉ qua `rst_n` | Tầng ngoài | `bit_valid = 0` **không** xoá, chỉ đóng băng |
| **Quan sát nội dung cửa sổ** | ❌ **(W-1: Charter mục 4 yêu cầu)** | Không ai — **không có cổng ra** | REQ-E06-002 **CHƯA THOẢ**; và đây là nguyên nhân `history[4]` bị loại |
| **Đổi mẫu lúc chạy** | ❌ | Không ai | Mẫu nằm trong **hình dạng cổng** (`nand4b_1` chân `A_N`) — Charter mục 3 đặt ngoài phạm vi |

### 5.1 Nghĩa vụ hợp đồng — tóm tắt

Giống E05, E06 mỏng vì **đẩy độ phức tạp ra ngoài**. Một bộ điều khiển khung tối thiểu ở
tầng ngoài cần:

| Thành phần tầng ngoài | Ước lượng |
|---|---|
| FSM khung (HUNT / SYNC / DATA) | 2 FF |
| Bộ đếm độ dài khung `N` bit | `⌈log₂N⌉` FF |
| Logic timeout | vài FF |

⟹ Với khung 64 bit, tầng ngoài tốn ~**9 FF** — **nhiều hơn** toàn bộ E06 (5 FF). Phải nói
điều này khi bảo vệ, đừng khoe "chỉ 18 cell".

## 6. Ghi chú về trạng thái kiểm chứng

⚠️ **Không một phát biểu nào trong tài liệu này được xác nhận bằng mô phỏng** — testbench
`e06_detector_tb.sv` **không biên dịch được** (xem
[`../05_VERIFICATION/known_issues.md`](../05_VERIFICATION/known_issues.md)).

Tất cả phân tích trên dựa vào **hai nguồn bằng chứng khác**:
1. **Đọc RTL** (`e06_detector.sv`, 33 dòng).
2. **Khai triển đại số netlist** (`netlist.v`, 18 cell) — đây là bằng chứng **mạnh hơn** mô
   phỏng về mặt cấu trúc, vì nó kiểm được **mọi** tổ hợp đầu vào chứ không chỉ các vector
   testbench chạy. Nhưng nó **không thay thế được** mô phỏng về mặt hành vi theo thời gian.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
