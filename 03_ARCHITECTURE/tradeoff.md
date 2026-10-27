# E06 · Phân tích đánh đổi (Trade-off)

---

## 0. Số liệu thật — mốc để so sánh

| Chỉ số | Giá trị đo được | Nguồn |
|---|---:|---|
| Số cell | **18** | `synth_stat.txt` |
| Flip-flop | **5** (4 `history` + 1 `match`) | như trên |
| Diện tích | **182,6752 µm²** | như trên |
| Cell cho **so sánh mẫu** | **3** (`nand2b_1` + `nand4b_1` + `nor3_1`) | `netlist.v` `_14_`, `_15_`, `_16_` |
| Cell cho **`overlap_en`** | **2** (`o31ai_1 _19_`, `_22_`) | `netlist.v` |
| Đường tới hạn | `bit_in` → `_28_` (`history[1]`), **3 cell** | `timing_report_max.txt` |
| Data arrival | **1,47 ns** (trong đó **1,00 ns là giả định IO = 68 %**) | như trên |
| Slack setup | **8,41 ns** (chu kỳ giả định 10 ns) | như trên |
| Slack hold nhỏ nhất | **0,46 ns** (`history[1] → history[2]`) | `timing_report_min.txt` |
| WNS / TNS | **0,00 / 0,00** | `wns.txt`, `tns.txt` |
| Công suất | **2,35e-05 W** (tuần tự **92,5 %**, tổ hợp 7,5 %) | `power_report.txt` |
| **Mô phỏng RTL** | ❌ **COMPILE_FAIL** | `iverilog_compile.log` · phán xử: `known_issues.md` |

---

## 1. Đáp án Charter mục 9 — so sánh với cách làm bằng FSM (đề F04)

> *"So sánh cách làm bằng thanh ghi dịch này với cách làm bằng FSM (đề F04). Nêu cách nào
> tốn ít cell hơn và vì sao."*

### 1.1 ⚠️ Trước hết: con số trong `brief/F04.md` **KHÔNG dùng trực tiếp được**

`brief/F04.md` ghi `So cell | 2` và `Dien tich | 86.3328 um2`. **Hai con số này là hiện vật
của cấu trúc phân cấp**, không phải số liệu của một bộ dò mẫu:

```
=== f04_comparison_scaffold ===        ← module TOP mà BRIEF lấy số
   Number of cells:                  2
     f04_mealy_detector              1
     f04_moore_detector              1
   Area for cell type \f04_mealy_detector is unknown!
   Area for cell type \f04_moore_detector is unknown!
```

F04 là một **khung so sánh** chứa **hai** bộ dò mẫu con, và Yosys **không làm phẳng** hệ
phân cấp ⟹ top chỉ có 2 "cell" (hai instance) và **không tính được diện tích** của nó.
Con số `86,3328 µm²` thực ra là diện tích của **riêng `f04_mealy_detector`**.

> **Bài học phương pháp — rất đáng dạy:** trước khi so sánh số liệu giữa hai đề, phải kiểm
> **số đó thuộc về module nào** và **hệ phân cấp đã được làm phẳng chưa**. Chép thẳng
> `So cell = 2` vào báo cáo và kết luận *"FSM chỉ tốn 2 cell, rẻ hơn thanh ghi dịch 9 lần"*
> là sai hoàn toàn — và đó chính là loại sai lầm Charter mục 6 muốn tránh khi đòi nêu
> **điều kiện tạo ra bằng chứng**.

### 1.2 Số liệu đúng — đọc từ `../F04_FSM_phat_hien_chuoi_1011_so_sanh_Mealy_va_Moore/06_GDSII/synthesis/synth_stat.txt`

| Module | Cell | Flip-flop | Diện tích (µm²) | Mẫu |
|---|---:|---:|---:|---|
| `f04_mealy_detector` | **11** | **2** | **86,3328** | `1011` (**4 bit**) |
| `f04_moore_detector` | **20** | **3** | **156,4000** | `1011` (**4 bit**) |
| `f04_comparison_scaffold` (cả hai) | **31** | **5** | 242,7328 (= tổng hai module con) | |
| **`e06_detector`** | **18** | **5** | **182,6752** | **`10110` (5 bit)** |

⚠️ **Lưu ý thêm:** `brief/F04.md` ghi `Flip-flop | 10`, nhưng bảng phân bố cell của chính
BRIEF đó và `synth_stat.txt` phần *design hierarchy* đều cho `dfxtp_1 × 5`. Con số **5** là
con số đúng (2 Mealy + 3 Moore). Đây là **lỗi thứ hai** của cách sinh số liệu tự động cho
một đề phân cấp.

### 1.3 So sánh có điều kiện — **hai đề KHÔNG cùng độ dài mẫu**

| | **E06 · Thanh ghi dịch** | **F04 Moore · FSM** | **F04 Mealy · FSM** |
|---|---:|---:|---:|
| Mẫu | `10110` — **5 bit** | `1011` — **4 bit** | `1011` — **4 bit** |
| Cell | **18** | **20** | **11** |
| Flip-flop | **5** (4 dữ liệu + 1 chốt) | **3** | **2** |
| Diện tích | **182,6752 µm²** | **156,4000 µm²** | **86,3328 µm²** |
| Diện tích / flip-flop | **36,5** | **52,1** | **43,2** |
| Cell / flip-flop | **3,6** | **6,7** | **5,5** |
| Đầu ra | **Moore** (đã chốt) | Moore | **Mealy** (tổ hợp) |
| Trạng thái bất hợp lệ | **0** | có (3 bit, 5 trạng thái ⟹ 3 thừa) | có (2 bit, 4 trạng thái ⟹ 0 thừa) |
| Mô phỏng | ❌ **COMPILE_FAIL** | ❌ **COMPILE_FAIL** | ❌ **COMPILE_FAIL** |

> ⚠️ **Hai đề không so sánh trực tiếp được về con số tuyệt đối** vì mẫu khác độ dài (5 so
> với 4 bit). Phải so bằng **tỷ số** và **quy luật tăng trưởng**, không bằng hiệu số.

### 1.4 Trả lời câu hỏi "cách nào tốn ít cell hơn và **vì sao**"

**Trả lời ngắn: tuỳ độ dài mẫu. Với mẫu ngắn, FSM Mealy rẻ nhất. Với mẫu dài, thanh ghi
dịch thắng — nhưng theo một tiêu chí khác với tiêu chí "số flip-flop".**

**(a) Về số flip-flop — FSM luôn thắng, và khoảng cách tăng theo `N`:**

| Độ dài mẫu `N` | Thanh ghi dịch: `N−1` FF | FSM: `⌈log₂(N+1)⌉` FF | Chênh |
|---:|---:|---:|---:|
| 4 (F04) | 3 | **2** | FSM tiết kiệm 1 |
| **5 (E06)** | **4** | **3** | FSM tiết kiệm 1 |
| 8 | 7 | **4** | FSM tiết kiệm 3 |
| 16 | 15 | **5** | FSM tiết kiệm **10** |
| 32 | 31 | **6** | FSM tiết kiệm **25** |

Thanh ghi dịch tăng **tuyến tính**; FSM tăng **logarit**. Với mẫu dài, FSM thắng áp đảo về
số ô nhớ.

**(b) Về logic tổ hợp — thanh ghi dịch thắng, và số liệu thật xác nhận:**

| | E06 (SR, mẫu 5 bit) | F04 Moore (FSM, mẫu 4 bit) |
|---|---:|---:|
| **Cell / flip-flop** | **3,6** | **6,7** — **gần gấp đôi** |
| **Diện tích / flip-flop** | **36,5 µm²** | **52,1 µm²** — **+43 %** |

Nghĩa là: mỗi ô nhớ của FSM cần **nhiều logic quanh nó hơn** rõ rệt. Lý do bản chất:

| | Thanh ghi dịch | FSM |
|---|---|---|
| Logic next-state | **phép dịch** — bit `k` nhận bit `k−1`, **không tính toán gì** | **bảng chuyển KMP** — mỗi bit trạng thái là hàm của **toàn bộ** trạng thái + đầu vào |
| Logic đầu ra | **một** phép so sánh với hằng (3 cell) | giải mã trạng thái |
| Khi mẫu đổi | chỉ đổi **hằng so sánh** | **tính lại toàn bộ** bảng chuyển bằng tay |

Bằng chứng netlist cho F04 Moore: nó cần `a41oi_1` (cổng 4 đầu vào phức tạp) và **3 ô
`nor3b_1`** cho logic next-state — những cổng mà E06 **không hề có**. E06 chỉ cần
`mux2i_1`, `o31ai_1`, `a21oi_1`, `o211a_1` — các ô đơn giản hơn.

**(c) Kết luận định lượng:**

| Tiêu chí | Cách nào tốn ít hơn | Bằng chứng |
|---|---|---|
| **Số flip-flop** | **FSM** — `⌈log₂(N+1)⌉` so với `N−1` | E06: 5 FF (mẫu 5 bit); F04 Moore: 3 FF (mẫu 4 bit) |
| **Cell / flip-flop** | **Thanh ghi dịch** — 3,6 so với 6,7 (**−46 %**) | `synth_stat.txt` hai đề |
| **Diện tích / flip-flop** | **Thanh ghi dịch** — 36,5 so với 52,1 µm² (**−30 %**) | như trên |
| **Tổng cell cho mẫu 4–5 bit** | **F04 Mealy** (11 cell) < **E06** (18) < **F04 Moore** (20) | như trên |
| **Tổng cell cho mẫu dài (≥ 8 bit)** | **FSM** — vì FF tăng logarit | ⬜ **chưa đo** — cần tổng hợp thêm |
| **Độ an toàn (trạng thái bất hợp lệ)** | **Thanh ghi dịch** — **0** trạng thái bất hợp lệ | `fsm.md` §6 |
| **Công sức thiết kế / rủi ro sai** | **Thanh ghi dịch** — không cần tính bảng chuyển KMP | định tính |

> **Câu trả lời đầy đủ cho Charter mục 9:**
>
> *Với mẫu ngắn (4–5 bit), FSM Mealy rẻ nhất về cell (11 so với 18), vì nó chỉ cần 2 ô nhớ
> và đầu ra tổ hợp. Nhưng tính trên mỗi ô nhớ, thanh ghi dịch rẻ hơn rõ rệt: **3,6 cell/FF
> so với 6,7 cell/FF** của FSM Moore, và **36,5 µm²/FF so với 52,1 µm²/FF** — vì logic
> next-state của thanh ghi dịch là **phép dịch tầm thường**, trong khi FSM cần một bảng
> chuyển tính bằng KMP. Đổi lại, số ô nhớ của thanh ghi dịch tăng **tuyến tính** theo độ dài
> mẫu (`N−1`) còn FSM tăng **logarit** (`⌈log₂(N+1)⌉`), nên với mẫu từ 8 bit trở lên FSM sẽ
> thắng về tổng diện tích.*
>
> ⚠️ **Điều kiện của bằng chứng:** hai đề có **độ dài mẫu khác nhau** (5 so với 4 bit); cả
> hai đều **COMPILE_FAIL** nên **chưa** có bằng chứng chức năng; số liệu F04 phải đọc từ
> `synth_stat.txt` chứ **không** dùng được con số trong BRIEF (§1.1). Điểm giao ở đâu
> (`N` bằng bao nhiêu thì FSM bắt đầu thắng) **⬜ chưa đo** — cần tổng hợp thêm nhiều độ dài
> mẫu.

---

## 2. So sánh kiến trúc: thanh ghi dịch **vs** ba phương án thay thế

| Tiêu chí | **(A) Thanh ghi dịch** *(đã chọn)* | (B) FSM mã hoá tay | (C) FSM one-hot | (D) Bộ so sánh song song trên đệm |
|---|---|---|---|---|
| **Flip-flop (mẫu `N` bit)** | **`N−1`** = 4 | `⌈log₂(N+1)⌉` = 3 | `N+1` = 6 | `N−1` = 4 |
| Cell (E06 đo) | **18** | 20 (F04 Moore, mẫu 4 bit) | ⬜ chưa chạy | ⬜ chưa chạy |
| Diện tích (E06 đo) | **182,6752 µm²** | 156,4 µm² (mẫu 4 bit) | ⬜ | ⬜ |
| Logic next-state | **dịch — tầm thường** | bảng chuyển KMP, **phải tính tay** | dịch vòng — đơn giản | dịch |
| Logic đầu ra | so sánh 5 bit — **3 cell** | giải mã trạng thái cuối | **1 dây** | như (A) |
| Trạng thái bất hợp lệ | **0** | có (3 bit, 5 trạng thái ⟹ 3 thừa) | nhiều (2⁶ − 6 = 58) | **0** |
| Tự phục hồi sau SEU | ✅ **tự động, sau 4 bit** | ❌ cần nhánh `default` | ❌ cần logic riêng | ✅ |
| Đổi mẫu | **đổi 1 hằng số** | tính lại bảng chuyển | tính lại | đổi hằng |
| Mở rộng mẫu dài | FF tăng **tuyến tính** | FF tăng **logarit** ✅ | FF tăng tuyến tính | tuyến tính |
| Phạm vi Charter | ✅ **bắt buộc** (tên đề) | ❌ đó là **đề F04** | ❌ | ❌ |

### 2.1 (B) FSM mã hoá tay — vì sao **không** dùng cho E06

Không phải vì kém, mà vì **ràng buộc đề**: tên đề chốt *"dùng thanh ghi dịch"* (ST-1,
`functional_spec.md` §4), và Charter mục 9 yêu cầu **so sánh** với F04 — nghĩa là hai cách
làm được giao cho **hai đề khác nhau** để đối chiếu.

Nhưng có một lý do kỹ thuật thật: **FSM cần tính bảng chuyển KMP bằng tay**, và đó là chỗ
sinh viên sai nhiều nhất. Ví dụ với mẫu `10110`, từ trạng thái `S4` (`1011`) nếu nhận `1`
thì **không** về `S0` — phải về `S3` (`101`), vì hậu tố `1` của `10111` khớp tiền tố mẫu.
Bỏ sót một cung lùi như vậy ⟹ **bỏ lỡ mẫu**, và lỗi chỉ lộ ra với một chuỗi rất cụ thể.

Thanh ghi dịch **không thể mắc lỗi này** — nó không có cung lùi nào để tính.

### 2.2 (C) FSM one-hot — chỉ đáng bàn cho mẫu rất dài

One-hot cho `N+1 = 6` trạng thái cần **6 FF** — **nhiều hơn** cả thanh ghi dịch (4 FF). Đổi
lại logic đầu ra chỉ là **1 dây**. Với mẫu 5 bit, đánh đổi này **không đáng**. ⬜ Chưa tổng
hợp.

### 2.3 (D) Bộ so sánh song song trên đệm

Nạp `N` bit vào một đệm rồi so sánh song song. Với `N = 5` thì **tương đương hoàn toàn** với
(A) — chỉ khác cách gọi tên. Với mẫu dài và **nhiều mẫu cùng lúc**, nó cho phép chia sẻ đệm.
⚠️ Nhưng "nhiều mẫu cùng lúc" **nằm ngoài phạm vi** Charter mục 3.

---

## 3. Đánh đổi bằng số liệu thật của E06

### 3.1 Đánh đổi **số trạng thái ↔ độ phức tạp logic**

| | Thanh ghi dịch (E06) | FSM tối thiểu |
|---|---:|---:|
| Số trạng thái | **16** (`2⁴`) | **6** (`S0`…`S5`) |
| Trạng thái "lãng phí" | 10 | 0 |
| Logic next-state | **phép dịch** | bảng chuyển KMP |
| Trạng thái bất hợp lệ | **0** | phụ thuộc mã hoá |

> **Đây là đánh đổi trung tâm của đề:** thanh ghi dịch dùng **16 trạng thái để làm việc của
> 6** — lãng phí 62,5 % không gian trạng thái. Đổi lại, hàm chuyển trở nên **tầm thường**
> và **không thể sai**. Đây là một ví dụ đẹp của nguyên lý *"đổi trạng thái lấy sự đơn
> giản"*, và nó lặp lại ở nhiều nơi khác trong thiết kế số (one-hot, mã Gray, bộ đếm vòng).

### 3.2 Đánh đổi **`bit_in` được so sánh trước khi chốt** — tiết kiệm 1 FF

E06 so sánh `bit_in` **trên đường vào**, nên mẫu 5 bit chỉ cần 4 FF (`datapath.md` §7).

| | Có tối ưu này | Không có (chốt cả 5 bit rồi so) |
|---|---:|---:|
| Flip-flop dữ liệu | **4** | 5 |
| Tiết kiệm | **1 FF = 20 %** ô nhớ dữ liệu | — |
| Chi phí | `bit_in` trở thành **startpoint đường tới hạn** (1,47 ns) | đường tới hạn sẽ là reg→reg, ngắn hơn |

⟹ Đổi **1 flip-flop** lấy **một chút độ trễ đầu vào**. Với slack 8,41 ns thì đánh đổi này
**rõ ràng có lợi**.

### 3.3 Đánh đổi **`overlap_en` — gần như miễn phí**

| Chỉ số | Giá trị |
|---|---:|
| Cell chuyên cho `overlap_en` | **2** (`o31ai_1 _19_`, `_22_`) = 11,1 % của 18 |
| Chi phí **gia tăng** thật | **≈ 0–2 cell** — hai ô này **thay thế** cổng vốn cần cho mạch dịch |
| Flip-flop thêm | **0** |
| Chỉ 2/4 bit cần logic xoá | vì khi `hit`, `bit_in = 0` và `history[2] = 0` sẵn (`control.md` §2.4.1) |

⟹ Tính năng chồng lấn/không chồng lấn **gần như miễn phí**. Đó là lý do mọi bộ dò mẫu thật
đều hỗ trợ cả hai chế độ.

### 3.4 Đánh đổi **Moore ↔ Mealy** — đối chiếu với F04

| | **E06 · Moore** | **F04 Mealy** |
|---|---|---|
| `match` | **đã chốt** (FF `_26_`) | tổ hợp |
| Flip-flop | 5 (gồm 1 cho `match`) | **2** |
| Cell | 18 (mẫu 5 bit) | **11** (mẫu 4 bit) |
| Trễ từ bit tới đầu ra | **1 chu kỳ** | **0 chu kỳ** |
| Glitch trên đầu ra | ❌ **không** | ⚠️ **có thể** |
| Đường reg→out | **0,26 ns** (đo được) | dài hơn — qua logic tổ hợp |
| Phù hợp cho chân **ra khỏi chip** | ✅ | ⚠️ rủi ro |

> **E06 chọn Moore, và đó là lựa chọn đúng** cho một khối có đầu ra đi ra khỏi chip: đổi
> **1 flip-flop và 1 chu kỳ trễ** lấy **đầu ra sạch, không glitch**. Đề F04 tồn tại chính
> để so sánh hai lựa chọn này trên cùng bài toán.

### 3.5 Đánh đổi ẩn: **`Init` của cửa sổ ↔ tính đúng của chế độ không chồng lấn**

| | Xoá về `0000` *(E06 làm)* | Cờ "cửa sổ chưa đầy" |
|---|---|---|
| Chi phí | **0 cell thêm** | +3–4 FF |
| Đúng với mẫu bắt đầu bằng **`1`** | ✅ | ✅ |
| Đúng với mẫu bắt đầu bằng **`0`** | ❌ **SAI — khớp giả sau 4 bit** | ✅ |

⟹ E06 **may mắn** có mẫu `10110` bắt đầu bằng `1`, nên cách rẻ nhất lại đúng. Xem
`timing_diagram.md` §3.1 và `functional_spec.md` §7.5. **Đây là bẫy dạy học quan trọng
nhất của đề.**

---

## 4. Ràng buộc phạm vi — kiến trúc chỉ được so sánh trên giấy

| Nằm ngoài phạm vi (Charter mục 3) | Ảnh hưởng |
|---|---|
| **Mẫu lập trình được** | Không được thêm thanh ghi chứa mẫu. Và về phần cứng, mẫu nằm trong **hình dạng cổng** (`nand4b_1 _15_` chân `A_N`) ⟹ **không thể** đổi lúc chạy |
| **Nhiều mẫu cùng lúc** | Phương án (D) chia sẻ đệm chỉ so sánh trên giấy |
| **Mẫu có ký tự đại diện** | Không được đổi `==` thành so sánh có mặt nạ |
| **Tự làm physical design, sign-off, tape-out** | Không khẳng định gì về tần số hoạt động thật |

---

## 5. Những đánh đổi **KHÔNG được phép** trong đề này

| Đánh đổi bị cấm | Vì sao | Điều khoản |
|---|---|---|
| Thay thanh ghi dịch bằng **FSM mã hoá tay** | Tên đề chốt "**dùng thanh ghi dịch**"; và đó là đề **F04** | ST-1, `functional_spec.md` §4 |
| **Bỏ `overlap_en`** để tiết kiệm 2 cell | Charter mục 4 yêu cầu `uio_in[1]` = "cho phép chồng lấn" | Charter mục 4 |
| Làm mẫu **lập trình được** | Ngoài phạm vi | Charter mục 3 |
| **Bỏ chốt `match`** (chuyển sang Mealy) | Đổi bản chất đầu ra; và mất ưu thế chống glitch cho chân ra khỏi chip | thiết kế |
| **Tự sửa netlist bằng tay** | Ngoài phạm vi với mọi đề | Charter mục 3 |
| Chép cách **"xoá về 0"** sang mẫu bắt đầu bằng `0` | **SAI về chức năng** — khớp giả sau 4 bit | §3.5 |
| Dùng thẳng `So cell = 2` của `brief/F04.md` | Đó là **hiện vật phân cấp**, không phải số liệu bộ dò mẫu | §1.1 |
| Khẳng định "E06 chạy ở 680 MHz" từ 1,47 ns | 68 % là giả định IO; chưa có RC dây; một góc PVT | `timing.md` §3 G-1…G-4 |
| Khẳng định **"mô phỏng đã chứng minh RTL đúng"** | ❌ **COMPILE_FAIL** — chưa ca nào chạy | `known_issues.md` |
| **Sửa RTL** theo đề xuất trong hồ sơ | Giữ nguyên bản gốc của thầy | cần thầy duyệt |

---

## 6. Ba đề xuất cải tiến **được phép bàn**

| # | Đề xuất | Lợi (định lượng) | Hại | Ngoài phạm vi? |
|---|---|---|---|:-:|
| 1 | **Sửa testbench** theo `known_issues.md` §4 | Mở khoá **toàn bộ** bằng chứng mô phỏng — hiện đang là **0** | 0 cell; chỉ sửa testbench, không đụng RTL | ❌ Không — **ưu tiên số 1** |
| 2 | Thêm `output logic [4:0] window;` + `assign window = history;` theo Charter mục 4 | Thoả REQ-E06-002 (đang **CHƯA THOẢ**); `history[4]` sống lại ⟹ **6 FF** đúng dự đoán Charter mục 10; cho phép debug bằng quan sát cửa sổ | **+1 FF** (5 → 6) và **+5 chân ra** (ngân sách còn dư 18) | ❌ Không |
| 3 | Thêm cờ **"cửa sổ chưa đầy"** | Làm chế độ không-chồng-lấn **đúng với mọi mẫu**, không chỉ mẫu bắt đầu bằng `1` | +3–4 FF (5 → 8–9, **+60–80 %**) | ❌ Không, nhưng **không cần** cho mẫu `10110` |

> **Thứ tự ưu tiên rõ ràng:** đề xuất **#1** phải làm trước, vì không có nó thì mọi khẳng
> định chức năng của E06 đều chưa có bằng chứng. Đề xuất #2 sửa vi phạm Charter. Đề xuất #3
> chỉ cần nếu mẫu đổi.

Cả ba **chưa được áp dụng** — cần thầy duyệt.

---

## 7. Bảng so sánh ba đề nhóm E — số liệu thật

| | **E04** P→S | **E05** CRC-8 | **E06** Dò mẫu |
|---|---:|---:|---:|
| Cell | 55 | **64** | **18** ← nhỏ nhất |
| Flip-flop | 13 | **17** | **5** ← ít nhất |
| Diện tích (µm²) | 519,248 | **646,8704** | **182,6752** ← nhỏ nhất |
| Công suất (W) | 6,29e-05 | **7,72e-05** | **2,35e-05** ← thấp nhất |
| % công suất tuần tự | 91,6 | 92,8 | 92,5 |
| Arrival (ns) | 1,71 | 1,51 | **1,47** ← nhanh nhất |
| Phần IO trong arrival | 58 % | 66 % | **68 %** |
| Slack setup (ns) | 8,22 | **8,43** | 8,41 |
| Slack hold (ns) | 0,45 | **0,43** | 0,46 |
| Startpoint tới hạn | `start` (**điều khiển**) | `data_valid` (**điều khiển**) | `bit_in` (**dữ liệu**) |
| FF điều khiển | **5 (38 %)** | 0 | 0 |
| Trạng thái bất hợp lệ | **8** | 0 | **0** |
| Mô phỏng RTL | ✅ PASS | ✅ PASS | ❌ **COMPILE_FAIL** |

> **Ba quy luật rút ra từ bảng này:**
> 1. **Công suất tuần tự luôn ≈ 92 %** ở cả ba đề, dù số FF chênh nhau ×3,4. Flip-flop ngốn
>    điện bất kể có dữ liệu hay không.
> 2. **Phần IO chiếm 58–68 % arrival** ở cả ba đề. Với mạch nhỏ, `set_input_delay` áp đảo
>    ⟹ **không** đọc arrival như "tốc độ của thiết kế".
> 3. **Startpoint tới hạn là tín hiệu điều khiển** khi datapath rộng (E04: 8 bit, E05:
>    8 bit), và là **tín hiệu dữ liệu** khi datapath hẹp (E06: 1 bit + cửa sổ 4 bit).

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
