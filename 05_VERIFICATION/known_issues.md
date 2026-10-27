# E06 · Phán xử sự cố mô phỏng (Known Issues)

## ✅ Trạng thái: ĐÃ ÁP DỤNG — 2026-09-24

Giảng viên đã duyệt. **Bản vá đã được áp dụng** vào `05_VERIFICATION/testbench/e06_detector_tb.sv`.
Nhật ký chi tiết: `08_ORIGINAL_SOURCE/PATCHLOG.md`.

| Bản vá | Trạng thái | Ghi chú |
|---|:-:|---|
| §4.2 — thay `string`/`getc()` bằng vector đóng gói + độ dài | ✅ ĐÃ ÁP DỤNG | đúng nguyên văn |
| §4.4 — cô lập cửa sổ giữa các chuỗi | ✅ ĐÃ ÁP DỤNG **có sửa** | áp dụng phương án `reset_window` mà chính §4.4 chỉ ra, **không** áp diff `repeat(4)` — vì `bit_valid=0` không xoá `history` (§4.4 tự cảnh báo điều này). Xem PATCHLOG §2. |
| `04_IMPLEMENTATION/rtl/*.sv` | ⬜ **KHÔNG SỬA** | vô can — đã được mô phỏng xác nhận |
| `05_VERIFICATION/golden_model/*` | ⬜ **KHÔNG SỬA** | vô can |
| 3 cảnh báo `sorry:` của Icarus | ⬜ **KHÔNG SỬA** | cảnh báo, không phải lỗi (§1.1) |

**Kết quả xác minh bằng công cụ thật (iverilog 12.0 + Yosys 0.33 + sky130hd):**

| Bước | Trước khi vá | Sau khi vá |
|---|---|---|
| `reference_model.py` | PASS | PASS — `[5, 8]` / `[5]`, mã thoát 0 |
| Biên dịch `iverilog -g2012` | **FAIL** — `1 error(s) during elaboration` | **Sạch** — 0 `error:`, còn 3 `sorry:` vô hại |
| Mô phỏng `vvp` | không chạy được | **PASS** — `E06 TB PASS`, `$finish` tại 706 ns |
| Tổng hợp Yosys | 18 cell / 5 FF / 182,6752 µm² | **18 cell / 5 FF / 182,6752 µm²** (không đổi) |

> **Phán xử §2 đã được mô phỏng chứng minh:** chỉ sửa testbench là đủ ⟹ DUT và golden model
> thật sự vô can. Đồng thời, phát biểu trung thực ở §7 ("bằng chứng mô phỏng RTL chưa tồn
> tại") **nay đã hết hiệu lực** — RTL đã khớp mô hình chuẩn theo từng chu kỳ trên cả tám
> chuỗi, ở cả hai chế độ `overlap_en`.

Phần chẩn đoán bên dưới được **giữ nguyên** làm tài liệu dạy học.

---

> **Trạng thái (nguyên văn lúc chẩn đoán):** mô phỏng RTL **COMPILE_FAIL** — Icarus Verilog dừng ở giai đoạn
> *elaboration*, **không sinh ra file thực thi**, nên **không có `simulation.log`** trong
> hồ sơ (thư mục `05_VERIFICATION/` chỉ có `iverilog_compile.log`).
>
> **Kết luận phán xử (đọc trước):**
> **Lỗi KHÔNG nằm ở DUT, KHÔNG nằm ở mô hình chuẩn.** Đây là **giới hạn công cụ** (Icarus
> Verilog chưa hiện thực phương thức chuỗi `getc` của SystemVerilog), **bộc lộ qua
> testbench**. Thiết kế `e06_detector` **không có lỗi nào được phát hiện** — nó tổng hợp
> sạch (18 cell, 5 FF), STA PASS, và mô hình Python độc lập PASS.

---

## 1. Trích chính xác thông báo lỗi

Nguồn: `05_VERIFICATION/iverilog_compile.log` (nguyên văn, không sửa):

```
/…/runs/E06/work/e06_detector_explicit.sv:12: sorry: constant selects in always_* processes are not currently supported (all bits will be included).
/…/runs/E06/work/e06_detector_tb.sv:31: error: Method getc is not a string method.
/…/runs/E06/work/e06_detector_tb.sv:31: error: Object e06_detector_tb.send_stream.s has no method "getc(...)".
/…/runs/E06/work/e06_detector.sv:13: sorry: constant selects in always_* processes are not currently supported (all bits will be included).
/…/runs/E06/work/e06_reference.sv:12: sorry: constant selects in always_* processes are not currently supported (all bits will be included).
1 error(s) during elaboration.
```

### 1.1 Tách bạch: **1 lỗi** và **3 cảnh báo**

Dòng cuối ghi rõ `1 error(s) during elaboration` — **chỉ một lỗi**. Ba dòng `sorry:` là
**cảnh báo**, không phải lỗi. Phải phân biệt ngay từ đầu, nếu không sẽ đi sai hướng chẩn
đoán.

| Dòng | Loại | File | Ngăn biên dịch? |
|---|---|---|:-:|
| `e06_detector_explicit.sv:12` `sorry:` | ⚠️ **Cảnh báo** | RTL (bản phụ) | ❌ Không |
| **`e06_detector_tb.sv:31` `error: Method getc is not a string method.`** | 🛑 **LỖI** | **Testbench** | ✅ **CÓ** |
| **`e06_detector_tb.sv:31` `error: … has no method "getc(...)"`** | 🛑 **LỖI** (cùng một nguyên nhân) | **Testbench** | ✅ **CÓ** |
| `e06_detector.sv:13` `sorry:` | ⚠️ **Cảnh báo** | RTL (top) | ❌ Không |
| `e06_reference.sv:12` `sorry:` | ⚠️ **Cảnh báo** | Golden model | ❌ Không |

> **Bằng chứng cảnh báo `sorry:` vô hại:** **cùng một cảnh báo đó** xuất hiện trong
> `brief/E04.md` và `brief/E05.md`, và cả hai đề đó **mô phỏng PASS**. E05 thậm chí có
> **12 dòng `sorry:`** mà vẫn `E05 TB PASS`. ⟹ `sorry:` không bao giờ là nguyên nhân
> COMPILE_FAIL.

---

## 2. Phán xử: lỗi nằm ở đâu?

| Ứng viên | Phán xử | Lập luận |
|---|:-:|---|
| **DUT** (`e06_detector.sv`) | ❌ **VÔ CAN** | Chỉ bị cảnh báo `sorry:` ở dòng 13, giống hệt E04/E05 vốn PASS. RTL **tổng hợp sạch** qua Yosys: 18 cell, 5 FF, 182,6752 µm²; STA PASS, slack 8,41 ns. Một module không biên dịch được thì **không thể** tổng hợp được. |
| **Mô hình chuẩn SV** (`e06_reference.sv`) | ❌ **VÔ CAN** | Cùng loại cảnh báo `sorry:` ở dòng 12. Không có `error:` nào. |
| **Mô hình chuẩn Python** (`reference_model.py`) | ❌ **VÔ CAN** | Chạy độc lập, **PASS**: `python_reference_run.log` in `E06 reference model PASS`, `overlap 1011011010 -> [5, 8]`, `nonoverlap 1011011010 -> [5]`. |
| **Testbench** (`e06_detector_tb.sv:31`) | ⚠️ **NƠI LỖI BỘC LỘ** | Dùng `s.getc(i)` — phương thức chuỗi của SystemVerilog. |
| **Giới hạn công cụ** (Icarus Verilog 12.0) | ✅ **NGUYÊN NHÂN GỐC** | `getc` là phương thức **hợp lệ theo chuẩn IEEE 1800** (§6.16.9 *String methods*). Icarus 12.0 **chưa hiện thực** nó. Thông báo `"Method getc is not a string method"` là lời khẳng định của công cụ, **không phải** của chuẩn. |

### 2.1 Vì sao đây là **giới hạn công cụ**, không phải lỗi testbench

Đây là điểm cần lập luận cẩn thận, vì hai cách phán xử dẫn tới hai cách sửa khác nhau.

**Bằng chứng 1 — `getc` là cú pháp hợp chuẩn.**
IEEE 1800 (SystemVerilog) định nghĩa kiểu `string` với các phương thức `len()`, `getc(i)`,
`putc(i,c)`, `substr(a,b)`, `toupper()`, `atoi()`… `getc(i)` trả về **byte thứ `i`** dưới
dạng `byte`. Testbench dùng đúng ngữ nghĩa đó: `s.getc(i) - 48` đổi ký tự `'0'`/`'1'` (mã
ASCII 48/49) thành giá trị `0`/`1`.

**Bằng chứng 2 — Icarus *có* hỗ trợ `len()` nhưng *không* hỗ trợ `getc()`.**
Log **không** báo lỗi nào ở `s.len()` — cũng nằm trên dòng 30–31:
```systemverilog
for (i=0;i<s.len();i=i+1)        // ← s.len() KHÔNG bị báo lỗi
    send_bit(s.getc(i)-48);      // ← s.getc(i) BỊ báo lỗi
```
⟹ Icarus **đã hiện thực một phần** kiểu `string`, nhưng **thiếu** `getc`. Đây là dấu hiệu
kinh điển của *hỗ trợ ngôn ngữ chưa đầy đủ*, không phải của mã sai.

**Bằng chứng 3 — thông báo lỗi tự tố cáo.**
`error: Method getc is not a string method.` — công cụ khẳng định `getc` **không phải** là
phương thức chuỗi. Điều đó **sai theo chuẩn**. Nếu testbench dùng một phương thức không tồn
tại (ví dụ `s.foobar()`), thông báo sẽ giống hệt — nên **chỉ đọc thông báo thì không phân
biệt được**. Phải tra chuẩn mới kết luận được, và chuẩn đứng về phía testbench.

**Bằng chứng 4 — thư mục hồ sơ cho thấy đã có sửa nguồn ở đúng file này.**
`brief/E06.md` mục *"Sua nguon toi thieu da ap dung"* ghi:
> `e06_detector_tb.sv`: *Doi ten instance 'ref' -> 'ref_i' (2 cho): 'ref' la tu khoa
> SystemVerilog, Icarus tu choi.*

⟹ Testbench **đã từng** bị Icarus từ chối một lần vì lý do tương tự (khác biệt giữa chuẩn
và hiện thực), và đã được sửa. Lỗi `getc` là **vấn đề cùng loại, còn sót lại**.

### 2.2 Nhưng phải công bằng với testbench

Dù nguyên nhân gốc là công cụ, **testbench vẫn có phần trách nhiệm**: nó được viết để chạy
trên Icarus Verilog (script `01_run_sim.sh` gọi `iverilog -g2012`), nên việc dùng một tính
năng ngôn ngữ mà công cụ đích không hỗ trợ là **rủi ro có thể tránh được**.

> **Phán xử cân bằng:** *"Cú pháp đúng chuẩn, nhưng sai công cụ đích."*
> Cách sửa đúng vì thế là **sửa testbench** (§4), **không** phải đổi công cụ — vì toàn bộ
> hồ sơ 80 đề đều chạy trên cùng Icarus Verilog 12.0, đổi công cụ sẽ làm mất tính so sánh
> được giữa các đề (`parameters.md` §2).

---

## 3. Giải thích từ mã: vì sao đúng dòng 31 mà không phải chỗ khác

```systemverilog
// e06_detector_tb.sv:27-34
task send_stream(input string s);          // ← kiểu 'string' của SystemVerilog
    integer i;
    begin
        for (i=0;i<s.len();i=i+1)          // dòng 30: len()  → Icarus CHẤP NHẬN
            send_bit(s.getc(i)-48);        // dòng 31: getc() → Icarus TỪ CHỐI  ◀── LỖI
        bit_valid=1'b0;
    end
endtask
```

Testbench chọn cách biểu diễn chuỗi bit bằng **chuỗi ký tự** (`"1011011010"`) vì nó dễ đọc
và khớp trực tiếp với mô hình Python (`detect("1011011010", True)`). Đó là một quyết định
thiết kế **tốt về mặt dạy học** — người đọc thấy ngay chuỗi bit trong mã:

```systemverilog
send_stream("10110");        // mẫu ở đầu
send_stream("0010110");      // mẫu ở cuối
send_stream("000000");       // không có mẫu
send_stream("1011011010");   // hai mẫu chồng lấn
```

Nhưng nó đòi hỏi truy cập **từng ký tự** của chuỗi, và đó chính là chỗ Icarus hụt.

### 3.1 Các cách truy cập ký tự khác cũng không an toàn

| Cách viết | Chuẩn IEEE 1800 | Icarus 12.0 |
|---|:-:|---|
| `s.getc(i)` | ✅ hợp lệ | ❌ **từ chối** (đã chứng minh bằng log) |
| `s[i]` (chỉ số trực tiếp) | ✅ hợp lệ | ⚠️ **không chắc** — chưa có bằng chứng trong hồ sơ này |
| `s.substr(i,i)` | ✅ hợp lệ | ⚠️ **không chắc** — chưa có bằng chứng |
| **Không dùng kiểu `string`** | ✅ Verilog-2005 thuần | ✅ **chắc chắn chạy** |

⚠️ Hồ sơ này **không chạy lại công cụ** (theo quy định), nên **không có bằng chứng** cho hai
hàng giữa. Vì vậy bản vá đề xuất ở §4 chọn hàng cuối — **phương án duy nhất chắc chắn
đúng**.

---

## 4. Bản vá tối thiểu (đề xuất — **CHƯA ÁP DỤNG**)

### 4.1 Nguyên tắc chọn bản vá

| Tiêu chí | Lý do |
|---|---|
| **Không đụng vào RTL** | DUT vô can; sửa RTL là sai địa chỉ |
| **Không đụng vào golden model** | Cũng vô can |
| **Không đổi công cụ** | Phải giữ Icarus 12.0 để số liệu so sánh được giữa 80 đề |
| **Bỏ hẳn kiểu `string`** | Chỉ cách này mới **chắc chắn** chạy, vì không có bằng chứng cho `s[i]`/`substr` |
| **Giữ nguyên mọi ca kiểm thử** | 7 lời gọi `send_stream` phải giữ đúng chuỗi, đúng thứ tự, đúng `overlap_en` |
| **Giữ tính dễ đọc** | Chuỗi bit vẫn phải nhìn thấy được trong mã |

### 4.2 Bản vá dạng diff

```diff
--- a/05_VERIFICATION/testbench/e06_detector_tb.sv
+++ b/05_VERIFICATION/testbench/e06_detector_tb.sv
@@ -27,8 +27,11 @@
-    task send_stream(input string s);
-        integer i;
-        begin
-            for (i=0;i<s.len();i=i+1)
-                send_bit(s.getc(i)-48);
-            bit_valid=1'b0;
-        end
-    endtask
+    // Khong dung kieu 'string' cua SystemVerilog: Icarus Verilog 12.0 chua
+    // hien thuc phuong thuc getc() (IEEE 1800 §6.16.9).
+    // Bieu dien chuoi bit bang vector dong goi + do dai, MSB truoc.
+    task send_stream(input logic [31:0] bits, input integer n);
+        integer i;
+        begin
+            for (i = n-1; i >= 0; i = i - 1)
+                send_bit(bits[i]);
+            bit_valid = 1'b0;
+        end
+    endtask
@@ -41,17 +44,17 @@
         // Official: beginning/end/no match.
-        send_stream("10110");
-        send_stream("0010110");
-        send_stream("000000");
+        send_stream(32'b10110,          5);   // "10110"
+        send_stream(32'b0010110,        7);   // "0010110"
+        send_stream(32'b000000,         6);   // "000000"
 
         // Official overlap stream.
         overlap_en=1;
-        send_stream("1011011010");
+        send_stream(32'b1011011010,    10);   // "1011011010"
 
         // Official non-overlap behavior.
         overlap_en=0;
-        send_stream("1011011010");
+        send_stream(32'b1011011010,    10);   // "1011011010"
 
         // Student boundary cases.
         overlap_en=1;
-        send_stream("1011");
-        send_stream("11111");
-        send_stream("101100");
+        send_stream(32'b1011,           4);   // "1011"
+        send_stream(32'b11111,          5);   // "11111"
+        send_stream(32'b101100,         6);   // "101100"
```

### 4.3 Vì sao bản vá này **bảo toàn ngữ nghĩa**

| Điểm | Chứng minh |
|---|---|
| **Thứ tự bit không đổi** | Vòng `for (i = n-1; i >= 0; i--)` lấy **bit cao nhất trong `n` bit trước**, đúng như `getc(0)` lấy **ký tự trái nhất**. MSB-first ⟺ trái-sang-phải. |
| **Số 0 dẫn đầu được giữ** | Tham số `n` mang độ dài **tường minh**. Ví dụ `"0010110"` (7 ký tự) → `send_stream(32'b0010110, 7)`: hằng `32'b0010110` = 22, nhưng vòng lặp chạy từ `i=6` nên vẫn phát đủ `0,0,1,0,1,1,0`. ⚠️ **Đây là chỗ dễ sai nhất** — nếu quên `n` và dùng độ dài tự suy thì hai số 0 đầu sẽ mất. |
| **Không đổi `send_bit`** | `send_bit` giữ nguyên hoàn toàn, kể cả assertion so với golden model |
| **Không đổi `overlap_en`** | Các lệnh đặt `overlap_en` giữ nguyên vị trí |
| **Dễ đọc** | Chuỗi nhị phân `32'b1011011010` vẫn nhìn ra được, và chú thích giữ lại dạng chuỗi gốc |
| **Chỉ dùng Verilog-2005** | `logic`, `integer`, vector đóng gói, vòng `for` — Icarus hỗ trợ đầy đủ |

### 4.4 Bản vá bổ sung (tuỳ chọn) — khắc phục **một điểm yếu thật** của testbench

Trong lúc đọc mã đã phát hiện thêm một vấn đề **độc lập với lỗi biên dịch**:

```systemverilog
task send_stream(...);
    ...
    bit_valid=1'b0;         // ← ha bit_valid o CUOI stream
endtask
...
send_stream("10110");       // stream 1
send_stream("0010110");     // stream 2  ← bat dau ngay, KHONG co chu ky bit_valid=0 tron ven
```

Giữa hai lời gọi `send_stream`, `bit_valid` được hạ rồi **nâng lại ngay lập tức** (cùng thời
điểm mô phỏng), nên **không có sườn clock nào lấy mẫu `bit_valid = 0`**. ⟹ **`history`
KHÔNG được xoá giữa các chuỗi** — các chuỗi bị **nối liền** thành một dòng bit duy nhất.

| Ảnh hưởng | Mức |
|---|---|
| Có làm mô phỏng FAIL không? | **Không** — golden model SV chịu **cùng một** dòng bit, nên hai bên vẫn khớp |
| Có làm sai **ý đồ** ca kiểm thử không? | ✅ **Có** — ca "mẫu ở đầu chuỗi" thực ra chạy với `history` còn sót từ chuỗi trước |
| Có sai so với mô hình Python không? | ✅ **Có** — Python `detect()` khởi tạo `window = ""` **cho mỗi lời gọi** |
| Ảnh hưởng tới 4 bit đầu mỗi chuỗi | Chỉ 4 bit đầu; từ bit thứ 5 trở đi cửa sổ hoàn toàn do chuỗi mới quyết định |

Bản vá bổ sung:
```diff
     task send_stream(input logic [31:0] bits, input integer n);
         integer i;
         begin
+            // Xoa cua so giua hai chuoi: cap it nhat 4 suon voi bit_valid=0
+            // (4 = so flip-flop history con lai sau tong hop)
+            bit_valid = 1'b0;
+            repeat (4) @(posedge clk);
             for (i = n-1; i >= 0; i = i - 1)
                 send_bit(bits[i]);
             bit_valid = 1'b0;
         end
     endtask
```
⚠️ **Lưu ý:** `bit_valid = 0` làm khối **đóng băng**, nó **không xoá** `history`. Muốn xoá
thật sự phải xung `rst_n`. Bản vá trên chỉ tạo khoảng nghỉ rõ ràng, giúp đọc waveform dễ
hơn; **để cô lập hoàn toàn các chuỗi thì phải reset**:
```systemverilog
task reset_window;
    begin
        bit_valid = 1'b0; rst_n = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
    end
endtask
```

### 4.5 Kiểm chứng bản vá — **chưa thực hiện**

⬜ **Chưa chạy.** Theo quy định của gói hồ sơ, **không chạy lại công cụ** trong bước này.
Để xác nhận bản vá, cần:

```bash
bash 04_IMPLEMENTATION/scripts/01_run_sim.sh
# Ky vong: bien dich sach, in ra "E06 TB PASS", $finish
```

Tiêu chí PASS: (1) không còn dòng `error:` nào; (2) không assertion nào `$fatal`;
(3) in `E06 TB PASS`; (4) số lần `match` lên khớp mô hình Python: `[5, 8]` ở chế độ chồng
lấn và `[5]` ở chế độ không chồng lấn.

---

## 5. Giá trị dạy học của lỗi này

Lỗi `getc` là một **bẫy kinh điển** và rất đáng dạy, vì nó minh hoạ bốn bài học khó dạy
bằng lý thuyết:

### 5.1 "Đúng chuẩn" ≠ "chạy được"

Chuẩn IEEE 1800 là một tài liệu hàng nghìn trang; **không công cụ nào hiện thực đủ 100 %**.
Mọi đội thiết kế thật đều phải chốt một *tập con ngôn ngữ được phép dùng* (language subset)
cho dự án. Bài học: **kiểm tra công cụ đích trước khi dùng tính năng ngôn ngữ cao cấp**,
đặc biệt trong testbench nơi cám dỗ dùng tính năng tiện lợi là lớn nhất.

### 5.2 Đọc log phải **phân biệt `error:` với `sorry:`/`warning:`**

Log E06 có **5 dòng**, nhưng chỉ **2 dòng là lỗi** và chúng là **cùng một nguyên nhân**. Ba
dòng `sorry:` đánh lạc hướng: chúng trỏ vào **RTL và golden model** — nghĩa là người đọc vội
sẽ kết luận "DUT sai". Bằng chứng phản bác nằm ở E04/E05: **cùng cảnh báo đó, mô phỏng
PASS**.

> **Quy tắc:** luôn đọc **dòng cuối** của log trước (`1 error(s) during elaboration`), rồi
> mới lọc ngược lên tìm đúng số lỗi đó.

### 5.3 Một khối **tổng hợp được** thì chắc chắn **biên dịch được**

E06 có netlist đầy đủ (18 cell, 5 FF) và STA PASS. Yosys **phải** phân tích được RTL mới
tổng hợp ra netlist. ⟹ RTL hợp lệ. Đây là một **phép kiểm chéo mạnh** giữa hai công cụ độc
lập: nếu Yosys đọc được mà Icarus không đọc được, thì vấn đề nằm ở **file mà Yosys không
đọc** — tức là **testbench** (Yosys không đọc testbench).

> **Kỹ thuật chẩn đoán tổng quát:** khi mô phỏng fail mà tổng hợp pass, hãy nghi **testbench
> trước tiên**. Khi cả hai cùng fail, hãy nghi **RTL**.

### 5.4 Lỗi biên dịch **che giấu** các vấn đề khác

Vì testbench không chạy, **không một invariant nào** trong `functional_spec.md` §5 được
kiểm. Và trong lúc đọc mã để chẩn đoán, đã phát hiện thêm **hai vấn đề độc lập**:

| # | Vấn đề | Mức | Nguồn |
|---|---|---|---|
| 1 | `history` **không được xoá giữa các chuỗi** — các ca kiểm thử bị nối liền | ⚠️ Làm sai ý đồ ca kiểm thử, **không** làm FAIL | §4.4 |
| 2 | Golden model SV `e06_reference.sv` viết **gần như y hệt** DUT | ⚠️ *Common-mode failure* — xem §5.5 | `corner_cases.md` §5 |

⟹ **Bài học:** lỗi biên dịch không chỉ chặn mô phỏng, nó còn **chặn việc phát hiện những
lỗi khác**. Sửa lỗi biên dịch là **điều kiện cần**, không phải điều kiện đủ.

### 5.5 Mô hình chuẩn SV **không độc lập** với DUT

So sánh hai file:

| | `e06_detector.sv` (DUT) | `e06_reference.sv` (golden SV) |
|---|---|---|
| Biến cửa sổ | `logic [4:0] history` | `logic [4:0] hist` |
| Cập nhật | `next_window = {history[3:0], bit_in}` | `nxt = {hist[3:0], bit_in}` |
| So sánh | `next_window == 5'b10110` | `nxt == 5'b10110` |
| Xoá khi không chồng lấn | `history <= 5'b00000` | `hist <= 5'b0` |
| Chốt `match` | `match <= hit` | `match_ref <= 1'b1` trong nhánh |

**Cùng thuật toán, cùng cấu trúc, chỉ khác tên biến.** Nếu ý tưởng gốc sai (ví dụ: xoá về 0
với một mẫu bắt đầu bằng `0` — xem `functional_spec.md` §7.5), **cả hai cùng sai** và
testbench vẫn PASS.

⟹ Mô hình thực sự độc lập là **`reference_model.py`** (viết bằng Python, dùng chuỗi ký tự
và `window = ""` chứ không phải `5'b0`) — và nó **không được đồng mô phỏng**, chỉ chạy riêng.
Đây là hạn chế cần nêu trong kết luận.

---

## 6. Trạng thái của bản vá

| Hạng mục | Trạng thái |
|---|---|
| Bản vá §4.2 (thay `string` bằng vector) | ⬜ **CHƯA ÁP DỤNG** |
| Bản vá §4.4 (xoá cửa sổ giữa các chuỗi) | ⬜ **CHƯA ÁP DỤNG** |
| File `e06_detector_tb.sv` trong hồ sơ | ✅ **Giữ nguyên bản gốc của thầy** |
| File RTL `e06_detector.sv` | ✅ **Giữ nguyên** — không có lý do sửa |
| File golden `e06_reference.sv` | ✅ **Giữ nguyên** — không có lý do sửa |

> ⚠️ **Mọi bản vá trong tài liệu này CHƯA được áp dụng vào hồ sơ.** Chúng là **đề xuất**,
> cần **thầy duyệt** trước khi sửa. Lý do giữ nguyên: (a) RTL và golden model vô can, không
> được đụng tới; (b) testbench là tài liệu gốc của thầy, việc sửa nó làm thay đổi bằng
> chứng đã thu được; (c) chưa chạy lại công cụ nên **chưa có bằng chứng** bản vá thực sự
> chạy được.

## 7. Những gì E06 **vẫn** chứng minh được dù mô phỏng fail

Quan trọng để không đánh giá thấp hồ sơ:

| Đã chứng minh | Bằng chứng |
|---|---|
| Thuật toán đúng | `python_reference_run.log`: `[5, 8]` (chồng lấn) và `[5]` (không chồng lấn) — **PASS** |
| RTL hợp lệ cú pháp và **tổng hợp được** | `yosys.log`, `synth_stat.txt`: 18 cell, 5 FF, 182,6752 µm² |
| RTL đúng phân loại **Tuần tự** | 5 cell tuần tự; công suất Sequential **92,5 %** |
| Logic phát hiện mẫu đúng | **Khai triển đại số netlist** khớp chính xác mẫu `10110` — xem `functional_spec.md` §3 |
| Timing đạt (sau tổng hợp) | `bit_in → _28_`, arrival 1,47 ns, slack **8,41 ns**, WNS/TNS = 0,00 |

| **Chưa** chứng minh | Vì sao |
|---|---|
| **RTL khớp golden model theo từng chu kỳ** | ❌ Testbench không biên dịch |
| Bất kỳ invariant nào (INV-1…INV-8) | ❌ như trên |
| Ba ca bắt buộc Charter mục 8 | ❌ như trên — `test_matrix.csv` ghi `XEM known_issues.md` |
| Hai ca tự xây dựng (REQ-E06-011) | ❌ như trên |

> **Phát biểu trung thực nhất về E06:**
> *"Thuật toán đã được kiểm chứng độc lập bằng Python; RTL đã được chứng minh tương đương
> với thuật toán đó bằng **đọc và khai triển netlist**, chứ **chưa** bằng mô phỏng. Bằng
> chứng mô phỏng RTL **chưa tồn tại** do một giới hạn của công cụ nằm trong testbench."*

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-E06-010, REQ-E06-012.*
