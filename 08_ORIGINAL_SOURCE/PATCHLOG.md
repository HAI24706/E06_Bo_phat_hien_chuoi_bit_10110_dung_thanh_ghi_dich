# E06 · Nhật ký vá (PATCHLOG)

**Ngày vá:** 2026-09-24 · **Người duyệt:** giảng viên đã duyệt áp dụng toàn bộ bản vá

## 1. Tóm tắt

| # | File | Loại lỗi | Mô tả một dòng | Ảnh hưởng số liệu |
|---|---|---|---|---|
| P-1 | `05_VERIFICATION/testbench/e06_detector_tb.sv` | Giới hạn công cụ, bộc lộ ở testbench | Bỏ kiểu `string` + `s.getc(i)` (Icarus 12.0 chưa hiện thực), thay bằng vector đóng gói + độ dài tường minh | Không |
| P-2 | `05_VERIFICATION/testbench/e06_detector_tb.sv` | Lỗi ý đồ ca kiểm thử | `history` không được xoá giữa các chuỗi ⟹ tám ca kiểm thử bị nối liền thành một dòng bit; thêm `reset_window()` để cô lập thật sự | Không |

**Không** bản vá nào chạm vào `04_IMPLEMENTATION/rtl/` hay
`05_VERIFICATION/golden_model/`. Phán xử ở `known_issues.md` §2 — "DUT vô can, golden model
vô can, nguyên nhân gốc là giới hạn công cụ" — **được mô phỏng xác nhận**: chỉ sửa testbench
là đủ để mô phỏng PASS.

## 2. Chi tiết từng bản vá

### P-1 — Bỏ `string.getc()` (Icarus Verilog 12.0 chưa hỗ trợ)

**File:** `05_VERIFICATION/testbench/e06_detector_tb.sv` · **Dòng:** 27–34 và 42–58 (bản
gốc) · **Phán xử:** **giới hạn công cụ**, bộc lộ qua testbench — không phải lỗi DUT, không
phải lỗi mô hình chuẩn

**Trước:**
```systemverilog
    task send_stream(input string s);
        integer i;
        begin
            for (i=0;i<s.len();i=i+1)
                send_bit(s.getc(i)-48);
            bit_valid=1'b0;
        end
    endtask
...
        send_stream("10110");
        send_stream("0010110");
        send_stream("000000");
        overlap_en=1;
        send_stream("1011011010");
        overlap_en=0;
        send_stream("1011011010");
        overlap_en=1;
        send_stream("1011");
        send_stream("11111");
        send_stream("101100");
```

**Sau:**
```systemverilog
    // Khong dung kieu 'string' cua SystemVerilog: Icarus Verilog 12.0 chua
    // hien thuc phuong thuc getc() (IEEE 1800 6.16.9).
    // Bieu dien chuoi bit bang vector dong goi + do dai, MSB truoc.
    task send_stream(input logic [31:0] bits, input integer n);
        integer i;
        begin
            reset_window();
            for (i = n-1; i >= 0; i = i - 1)
                send_bit(bits[i]);
            bit_valid = 1'b0;
        end
    endtask
...
        send_stream(32'b10110,          5);   // "10110"
        send_stream(32'b0010110,        7);   // "0010110"
        send_stream(32'b000000,         6);   // "000000"
        overlap_en=1;
        send_stream(32'b1011011010,    10);   // "1011011010"
        overlap_en=0;
        send_stream(32'b1011011010,    10);   // "1011011010"
        overlap_en=1;
        send_stream(32'b1011,           4);   // "1011"
        send_stream(32'b11111,          5);   // "11111"
        send_stream(32'b101100,         6);   // "101100"
```

**Vì sao:** `getc()` là phương thức hợp chuẩn IEEE 1800 §6.16.9, nhưng Icarus 12.0 từ chối
(`error: Method getc is not a string method.`). Icarus **có** `len()` mà **thiếu** `getc()`
— dấu hiệu điển hình của hỗ trợ ngôn ngữ chưa đầy đủ. Không đổi công cụ (toàn bộ 80 đề phải
chạy trên cùng Icarus 12.0 để số liệu so sánh được), không đụng RTL/golden (vô can) ⟹ chỉ
còn cách viết lại testbench bằng Verilog-2005 thuần.

**Bảo toàn ngữ nghĩa:** vòng `for (i = n-1; i >= 0; i--)` lấy bit cao nhất trong `n` bit
trước, đúng như `getc(0)` lấy ký tự trái nhất (MSB-first ⟺ trái-sang-phải). Tham số `n`
mang độ dài **tường minh** nên số 0 dẫn đầu được giữ: `32'b0010110` có giá trị 22 nhưng vòng
lặp chạy từ `i=6` nên vẫn phát đủ `0,0,1,0,1,1,0`. `send_bit` và các lệnh đặt `overlap_en`
giữ nguyên hoàn toàn.

**Hệ quả:** biên dịch sạch (không còn `error:`), mô phỏng chạy tới `$finish` và in
`E06 TB PASS`.

### P-2 — Cô lập thật sự cửa sổ `history` giữa các chuỗi

**File:** `05_VERIFICATION/testbench/e06_detector_tb.sv` · **Phán xử:** lỗi ý đồ ca kiểm
thử ở **testbench**

**Trước:** `send_stream` chỉ hạ `bit_valid` ở **cuối** chuỗi, rồi lời gọi kế tiếp nâng lại
ngay trong cùng thời điểm mô phỏng ⟹ **không sườn clock nào lấy mẫu `bit_valid = 0`** ⟹
`history` không bao giờ được xoá và tám chuỗi bị nối liền thành một dòng bit duy nhất.

**Sau:**
```systemverilog
    // Co lap that su giua hai chuoi: 'bit_valid=0' chi lam khoi dong bang,
    // KHONG xoa history. Phai xung rst_n moi xoa duoc cua so.
    task reset_window;
        begin
            bit_valid = 1'b0; rst_n = 1'b0;
            repeat (2) @(posedge clk);
            rst_n = 1'b1;
        end
    endtask
```
và `send_stream` gọi `reset_window()` ở đầu mỗi chuỗi.

**Vì sao:** mô hình Python `detect()` khởi tạo `window = ""` **cho mỗi lời gọi**. Nếu
testbench không xoá cửa sổ, ca "mẫu ở đầu chuỗi" thực ra chạy với 4 bit còn sót từ chuỗi
trước ⟹ ca kiểm thử **không kiểm thứ nó tuyên bố kiểm**.

**Hệ quả:** tám ca kiểm thử nay độc lập nhau và khớp đúng ngữ nghĩa của mô hình Python.
Lỗi này **không** gây FAIL (DUT và golden SV chịu cùng một dòng bit nên vẫn khớp nhau), nên
nó chỉ lộ ra khi đọc mã — đây chính là lý do §5.4 của `known_issues.md` nói "lỗi biên dịch
che giấu các vấn đề khác".

### Chênh lệch so với bản vá đã soạn trong `known_issues.md`

**P-1** được áp dụng **đúng nguyên văn** như §4.2.

**P-2 khác với bản vá dạng diff ở §4.4, và cố ý như vậy.** Diff ở §4.4 đề xuất chèn
`bit_valid = 1'b0; repeat (4) @(posedge clk);` vào đầu `send_stream`. Chính §4.4 **tự cảnh
báo** rằng cách đó **không xoá `history`** — `bit_valid = 0` chỉ làm khối đóng băng — và nêu
`reset_window` là cách xoá thật sự. Áp dụng diff nguyên văn sẽ chỉ thêm 4 chu kỳ chết mà
không đạt mục tiêu đã tuyên bố. Vì vậy đã áp dụng **phương án `reset_window` mà chính §4.4
chỉ ra**, theo PATCH_SPEC §1.3 (bản vá đã soạn thiếu thì sửa cho đúng và ghi rõ chênh lệch).

Ba dòng cảnh báo `sorry: constant selects in always_* processes…` ở
`e06_detector_explicit.sv:12`, `e06_detector.sv:13`, `e06_reference.sv:12` **vẫn còn** sau
khi vá và **không được sửa** — đúng như phán xử §1.1: đó là **cảnh báo**, không phải lỗi,
không ngăn biên dịch, và cùng cảnh báo đó xuất hiện ở E04/E05 vốn mô phỏng PASS. Sửa chúng
sẽ là thay đổi RTL không có lý do.

## 3. Kết quả xác minh sau khi vá

| Bước | Trước khi vá | Sau khi vá |
|---|---|---|
| Mô hình chuẩn Python | PASS (`[5, 8]` / `[5]`) | PASS — `E06 reference model PASS`, `overlap 1011011010 -> [5, 8]`, `nonoverlap 1011011010 -> [5]`, mã thoát 0 |
| Biên dịch | **FAIL** — `1 error(s) during elaboration` (`getc` ×2 cùng nguyên nhân, dòng 31) | **Sạch** — 0 `error:`, còn 3 cảnh báo `sorry:` vô hại (đã phán xử) |
| Mô phỏng | **Không chạy được** (không có `simulation.log`) | **PASS** — `E06 TB PASS`, `$finish` tại 706 ns, không `ERROR`/`FATAL`/`mismatch` |
| Tổng hợp | 18 cell / 5 FF / 182,6752 µm² | **18 cell / 5 FF / 182,6752 µm²** (không đổi — không bản vá nào chạm RTL) |

Số FF = 5 × `sky130_fd_sc_hd__dfxtp_1`. Thư viện: `sky130hd.lib`.

> **Điều E06 nay chứng minh được mà trước đây không:** RTL khớp mô hình chuẩn **theo từng
> chu kỳ** trên cả tám chuỗi, ở cả hai chế độ `overlap_en`. Phát biểu trung thực ở
> `known_issues.md` §7 ("bằng chứng mô phỏng RTL chưa tồn tại") **đã hết hiệu lực**.

Lệnh đã chạy để xác minh:

```bash
D=<thu muc de E06>
T=$(mktemp -d)
LIB=/tmp/claude-0/-home-claude/00931947-5415-56ee-a8ea-9708a0fd622a/scratchpad/sky130hd.lib

python3 $D/05_VERIFICATION/golden_model/reference_model.py

iverilog -g2012 -o $T/sim.vvp \
   $D/04_IMPLEMENTATION/rtl/*.sv \
   $D/05_VERIFICATION/golden_model/*.sv \
   $D/05_VERIFICATION/testbench/*.sv
cd $T && vvp sim.vvp | tail -20

yosys -Q -p "read_verilog -sv $D/04_IMPLEMENTATION/rtl/*.sv; \
   hierarchy -check -top e06_detector; proc; opt; fsm; opt; memory; opt; techmap; opt; \
   dfflibmap -liberty $LIB; abc -liberty $LIB; setundef -zero; splitnets; opt_clean -purge; \
   stat -liberty $LIB"
```

## 4. Cách quay lui

```bash
cp 08_ORIGINAL_SOURCE/rtl/*            04_IMPLEMENTATION/rtl/
cp 08_ORIGINAL_SOURCE/golden_model/*   05_VERIFICATION/golden_model/
cp 08_ORIGINAL_SOURCE/testbench/*      05_VERIFICATION/testbench/
```

## 5. Việc còn lại

- **Không vá:** mô hình chuẩn SV `e06_reference.sv` vẫn **gần như y hệt** DUT (cùng thuật
  toán, cùng cấu trúc, chỉ khác tên biến — `known_issues.md` §5.5). Đây là *common-mode
  failure*: nếu ý tưởng gốc sai thì cả hai cùng sai và testbench vẫn PASS. **Không sửa** vì
  viết lại golden model theo một thuật toán khác là thay đổi lớn, vượt xa phạm vi "sửa tối
  thiểu", và mô hình thực sự độc lập đã tồn tại (`reference_model.py`). Việc đáng làm là
  **đồng mô phỏng** DUT với mô hình Python (qua VPI/DPI hoặc so log), không phải sửa
  `e06_reference.sv`.
- Cảnh báo `sorry:` của Icarus vẫn còn — cố ý, xem §2.
- `test_matrix.csv`, `verification_report.md`, `README.md` và `limitations.md` còn ghi trạng
  thái COMPILE_FAIL; những file này được sinh lại tự động sau bước vá (PATCH_SPEC §0).

## 6. Áp dụng lại (2026-09-24)

Sau đợt vá ở §1–§5, một bước sinh tài liệu tự động (`generate2.py`) đã **chép đè** mã nguồn
cũ từ `runs/E06/work/` lên `04_IMPLEMENTATION/rtl/`, `05_VERIFICATION/golden_model/` và
`05_VERIFICATION/testbench/`, làm **mất toàn bộ bản vá**. Lỗi của bộ sinh đã được sửa. Mục
này ghi lại việc **áp dụng lại** bản vá, không phải một đợt chẩn đoán mới.

**Đã áp dụng lại:** P-1 và P-2 — cả hai đều nằm trong
`05_VERIFICATION/testbench/e06_detector_tb.sv`, đúng nguyên văn các đoạn "Sau" ở §2.
`04_IMPLEMENTATION/rtl/` và `05_VERIFICATION/golden_model/` **không bị chạm tới** (đúng như
§1: không bản vá nào của E06 đụng RTL), nên việc ghi đè không gây thiệt hại ở hai thư mục
đó và không cần khôi phục gì ở đấy.

**Kết quả xác minh lần này** (iverilog 12.0, Yosys 0.33, `sky130hd.lib`):

| Bước | Kết quả đo lần này | Khớp §3? |
|---|---|:-:|
| Mô hình chuẩn Python | PASS — `E06 reference model PASS`, `overlap 1011011010 -> [5, 8]`, `nonoverlap 1011011010 -> [5]`, mã thoát 0 | ✅ |
| Biên dịch | Sạch — 0 `error:`, còn đúng 3 cảnh báo `sorry:` đã phán xử | ✅ |
| Mô phỏng | **PASS** — `E06 TB PASS`, `$finish` tại 706 ns, không `ERROR`/`FATAL`/`mismatch` | ✅ |
| Tổng hợp, top `e06_detector` | **18 cell / 5 FF (`dfxtp_1`) / 182,6752 µm²** | ✅ |

Số liệu **trùng khớp hoàn toàn** với §3. Không phát hiện chênh lệch nào giữa PATCHLOG và
bản vá áp dụng lại; không phải sửa khác đi ở chỗ nào.
