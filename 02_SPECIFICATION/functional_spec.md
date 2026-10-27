# E06 · Đặc tả chức năng (Functional Specification)

---

## 0. ⚠️ CẢNH BÁO — RTL không khớp Charter ở hai điểm

> Đọc trước khi dùng phần còn lại. **Không tự sửa RTL** — hồ sơ giữ nguyên bản gốc của thầy.

| # | Yêu cầu Charter | Hiện trạng RTL `e06_detector` | Phán xử |
|---|---|---|---|
| **W-1** | **Charter mục 4**: `uo_out[5:1]` = **"nội dung thanh ghi"** (5 bit) | Module chỉ có **một** cổng ra: `match`. **Không có cổng nào xuất `history[4:0]`.** | ❌ **CHƯA THOẢ** — REQ-E06-002 |
| **W-2** | `02_SPECIFICATION/interface.md` §2 ghi *"**Không có reset**"* | RTL có `rst_n`, dùng ở dòng 19 `if (!rst_n)` **bên trong** `always_ff @(posedge clk)` ⟹ **reset đồng bộ, tích cực thấp** | ❌ Tài liệu sinh tự động **sai** |

### 0.1 Hệ quả đo được của W-1 — **phát hiện quan trọng nhất của đề**

Vì `history` **không có cổng ra**, Yosys chứng minh được `history[4]` là **tín hiệu chết**
và **loại bỏ hẳn nó**. Bằng chứng: netlist chỉ khai báo **bốn** dây `history`:

```verilog
// 06_GDSII/synthesis/netlist.v — toàn bộ khai báo history
  wire \history[0] ;
  wire \history[1] ;
  wire \history[2] ;
  wire \history[3] ;
  // KHÔNG có \history[4]
```

và đúng **5** flip-flop: `_26_` (`match`) + `_27_`…`_30_` (`history[0..3]`).

| | Charter mục 10 dự đoán | RTL khai báo | **Netlist thật** |
|---|---:|---:|---:|
| Ô nhớ dịch | 5 | `logic [4:0] history` = 5 | **4** |
| Chốt đầu ra | +1 | `match` = 1 | **1** |
| **Tổng** | **6** | 6 | **5** |

> **Chuỗi nhân quả đầy đủ:**
> Charter mục 4 yêu cầu xuất `history` → RTL **không** xuất → `history[4]` được ghi nhưng
> **không bao giờ được đọc** (vì `next_window = {history[3:0], bit_in}` chỉ dùng `[3:0]`) →
> Yosys loại bỏ → **5 FF thay vì 6**, đúng như BRIEF ghi.
>
> Nghĩa là: **độ lệch so với dự đoán Charter mục 10 không phải lỗi tổng hợp — nó là hệ quả
> trực tiếp của việc thiếu cổng ra theo Charter mục 4.** Nếu bổ sung cổng
> `output logic [4:0] window`, số FF sẽ trở lại đúng **6**.

### 0.2 Nhưng `history[4]` **vốn đã** thừa về mặt thuật toán

Ngay cả khi có cổng ra, `history[4]` cũng **không tham gia** vào việc phát hiện mẫu. Xem §4.2:
mẫu 5 bit chỉ cần **4 bit đã chốt + 1 bit đang vào**. Đây là hai vấn đề khác nhau và phải
phân biệt rõ:

| Vấn đề | Bản chất | Cách sửa |
|---|---|---|
| `history[4]` bị loại khỏi netlist | Thiếu cổng ra Charter mục 4 (W-1) | Thêm `output [4:0] window` |
| `history[4]` không tham gia phát hiện | **Thuật toán chỉ cần 4 FF** — đây là tối ưu đúng | Không cần sửa; nhưng nếu Charter muốn xuất "nội dung thanh ghi" thì phải giữ |

---

## 1. Chức năng — phát biểu một câu

E06 quan sát một dòng bit nối tiếp và **bật `match` trong đúng một chu kỳ** mỗi khi năm bit
gần nhất tạo thành mẫu **`10110`** (bit trái nhất là bit cũ nhất). Tín hiệu `overlap_en`
quyết định hai mẫu có được phép **chồng lấn** hay không.

Bối cảnh ứng dụng (Charter mục 1): *dò mẫu đồng bộ trong dòng bit đến từ đường truyền, để
biết khung dữ liệu bắt đầu ở đâu*.

## 2. Bảng hành vi mức trạng thái

Ký hiệu: `H` = `history[3:0]` (4 bit hữu dụng), `W` = `next_window` = `{H, bit_in}` (5 bit),
`P` = `5'b10110`. Mọi phép gán tại **sườn lên `clk`**.

| # | Điều kiện tại sườn lên | `H` kế tiếp | `match` kế tiếp |
|---|---|---|:-:|
| R | `rst_n = 0` | `4'b0000` | `0` |
| 1 | `rst_n=1`, `bit_valid = 0` | **giữ nguyên** | **`0`** |
| 2 | `rst_n=1`, `bit_valid=1`, `W ≠ P` | `W[3:0]` (dịch vào) | `0` |
| 3 | `rst_n=1`, `bit_valid=1`, `W = P`, `overlap_en = 1` | `W[3:0]` = `4'b0110` | **`1`** |
| 4 | `rst_n=1`, `bit_valid=1`, `W = P`, `overlap_en = 0` | **`4'b0000`** (xoá) | **`1`** |

Trích RTL tương ứng:
```systemverilog
// e06_detector.sv:13-31
next_window = {history[3:0], bit_in};
hit = bit_valid && (next_window == 5'b10110);
...
match <= 1'b0;                        // gán mặc định
if (bit_valid) begin
    if (hit && !overlap_en) history <= 5'b00000;   // hàng 4
    else                    history <= next_window; // hàng 2, 3
    match <= hit;
end
```

## 3. Định nghĩa chính xác đầu ra

| Đầu ra | Loại | Định nghĩa |
|---|---|---|
| `match` | **Tuần tự** (1 FF) | `match = FF( rst_n ∧ bit_valid ∧ (history[3:0] ∥ bit_in = 10110) )`. Xung rộng **đúng 1 chu kỳ** (trừ khi hai mẫu liên tiếp ở hai chu kỳ kề nhau — bất khả thi, xem §5 INV-4). |

**Bằng chứng netlist** — toàn bộ logic `match` chỉ tốn **3 cổng**:
```verilog
sky130_fd_sc_hd__clkinv_1  _13_ (.A(rst_n),                                       .Y(_05_));
sky130_fd_sc_hd__nand2b_1  _14_ (.A_N(\history[2] ), .B(bit_valid),               .Y(_06_));
sky130_fd_sc_hd__nand4b_1  _15_ (.A_N(bit_in), .B(\history[0] ),
                                 .C(\history[1] ), .D(\history[3] ),              .Y(_07_));
sky130_fd_sc_hd__nor3_1    _16_ (.A(_05_), .B(_06_), .C(_07_),                    .Y(_00_));
sky130_fd_sc_hd__dfxtp_1   _26_ (.CLK(clk), .D(_00_), .Q(match));
```

Khai triển: `_00_ = ¬(¬rst_n ∨ _06_ ∨ _07_) = rst_n ∧ ¬_06_ ∧ ¬_07_`
`= rst_n ∧ (bit_valid ∧ ¬history[2]) ∧ (¬bit_in ∧ history[0] ∧ history[1] ∧ history[3])`

Đối chiếu mẫu `10110`: `W = {history[3], history[2], history[1], history[0], bit_in}` phải
bằng `1,0,1,1,0` ⟹
`history[3]=1 ∧ history[2]=0 ∧ history[1]=1 ∧ history[0]=1 ∧ bit_in=0` — **khớp chính xác**. ✅

> **Đây là một trong những netlist đẹp nhất trong cả bộ đề:** một phép so sánh 5 bit với
> hằng số được Yosys rút xuống **đúng 3 cổng** (`nand2b` + `nand4b` + `nor3`), bằng cách
> dùng các ô có **đầu vào đảo sẵn** (`_N`). Đếm cổng từ cú pháp RTL (`==` 5 bit ⟹ "5 XNOR +
> 1 AND5") sẽ cho ước lượng sai gấp đôi.

## 4. Ràng buộc cấu trúc bắt buộc

Tên đề chốt **"dùng thanh ghi dịch"**; Charter mục 10 chốt *"5 ô nhớ dịch (+1 nếu có chốt
đầu ra)"*.

| ID | Ràng buộc | Thoả? | Bằng chứng |
|---|---|:-:|---|
| ST-1 | Phải dùng **thanh ghi dịch**, **không** dùng FSM liệt kê trạng thái | ✅ | `next_window = {history[3:0], bit_in}` — phép nối bit tường minh; netlist có `mux2i_1 _17_` làm mạch dịch |
| ST-2 | Mẫu `10110` phải được **so sánh với nội dung cửa sổ**, không mã hoá thành trạng thái | ✅ | `next_window == 5'b10110` (dòng 15) → `nand4b _15_` |
| ST-3 | Phải có **chế độ chồng lấn** điều khiển được | ✅ | `overlap_en` vào `o31ai _19_`, `_22_` |
| ST-4 | Ô nhớ ≈ 5 (+1 chốt) | ⚠️ **5** đo được, không phải 6 — xem §0.1 | `synth_stat.txt`: `dfxtp_1 × 5` |
| ST-5 | `match` phải là xung **1 chu kỳ** | ✅ | `match <= 1'b0` mặc định (dòng 23) + ghi đè (dòng 29) |

### 4.1 `overlap_en` hiện thực ra sao — Charter mục 2, câu 2

> *"Cho phép chồng lấn và không chồng lấn khác nhau thế nào trong phần cứng?"*

Khác biệt **duy nhất** là: khi khớp, cửa sổ **giữ nguyên** (chồng lấn) hay **bị xoá về 0**
(không chồng lấn). Trong netlist, `overlap_en` chỉ xuất hiện ở **hai** cổng:

```verilog
sky130_fd_sc_hd__o31ai_1 _19_ (.A1(overlap_en), .A2(_06_), .A3(_07_), .B1(\history[0] ), .Y(_09_));
sky130_fd_sc_hd__o31ai_1 _22_ (.A1(overlap_en), .A2(_06_), .A3(_07_), .B1(\history[1] ), .Y(_11_));
```

Khai triển `_19_`: `_09_ = ¬( (overlap_en ∨ _06_ ∨ _07_) ∧ history[0] )`.
Vì `(_06_ ∨ _07_) = ¬hit_core`, ta có: giá trị dịch vào `history[1]` là
`history[0]` **trừ khi** `(¬overlap_en ∧ hit)` — khi đó nó bị ép về `0`. ✅

| Chi phí của chế độ chồng lấn | Con số |
|---|---:|
| Cell chuyên cho `overlap_en` | **2** (`o31ai_1 _19_`, `_22_`) — nhưng chúng **thay thế** các cổng vốn cần cho mạch dịch, nên chi phí **gia tăng ≈ 0–2 cell** |
| Flip-flop thêm | **0** |
| Chân vào | 1 |

> **Chi phí cực thấp** — và đó là lý do gần như mọi bộ dò mẫu thật đều hỗ trợ cả hai chế độ.

#### 4.1.1 ⚠️ Chi tiết tinh vi: **vì sao `history[2]` và `history[3]` KHÔNG cần logic xoá?**

Chế độ không chồng lấn phải xoá **cả 4 bit** `history` về 0. Nhưng netlist chỉ có **2** cổng
`o31ai` (cho bit 1 và bit 2 của `history` kế tiếp). Bit 0 và bit 3 thì sao?

```verilog
sky130_fd_sc_hd__mux2i_1 _17_ (.A0(\history[0] ), .A1(bit_in), .S(bit_valid), .Y(_08_));
sky130_fd_sc_hd__nor2_1  _18_ (.A(_05_), .B(_08_), .Y(_01_));   // _01_ → history[0]
```
`history[0]` kế tiếp = `bit_valid ? bit_in : history[0]`, **không có** nhánh xoá.

**Lý do:** khi `hit` đúng thì `bit_in` **bắt buộc phải bằng `0`** (vì bit cuối của mẫu
`10110` là `0`). Nên giá trị dịch vào `history[0]` **đã** bằng 0 rồi — **không cần xoá**.
Yosys đã tự phát hiện điều này.

Tương tự `history[3]` (`o211a_1 _25_`) không cần nhánh `overlap_en` vì nó nhận
`history[2]`, và khi `hit` thì `history[2] = 0` (bit thứ hai của mẫu là `0`).

> **Bài học:** công cụ tổng hợp làm được suy luận mà người viết RTL thường bỏ qua — nó
> **kết hợp điều kiện kích hoạt với giá trị dữ liệu**. Chỉ đọc netlist mới thấy được.

### 4.2 Vì sao chỉ cần **4** flip-flop cho mẫu **5** bit

Điểm bản chất thứ hai của đề:

```
  Cửa sổ so sánh: W = { history[3], history[2], history[1], history[0], bit_in }
                        └──────── 4 bit ĐÃ CHỐT ────────┘   └─ 1 bit ĐANG VÀO ─┘
                              (cần flip-flop)                  (không cần FF!)
```

Bit cuối cùng của mẫu được so sánh **ngay trên đường vào**, trước khi nó được chốt. Vì vậy
mẫu `N` bit chỉ cần **`N−1` flip-flop**.

| Mẫu | FF lý thuyết tối thiểu | E06 đo được |
|---|---:|---:|
| 5 bit (`10110`) | **4** | **4** ✅ (+1 cho `match`) |

Đây là lý do BRIEF ghi **5 FF** trong khi Charter mục 10 dự đoán 6.

## 5. Tính chất bất biến (Invariants)

| ID | Phát biểu | Dạng SVA gợi ý |
|---|---|---|
| **INV-1** | `bit_valid = 0` ⟹ `match` chu kỳ sau = `0` và `history` không đổi | `assert property (@(posedge clk) (rst_n && !bit_valid) \|=> (!match && $stable(dut.history)));` |
| **INV-2** | `match` lên ⟺ chu kỳ trước có `bit_valid` và cửa sổ = `10110` | `assert property (@(posedge clk) match \|-> $past(bit_valid && ({dut.history[3:0],bit_in}==5'b10110)));` |
| **INV-3** | Ở chế độ **không** chồng lấn, sau `match` thì `history = 0` | `assert property (@(posedge clk) (match && !$past(overlap_en)) \|-> (dut.history[3:0]==4'b0000));` |
| **INV-4** | **`match` không bao giờ lên hai chu kỳ liên tiếp** | `assert property (@(posedge clk) match \|=> !match);` — chứng minh ở §7.2 |
| **INV-5** | Ở chế độ chồng lấn, hai `match` cách nhau **≥ 3 chu kỳ có `bit_valid`** | chứng minh ở §7.3 |
| **INV-6** | Sau reset: `history = 0`, `match = 0` | `assert property (@(posedge clk) !rst_n \|=> (dut.history==0 && !match));` |
| **INV-7** | `overlap_en` **không** ảnh hưởng tới **việc có khớp hay không** ở chu kỳ hiện tại, chỉ ảnh hưởng tới các chu kỳ **sau** | `hit` (dòng 15) không chứa `overlap_en` — kiểm bằng đọc mã |
| **INV-8** | Chế độ chồng lấn phát hiện **tập siêu** của chế độ không chồng lấn | suy từ §7.3 |

⚠️ **Không assertion nào trong danh sách này được kiểm** — testbench **không biên dịch được**
(xem `05_VERIFICATION/known_issues.md`). Mọi phát biểu ở đây là **suy luận từ mã và netlist**,
**chưa có bằng chứng mô phỏng**.

## 6. Reset, độ trễ

### 6.1 Reset

- **Đồng bộ**, tích cực thấp; cần ≥ 1 sườn `clk` với `rst_n = 0`.
- Bằng chứng netlist: 5 ô nhớ đều là `dfxtp_1` — **không có chân `RESET_B`**. `rst_n` gộp
  vào tổ hợp qua `clkinv_1 _13_` rồi vào `nor3 _16_`, `nor2 _18_`, `o21ai _20_`/`_23_`,
  `o211a _25_`.
- Sau reset: `history = 0`, `match = 0`.

### 6.2 Độ trễ tính bằng chu kỳ

| Từ | Đến | Số chu kỳ |
|---|---|---:|
| Sườn lấy mẫu **bit thứ 5 của mẫu** | `match = 1` | **0** (ngay sau sườn đó) |
| `match = 1` | `match = 0` | **1** |
| Reset nhả | sẵn sàng phát hiện mẫu đầu tiên | **0** — nhưng cần ≥ 5 bit vào trước khi có thể khớp |

> `match` là đầu ra **đã chốt** (Moore), nên nó trễ **một sườn** so với bit gây ra nó. Tầng
> ngoài phải hiểu: `match` ở chu kỳ `t` nói về bit được lấy mẫu ở sườn `t`, không phải bit
> đang có trên `bit_in` ở chu kỳ `t`.

### 6.3 `bit_valid` — cơ chế "đóng băng thời gian"

`bit_valid = 0` làm **toàn bộ khối đứng yên**: `history` giữ nguyên, `match = 0`. Nghĩa là
E06 đếm theo **số bit hợp lệ**, không theo **số chu kỳ clock**. Điều này cho phép nguồn bit
chạy chậm hơn clock (ví dụ 1 bit mỗi 16 chu kỳ) mà không cần chia tần.

## 7. Điều kiện biên và hành vi không xác định

| # | Tình huống | Hành vi RTL | Đặc tả? |
|---|---|---|---|
| B-1 | Mẫu xuất hiện ngay từ **5 bit đầu tiên** sau reset | ✅ Phát hiện được. `history = 0000` sau reset, nạp `1,0,1,1` rồi `bit_in=0` ⟹ `W = 10110` | ✅ |
| B-2 | **Hai mẫu chồng lấn** `1011011010`, `overlap_en=1` | Phát hiện **2 lần**, tại bit 5 và bit 8 | ✅ — khớp `reference_model.py:18` `[5, 8]` |
| B-3 | Cùng chuỗi, `overlap_en=0` | Phát hiện **1 lần**, tại bit 5 | ✅ — `reference_model.py:19` `[5]` |
| B-4 | `bit_valid` nhấp nháy giữa chừng | Khối "đóng băng"; mẫu vẫn khớp khi đủ 5 bit **hợp lệ** liên tiếp | ✅ |
| B-5 | `overlap_en` **đổi giữa chừng** | Không có trạng thái nào ghi nhớ `overlap_en`; chế độ có hiệu lực **ngay tại sườn khớp** | ⚠️ xem §7.1 |
| B-6 | `bit_in` có `X`/`Z` khi `bit_valid=1` | **KHÔNG XÁC ĐỊNH** — `X` lan vào `history` và kéo dài ≤ 4 chu kỳ | ❌ nghĩa vụ tầng ngoài |
| B-7 | `rst_n` xuống 0 giữa chuỗi | Cửa sổ bị xoá; mẫu đang hình thành **mất** | ✅ |
| B-8 | `rst_n=0` mà `clk` đứng yên | **Không reset** (đồng bộ) | ❌ nghĩa vụ tầng ngoài |
| B-9 | Trạng thái `history` bất hợp lệ | **Không tồn tại** — cả 16 giá trị của `history[3:0]` đều hợp lệ | ✅ xem §7.4 |

### 7.1 B-5 — `overlap_en` không được chốt, và điều đó **là đúng**

`overlap_en` đi thẳng từ cổng vào tới `o31ai _19_`/`_22_`, không qua flip-flop nào. Vậy nếu
nó đổi giữa chừng thì sao?

Trả lời: **không sao cả**, vì `overlap_en` chỉ có tác dụng **tại đúng sườn xảy ra khớp**.
Giá trị của nó ở các chu kỳ khác hoàn toàn không ảnh hưởng. Nghĩa vụ tầng ngoài: giữ
`overlap_en` ổn định **quanh sườn có khả năng khớp** — thực tế nghĩa là giữ nó cố định
trong suốt phiên dò.

### 7.2 Chứng minh INV-4: `match` **không bao giờ** hai chu kỳ liên tiếp

Giả sử `match` lên ở hai sườn `t` và `t+1`. Ở sườn `t`: `W_t = 10110` ⟹ `bit_in(t) = 0` và
`history(t+1)[3:0] = 0110` (chồng lấn) hoặc `0000` (không chồng lấn).
Ở sườn `t+1` cần `W_{t+1} = {history(t+1)[3:0], bit_in(t+1)} = 10110` ⟹
`history(t+1)[3:0]` phải bằng `1011`.
Nhưng ta vừa có `0110` hoặc `0000` — **cả hai đều khác `1011`**. Mâu thuẫn. ∎

### 7.3 Chứng minh INV-5: hai `match` chồng lấn cách nhau **≥ 3 bit**

Sau một khớp ở chế độ chồng lấn, `history = 0110`. Muốn khớp lại cần `history = 1011`. Mỗi
bit vào dịch trái 1 vị trí. Kiểm tra:
- sau 1 bit: `110b₁` — cần `1011`, sai ở bit 2.
- sau 2 bit: `10b₁b₂` — cần `1011`: `b₁=1, b₂=1` ⟹ **khả dĩ!** rồi cần `bit_in = 0`.

⟹ Khoảng cách tối thiểu giữa hai `match` là **3 bit hợp lệ**. Đúng với `reference_model.py`:
`detect("1011011010", True) == [5, 8]` — cách nhau **3**. ✅

Đây chính là câu trả lời cho Charter mục 2 câu 3 (xem `corner_cases.md` §1).

### 7.4 B-9 — vì sao **không có trạng thái bất hợp lệ**

Cả 16 giá trị của `history[3:0]` đều là "4 bit gần nhất của một dòng bit nào đó" ⟹ đều hợp
lệ và đều đạt tới được. Không có trạng thái chết, không có nguy cơ kẹt.

> **Đối lập rõ với E04**, nơi `count[3:0]` có **8 trạng thái bất hợp lệ** có thể làm `busy`
> kẹt 16 chu kỳ. Đây là **ưu điểm cấu trúc của cách làm bằng thanh ghi dịch**: trạng thái
> *là* dữ liệu, nên mọi trạng thái đều hợp lệ theo định nghĩa. Một FSM mã hoá tay (như F04)
> **không có** tính chất này.

### 7.5 Một bẫy tinh vi: xoá về `00000` chỉ **đúng** vì mẫu bắt đầu bằng `1`

Chế độ không chồng lấn xoá `history` về `0`. Mô hình Python thì đặt `window = ""` (rỗng).
**Hai cái không giống nhau** — nhưng ở đây cho kết quả như nhau. Vì sao?

Sau khi xoá, với `k < 5` bit mới vào, cửa sổ RTL là `0…0 b₁…b_k` (có `5−k` số 0 dẫn đầu).
Để khớp `10110` cần bit đầu tiên bằng `1` — nhưng nó là `0`. ⟹ **không thể khớp giả**. ∎

⚠️ **Tính chất này KHÔNG tổng quát.** Nếu mẫu là `01101` (bắt đầu bằng `0`), thì sau khi xoá
và nạp 4 bit `1101`, cửa sổ = `01101` = **khớp giả** chỉ sau 4 bit, trong khi mô hình Python
(cửa sổ rỗng) sẽ **không** khớp.

> **Đây là bẫy kinh điển rất đáng dạy:** "xoá thanh ghi về 0" là cách hiện thực
> **không chồng lấn** phổ biến nhất, và nó **chỉ an toàn khi bit đầu của mẫu bằng 1**. Với
> mẫu bắt đầu bằng `0`, phải dùng thêm **một bit cờ "cửa sổ chưa đầy"** hoặc một bộ đếm
> nạp lại. Charter mục 10 cảnh báo đúng vùng này: *"Nhầm hai chế độ chồng lấn: sau khi khớp,
> chế độ không chồng lấn phải xoá thanh ghi."*

## 8. Truy vết

| Mục | Yêu cầu | Bằng chứng |
|---|---|---|
| §2, §3 | REQ-E06-001 | `e06_detector.sv`; ⚠️ **mô phỏng COMPILE_FAIL** — xem `known_issues.md` |
| §3 (netlist `match`) | REQ-E06-003 | `netlist.v` `_14_`, `_15_`, `_16_`, `_26_` |
| §4.2 (4 FF cho mẫu 5 bit) | REQ-E06-004 | `synth_stat.txt`: `dfxtp_1 × 5` |
| §0 W-1 | REQ-E06-002 | ❌ **CHƯA THOẢ** |
| §5 (INV-1…INV-8) | REQ-E06-012 | ❌ **Chưa kiểm được** — testbench không biên dịch |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
