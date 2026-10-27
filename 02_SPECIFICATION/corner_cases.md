# E06 · Ca biên và ca kiểm thử (Corner Cases)

> ⚠️ **Trạng thái đặc biệt:** mô phỏng RTL **COMPILE_FAIL** — testbench
> `e06_detector_tb.sv` không biên dịch được (`getc` không được Icarus hỗ trợ). Phán xử đầy
> đủ ở **[`../05_VERIFICATION/known_issues.md`](../05_VERIFICATION/known_issues.md)**.
>
> ⟹ Mọi ca liệt kê dưới đây là ca **đã được viết** trong testbench, **chưa** ca nào được
> **chạy**. Chỉ mô hình Python (`reference_model.py`) là có kết quả thật.

---

## 1. Ca bắt buộc của Charter mục 8 — vì sao từng ca

Charter mục 8: *chuỗi có mẫu ở đầu, giữa, cuối · hai mẫu chồng lấn `1011011010` · chuỗi
không có mẫu*.

| Ca | Chuỗi | Lý do **kỹ thuật** | Trong TB? | Trong Python? | **Đã chạy?** |
|---|---|---|:-:|:-:|:-:|
| **C-1 · Mẫu ở ĐẦU** | `10110` | Ca **biên khởi tạo**: mẫu khớp ngay khi cửa sổ vừa đủ 5 bit đầu tiên sau reset. Nếu RTL đòi "nạp đủ cửa sổ rồi mới so sánh" (ví dụ thêm cờ `window_full`), ca này sẽ **trượt** — và **chỉ ca này** bắt được. | ✅ dòng 42 | ✅ `detect("10110",True)==[5]` | ❌ TB / ✅ Python |
| **C-2 · Mẫu ở CUỐI** | `0010110` | Kiểm mạch **dịch đúng** qua nhiều chu kỳ không khớp trước khi khớp. Hai bit `00` dẫn đầu buộc cửa sổ phải trôi qua 2 trạng thái vô nghĩa. | ✅ dòng 43 | ✅ `[7]` | ❌ / ✅ |
| **C-3 · KHÔNG có mẫu** | `000000` | Ca **âm tính**. Không có ca âm thì một DUT luôn bật `match` vẫn "PASS" mọi ca dương tính. Bắt buộc phải có. | ✅ dòng 44 | ✅ `[]` | ❌ / ✅ |
| **C-4 · Hai mẫu CHỒNG LẤN** | `1011011010`, `overlap_en=1` | **Ca lõi của đề.** Xem §1.1. | ✅ dòng 48 | ✅ `[5, 8]` | ❌ / ✅ |
| **C-5 · KHÔNG chồng lấn** | `1011011010`, `overlap_en=0` | Cùng chuỗi, khác chế độ ⟹ **cô lập được đúng tác dụng của `overlap_en`**. Nếu dùng hai chuỗi khác nhau thì không kết luận được điều gì. | ✅ dòng 52 | ✅ `[5]` | ❌ / ✅ |

> **"Mẫu ở giữa"** không có ca riêng, nhưng được phủ bởi C-4: mẫu thứ hai trong
> `1011011010` kết thúc ở bit 8/10 — tức **nằm giữa chuỗi**.

### 1.1 Vì sao chuỗi `1011011010` — Charter mục 2, câu 3

> *"Chuỗi `1011011010` kiểm được điều gì mà chuỗi đơn lẻ không kiểm được?"*

Chuỗi này được chọn **rất có chủ đích**. Nó chứa **hai** thể hiện của mẫu `10110`, ở vị trí
5 và 8 — **cách nhau đúng 3 bit**, tức là **chồng lấn 2 bit**:

```
  vị trí :  1  2  3  4  5  6  7  8  9 10
  bit    :  1  0  1  1  0  1  1  0  1  0
  mẫu 1  : [1  0  1  1  0]                 ← khớp tại bit 5
  mẫu 2  :           [1  1  0  ...]
             thực tế:  1  0  1  1  0       ← khớp tại bit 8
                      └──┬──┘
                    2 bit DÙNG CHUNG (bit 6, 7 thuộc cả hai? không —
                    chính xác: bit 4,5 của mẫu 1 trùng vùng mẫu 2)
```

Chuỗi trạng thái thật (tính từ RTL, `history[3:0]`, bắt đầu `0000`):

| Bit # | `bit_in` | `history` trước | `next_window` | Khớp? | `history` sau (chồng lấn) |
|---:|:-:|---|---|:-:|---|
| 1 | 1 | `0000` | `00001` | | `0001` |
| 2 | 0 | `0001` | `00010` | | `0010` |
| 3 | 1 | `0010` | `00101` | | `0101` |
| 4 | 1 | `0101` | `01011` | | `1011` |
| **5** | 0 | `1011` | **`10110`** | ✅ **MATCH** | `0110` |
| 6 | 1 | `0110` | `01101` | | `1101` |
| 7 | 1 | `1101` | `11011` | | `1011` |
| **8** | 0 | `1011` | **`10110`** | ✅ **MATCH** | `0110` |
| 9 | 1 | `0110` | `01101` | | `1101` |
| 10 | 0 | `1101` | `11010` | | `1010` |

**Bốn điều chuỗi này kiểm được mà chuỗi đơn lẻ KHÔNG kiểm được:**

| # | Kiểm được điều gì | Vì sao chuỗi đơn lẻ không kiểm được |
|---|---|---|
| 1 | **Mạch không "kẹt" sau lần khớp đầu** | Chuỗi một mẫu dừng lại ngay sau khi khớp — không biết mạch còn hoạt động không |
| 2 | **Cửa sổ được tái sử dụng đúng ở chế độ chồng lấn** | Sau khớp, `history = 0110`; mẫu thứ hai **dùng lại** 2 bit này. Chỉ chuỗi chồng lấn mới kiểm được |
| 3 | **`overlap_en` thật sự có tác dụng** (đối chiếu C-4 vs C-5: `[5,8]` vs `[5]`) | Cần **cùng một chuỗi, hai chế độ**; một mẫu đơn cho kết quả giống nhau ở cả hai chế độ |
| 4 | **INV-4: `match` không lên hai chu kỳ liên tiếp**, và khoảng cách tối thiểu là **3 bit** | Cần ít nhất hai lần khớp mới đo được khoảng cách |

> **Đây chính là lý do Charter đặt chuỗi này vào danh mục bắt buộc.** Nó là *chuỗi ngắn
> nhất* kiểm được cả bốn điều trên. Thiết kế một vector kiểm thử tốt là như vậy: **một chuỗi
> 10 bit làm việc của bốn ca**.

### 1.2 Tính chất định lượng: khoảng cách tối thiểu = **3 bit**

Chứng minh (chi tiết ở `functional_spec.md` §7.3): sau khớp chồng lấn, `history = 0110`.
Cần trở lại `1011` để khớp lần nữa:
- sau 1 bit: `110·` — sai ngay bit đầu (cần `1`, có `1`... nhưng vị trí 2 cần `0`, có `1`) ❌
- sau 2 bit: `10··` — cần `1011`: hai bit tự do `b₁b₂` phải là `11` ⟹ **khả dĩ**
- rồi cần `bit_in = 0` ⟹ **tổng 3 bit**

Kết quả `[5, 8]` của `reference_model.py` xác nhận: `8 − 5 = 3`. ✅

## 2. Ca tự xây dựng đã có trong testbench

| Ca | Chuỗi | Loại | Lý do kỹ thuật |
|---|---|---|---|
| **C-6** | `"1011"` | **Ca biên độ dài** — chuỗi **ngắn hơn mẫu** | Cửa sổ không bao giờ đủ 5 bit *mới*. Kiểm rằng mạch **không** khớp non. Nếu logic so sánh chỉ nhìn 4 bit (quên `bit_in`), ca này sẽ khớp sai. |
| **C-7** | `"11111"` | **Ca biên giá trị** — toàn `1` | Đối xứng với C-3 (toàn `0`). Hai ca này phủ **hai góc** của không gian đầu vào. Bắt được lỗi so sánh ngược cực (`== 5'b01001`). |
| **C-8** | `"101100"` | **Ca gần khớp** — mẫu rồi thêm 2 bit | Kiểm `match` **hạ xuống đúng 1 chu kỳ sau** khi khớp (INV-4), và mạch tiếp tục hoạt động bình thường sau đó. |

Charter mục 8 yêu cầu **≥ 2 ca tự xây dựng, có ca biên**. Có **3** (C-6…C-8), trong đó C-6
và C-7 là ca biên. ⟹ REQ-E06-011 **đã được viết**, nhưng **chưa được chạy** (COMPILE_FAIL).

## 3. Phân loại ca theo tiêu chí kỹ thuật riêng của E06

Tiêu chí tự nhiên của một bộ dò mẫu là **mức độ "gần khớp" của cửa sổ** — tức số bit trùng
với mẫu tính từ bên phải. Đây là khái niệm *prefix/suffix* của lý thuyết otomat.

### Trục A — độ sâu "gần khớp"

| Lớp | Cửa sổ | Ý nghĩa | Ca phủ |
|---|---|---|---|
| A-0 | 0 bit trùng hậu tố mẫu | xa mẫu | C-3 (`000000`) |
| A-1 | `····1` | trùng 1 bit? (`10110` kết bằng `0`) — thực ra `····0` | C-3, mọi ca |
| A-2 | `···10` | trùng 2 bit cuối | C-1 bit 4–5 |
| A-3 | `··110` | trùng 3 | C-4 bit 3–5 |
| A-4 | `·1011`→ chờ `0` | **trùng 4 — sắp khớp** | C-1 bit 4, C-6 (`1011`, kết thúc ở đây!) |
| A-5 | `10110` | **KHỚP** | C-1, C-2, C-4, C-5, C-8 |

> **C-6 (`"1011"`) dừng đúng ở lớp A-4** — chuỗi kết thúc khi mạch "sắp khớp". Đây là ca
> biên **được thiết kế rất khéo**: nó kiểm rằng mạch **không đoán trước**, phải có đủ bit
> thứ 5 mới bật `match`.

### Trục B — cấu hình điều khiển

| Lớp | `bit_valid` | `overlap_en` | Có khớp? | Phủ? | Ca |
|---|:-:|:-:|:-:|:-:|---|
| B-I | 1 | 1 | không | ✅ (viết) | C-3, C-6, C-7 |
| B-II | 1 | 1 | **có** | ✅ (viết) | C-1, C-2, C-4, C-8 |
| B-III | 1 | **0** | **có** | ✅ (viết) | **C-5** |
| B-IV | 1 | 0 | không | ✅ (viết) | C-5 (các bit không khớp) |
| B-V | **0** | × | × | ❌ **KHÔNG PHỦ** | — |

**B-V là lỗ hổng độ phủ thật:** testbench **luôn** đặt `bit_valid = 1` trong `send_bit`
(dòng 19) và chỉ hạ xuống 0 ở cuối `send_stream` — **mà không có sườn clock nào lấy mẫu giá
trị 0 đó** (xem §5, M-2). ⟹ **Nhánh `if (bit_valid)` sai của RTL chưa bao giờ được chạy.**

## 4. Ca **KHÔNG áp dụng** cho E06 — và vì sao

| Ca | Vì sao không áp dụng |
|---|---|
| **Mẫu lập trình được** (đổi `10110` lúc chạy) | Charter mục 3: **ngoài phạm vi**. Và về phần cứng, mẫu nằm trong **hình dạng cổng** (`nand4b_1 _15_` với chân `A_N`), không trong thanh ghi ⟹ **không thể** đổi lúc chạy. |
| **Nhiều mẫu cùng lúc** | Ngoài phạm vi. Cần nhân bản logic so sánh cho mỗi mẫu. |
| **Mẫu có ký tự đại diện** (wildcard) | Ngoài phạm vi. Cần đổi `==` thành so sánh có mặt nạ. |
| **Quét toàn bộ 2ⁿ chuỗi độ dài n** | Không khả thi và **không cần**: cửa sổ chỉ có **16 trạng thái** (`history[3:0]`) × 2 giá trị `bit_in` = **32 tổ hợp**. Một ca đi hết 32 tổ hợp là đủ phủ **toàn bộ** hàm chuyển. Xem §5.1. |
| **Ca trạng thái bất hợp lệ** | **Không tồn tại** — cả 16 giá trị `history[3:0]` đều hợp lệ và đạt tới được (`functional_spec.md` §7.4). Khác hẳn E04 (8 trạng thái `count` bất hợp lệ). |
| **Ca CDC** | Một miền clock duy nhất. CDC là đề **J11**. |
| **Ca mẫu bắt đầu bằng `0`** (ví dụ `01101`) | Không áp dụng cho E06 vì mẫu đã chốt là `10110`. **Nhưng** đây là ca cực kỳ đáng bàn về mặt lý thuyết — xem `functional_spec.md` §7.5: cách xoá-về-0 sẽ **sai** với mẫu như vậy. |

### 4.1 Một ca đủ để phủ **toàn bộ** hàm chuyển — chuỗi De Bruijn

Vì trạng thái chỉ có 16 giá trị và mỗi trạng thái có 2 cung ra, **toàn bộ hàm chuyển có
đúng 32 cạnh**. Một **chuỗi De Bruijn B(2,5)** độ dài `2⁵ + 4 = 36` bit đi qua **mọi** cửa
sổ 5 bit đúng **một lần** ⟹ phủ 100 % hàm chuyển, bao gồm cả `10110`.

```
Chuỗi De Bruijn B(2,5), độ dài 36 (một trong nhiều chuỗi hợp lệ):
  00000100011001010011101011011111 0000
```
⚠️ Chuỗi trên là **ví dụ minh hoạ khái niệm**, **chưa được kiểm chứng** trong hồ sơ này —
cần sinh và kiểm bằng công cụ trước khi dùng làm ca kiểm thử.

> **Giá trị dạy học:** đây là ví dụ hiếm hoi mà **độ phủ 100 % là khả thi và chứng minh
> được**, nhờ không gian trạng thái nhỏ. Với E04 (13 FF, 8192 trạng thái) hay E05 (17 FF)
> thì không thể.

## 5. Ca CÒN THIẾU

| # | Ca thiếu | INV không kiểm | Hậu quả |
|---|---|---|---|
| **M-0** | ⚠️ **TẤT CẢ** — testbench **không biên dịch được** | INV-1…INV-8 | **Không một ca nào được chạy.** Xem `known_issues.md` |
| **M-1** | Không có ca `bit_valid = 0` **được lấy mẫu** (lớp B-V) | INV-1 | Nhánh "đóng băng" của RTL chưa từng chạy. Một DUT bỏ qua `bit_valid` hoàn toàn vẫn sẽ PASS |
| **M-2** | **Các chuỗi bị NỐI LIỀN nhau** | — | Xem §5.2 — làm sai ý đồ ca C-1 ("mẫu ở đầu") |
| **M-3** | Không có ca **reset giữa chuỗi** | INV-6 | Không biết mạch thoát sạch khi bị reset ở giữa |
| **M-4** | Không quan sát `history` từ testbench | INV-3 | Không kiểm trực tiếp được "xoá về 0" ở chế độ không chồng lấn — chỉ suy gián tiếp từ số lần `match` |
| **M-5** | Golden model SV **không độc lập** với DUT | — | *Common-mode failure* — xem §5.3 |
| **M-6** | Mô hình Python **không được đồng mô phỏng** | — | Mô hình thực sự độc lập duy nhất lại chỉ chạy riêng, không đối chiếu từng chu kỳ với RTL |

### 5.1 M-2 chi tiết: các chuỗi bị nối liền

```systemverilog
task send_bit(input logic b);
    begin
        bit_in = b;  bit_valid = 1'b1;      // NÂNG bit_valid
        @(posedge clk); #1;  assert(...);
    end
endtask

task send_stream(input string s);
    begin
        for (...) send_bit(...);
        bit_valid=1'b0;                      // HẠ bit_valid ở cuối
    end
endtask
```

Sau `send_stream` cuối cùng, `bit_valid` xuống 0 tại `t = sườn + 1ns`. Lời gọi
`send_stream` **tiếp theo** nâng nó lên 1 **ngay lập tức** (cùng thời điểm mô phỏng, trước
sườn kế tiếp). ⟹ **Không có sườn clock nào lấy mẫu `bit_valid = 0`.**

Hệ quả: `history` **không** được xoá giữa hai chuỗi. Ví dụ C-2 (`"0010110"`) thực ra chạy
với `history = 0110` còn sót từ C-1 (`"10110"`), chứ không phải `0000`.

| | Mô hình Python | Testbench SV |
|---|---|---|
| Giữa hai lời gọi | `window = ""` — **khởi tạo lại** | `history` **giữ nguyên** |
| Ca "mẫu ở đầu" có thật sự "ở đầu"? | ✅ Có | ❌ **Không** — có 4 bit lịch sử |

> ⚠️ **Nhưng mô phỏng vẫn sẽ PASS** (nếu biên dịch được), vì golden model SV chịu **cùng
> một dòng bit** nên hai bên vẫn khớp. Đây là loại lỗ hổng mà **so sánh với golden model
> không bao giờ bắt được** — chỉ đọc mã mới thấy.

Ảnh hưởng bị **giới hạn ở 4 bit đầu** mỗi chuỗi: từ bit thứ 5 trở đi, cửa sổ hoàn toàn do
chuỗi mới quyết định. Với các chuỗi trong testbench, đã kiểm tay: **không có khớp giả nào**
phát sinh (xem bảng §1.1 và tính tương tự cho các chuỗi khác).

Bản vá: xem `known_issues.md` §4.4.

### 5.2 M-5 chi tiết: golden model SV gần như là bản sao của DUT

| | `e06_detector.sv` | `e06_reference.sv` |
|---|---|---|
| Cửa sổ | `logic [4:0] history` | `logic [4:0] hist` |
| Cập nhật | `{history[3:0], bit_in}` | `{hist[3:0], bit_in}` |
| So sánh | `== 5'b10110` | `== 5'b10110` |
| Xoá | `history <= 5'b00000` | `hist <= 5'b0` |

**Cùng thuật toán, cùng cấu trúc, chỉ khác tên biến.** Nếu ý tưởng gốc sai, cả hai cùng sai.
Mô hình thực sự độc lập là `reference_model.py` — dùng chuỗi ký tự và `window = ""` (rỗng)
thay vì `5'b0`. **Chính sự khác biệt đó** mới là thứ phát hiện được bẫy ở
`functional_spec.md` §7.5 (xoá-về-0 chỉ an toàn khi mẫu bắt đầu bằng `1`).

⟹ **Đề xuất (chưa áp dụng):** đồng mô phỏng mô hình Python qua DPI/VPI, hoặc ít nhất sinh
vector kỳ vọng từ Python rồi nạp vào testbench SV bằng `$readmemb`.

## 6. Ca cần bổ sung khi chuyển sang gate-level / post-layout

| Tầng | Ca phải thêm | Vì sao chỉ ở tầng đó |
|---|---|---|
| **L4 · gate-level** | ⚠️ **ĐIỀU KIỆN TIÊN QUYẾT: sửa lỗi biên dịch trước** (`known_issues.md` §4) | Không có testbench chạy được thì không có gì để chạy trên netlist |
| **L4** | Chạy lại C-1…C-8 trên `netlist.v` | Đặc biệt quan trọng với E06: Yosys đã **loại bỏ `history[4]`** và **bỏ nhánh xoá của `history[0]`, `history[3]`**. Cần chứng minh các tối ưu đó **không đổi chức năng** |
| **L4** | Ca **X-propagation sau power-up** | 5 ô nhớ là `dfxtp_1` **không có chân reset** ⟹ sau power-up thật, `history` bất định. `X` sẽ tồn tại ≤ 4 chu kỳ rồi trôi ra — nhẹ hơn E05 (nơi `X` lan qua feedback) |
| **L4** | Ca kiểm **`mux2i_1 _17_`** (ô mux có đầu ra đảo) | Yosys dùng mux **inverting**; cần xác nhận mô hình mô phỏng khớp mô hình timing |
| **L5 · post-layout (SDF)** | Ca **hold** trên chuỗi dịch `history[k] → history[k+1]` | `timing_report_min.txt`: `_28_/Q → _22_ → _24_ → _29_/D`, arrival **0,40 ns**, hold slack **0,46 ns**. Đường ngắn nhất ⟹ nhạy nhất với skew sau CTS |
| **L5** | Ca đo **glitch trên `match`** | `match` là đầu ra **đã chốt** (Moore) nên **không** glitch theo `bit_in` — nhưng đường `_26_/Q → match` (reg→out, arrival 0,26 ns) cần kiểm với tải ngoài thật |
| **L5** | Đo công suất với VCD dòng bit thật | 2,35e-05 W hiện tại dùng hoạt động **mặc định**. Dòng bit thật (ví dụ dữ liệu mã hoá) có thống kê chuyển mạch khác hẳn |

## 7. Bảng tổng kết độ phủ

| Tiêu chí | Đã **viết** | Đã **chạy** |
|---|---|---|
| Ca bắt buộc Charter mục 8 | **5/5** ✅ (C-1…C-5) | **0/5** ❌ (COMPILE_FAIL) |
| Ca tự xây dựng (yêu cầu ≥ 2) | **3** ✅ (C-6…C-8) | **0** ❌ |
| Lớp "gần khớp" (trục A) | A-0…A-5 đầy đủ | — |
| Cấu hình điều khiển (trục B) | **4/5** (thiếu B-V `bit_valid=0`) | — |
| Invariant INV-1…INV-8 | không assertion tường minh nào | **0** |
| Trạng thái `history` | 16/16 hợp lệ, **không có trạng thái chết** | — |
| Mô hình Python độc lập | ✅ | ✅ **PASS** — `[5,8]` và `[5]` |
| Mô hình SV | ✅ có, nhưng **không độc lập** (M-5) | ❌ |
| Mức trừu tượng | RTL hành vi | ❌ COMPILE_FAIL · gate-level ⬜ · post-layout ⬜ |

> **Phát biểu trung thực:** E06 có **bộ ca kiểm thử được thiết kế tốt** — đủ 5 ca Charter,
> 3 ca tự xây dựng, chuỗi chồng lấn chọn rất khéo — nhưng **chưa ca nào được chạy**. Giá trị
> của bộ ca đó hiện là **tiềm năng**, không phải **bằng chứng**.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
