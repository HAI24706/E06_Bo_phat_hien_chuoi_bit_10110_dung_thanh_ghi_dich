# E06 · Giản đồ thời gian (Timing Diagram)

> ⚠️ **HAI cảnh báo phải đọc trước:**
>
> 1. **Mô phỏng RTL COMPILE_FAIL** — mọi giản đồ dưới đây được **dựng bằng tay** từ RTL,
>    netlist và mô hình Python đã chạy PASS. Chúng **KHÔNG** phải là waveform thu được từ
>    mô phỏng. Xem [`../05_VERIFICATION/known_issues.md`](../05_VERIFICATION/known_issues.md).
> 2. Ngay cả khi mô phỏng chạy được, nó là **mô phỏng hành vi (zero-delay)** — mọi tín hiệu
>    đổi **tức thời** tại sườn clock, **không** minh hoạ độ trễ thật (`t_ckq` ≈ 0,29 ns,
>    slew, glitch). Số độ trễ thật chỉ có ở `06_GDSII/sta/`; độ trễ sau routing **chưa có**.

---

## 1. Giao dịch điển hình — chuỗi `1011011010`, chế độ **chồng lấn**

Ca C-4 (testbench dòng 48). Giá trị `history` tính trực tiếp từ RTL; số lần khớp khớp với
`python_reference_run.log`: `overlap 1011011010 -> [5, 8]`.

```
 bit #    │ 1  │ 2  │ 3  │ 4  │ 5  │ 6  │ 7  │ 8  │ 9  │10  │11  │
          ┌─┐  ┌─┐  ┌─┐  ┌─┐  ┌─┐  ┌─┐  ┌─┐  ┌─┐  ┌─┐  ┌─┐  ┌─┐
 clk    ──┘ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘ └──
          ▲    ▲    ▲    ▲    ▲    ▲    ▲    ▲    ▲    ▲    ▲

 rst_n  ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

 overlap ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾  = 1
 _en

 bit_    ┌────────────────────────────────────────────────────┐
 valid ──┘                                                    └───

 bit_in   ┌────┐    ┌─────────┐    ┌─────────┐    ┌────┐
        ──┘    └────┘         └────┘         └────┘    └──────────
           1    0    1    1    0    1    1    0    1    0
           └───────── chuỗi '1011011010' ──────────────┘

 history ═ 0000 ╳0001╳0010╳0101╳1011╳0110╳1101╳1011╳0110╳1101╳1010═
  [3:0]                          ▲              ▲
                          "sắp khớp"      "sắp khớp" LẠI

 cửa sổ  ═  ·  ╳00001╳00010╳00101╳01011╳10110╳01101╳11011╳10110╳…
  {h,b}                                   ▲                ▲
                                        KHỚP!            KHỚP!

                                         ┌────┐          ┌────┐
 match  ─────────────────────────────────┘    └──────────┘    └───
                                         ▲               ▲
                                    bit thứ 5       bit thứ 8
                                         └──── 3 bit ────┘
```

### 1.1 Bảng số chính xác theo bit (giá trị **sau** sườn lên)

| Bit # | `bit_in` | `history[3:0]` **trước** | cửa sổ `{h, bit_in}` | Khớp? | `history` **sau** | `match` sau |
|---:|:-:|---|---|:-:|---|:-:|
| — (reset) | — | — | — | — | `0000` | 0 |
| 1 | 1 | `0000` | `00001` | | `0001` | 0 |
| 2 | 0 | `0001` | `00010` | | `0010` | 0 |
| 3 | 1 | `0010` | `00101` | | `0101` | 0 |
| 4 | 1 | `0101` | `01011` | | **`1011`** ← sắp khớp | 0 |
| **5** | **0** | **`1011`** | **`10110`** | ✅ | `0110` | **1** |
| 6 | 1 | `0110` | `01101` | | `1101` | **0** |
| 7 | 1 | `1101` | `11011` | | **`1011`** ← sắp khớp | 0 |
| **8** | **0** | **`1011`** | **`10110`** | ✅ | `0110` | **1** |
| 9 | 1 | `0110` | `01101` | | `1101` | **0** |
| 10 | 0 | `1101` | `11010` | | `1010` | 0 |

Hai lần khớp tại bit **5** và **8** — khớp chính xác `reference_model.py`: `[5, 8]`. ✅

> **Đọc kỹ hai điểm:**
>
> **(a) `history` trở lại `1011` ở bit 7.** Sau lần khớp đầu, cửa sổ là `0110`; hai bit
> `1,1` đưa nó về `1011`. Đây là **tái sử dụng 2 bit cuối của mẫu trước** — chính là ý
> nghĩa của "chồng lấn".
>
> **(b) Khoảng cách tối thiểu giữa hai `match` là 3 bit.** Sau khớp, `history = 0110`; cần
> ≥ 2 bit để quay về `1011`, rồi 1 bit `0` nữa ⟹ tổng 3. Con số `8 − 5 = 3` xác nhận. Đây
> là bằng chứng waveform cho **INV-5** (`functional_spec.md` §7.3).

## 2. Cùng chuỗi, chế độ **KHÔNG chồng lấn** — chỉ 1 lần khớp

Ca C-5 (testbench dòng 52). Mô hình Python: `nonoverlap 1011011010 -> [5]`.

```
 bit #    │ 1  │ 2  │ 3  │ 4  │ 5  │ 6  │ 7  │ 8  │ 9  │10  │

 overlap ─────────────────────────────────────────────────────── = 0
 _en

 bit_in    1    0    1    1    0    1    1    0    1    0
                                          ▲
                              ở chế độ CHỒNG LẤN, đây là chỗ khớp lần 2

 history ═ 0000 ╳0001╳0010╳0101╳1011╳0000╳0001╳0011╳0110╳1101╳1010═
                                     ▲▲▲▲
                               XOÁ VỀ 0 thay vì 0110
                                      │
                                      └── và đây là TOÀN BỘ khác biệt phần cứng

 cửa sổ  ═  ·  ╳00001╳00010╳00101╳01011╳10110╳00001╳00011╳00110╳…
                                         ▲            ▲
                                       KHỚP!       KHÔNG khớp
                                                 (so với 10110:
                                                  bit đầu là 0 ≠ 1)

                                         ┌────┐
 match  ─────────────────────────────────┘    └────────────────────
                                         ▲
                                  CHỈ MỘT lần khớp
```

### 2.1 Bảng đối chiếu hai chế độ — cô lập đúng tác dụng của `overlap_en`

| Bit # | `bit_in` | `history` (chồng lấn) | `history` (**không** chồng lấn) | Khác? |
|---:|:-:|---|---|:-:|
| 1–4 | `1,0,1,1` | `0001`→`0010`→`0101`→`1011` | **giống hệt** | |
| **5** | 0 | `0110` ✅ match | **`0000`** ✅ match | ⬅ **KHÁC** |
| 6 | 1 | `1101` | `0001` | ⬅ |
| 7 | 1 | `1011` | `0011` | ⬅ |
| **8** | 0 | `0110` ✅ **match** | `0110` ❌ **không** | ⬅ **KHÁC** |
| 9 | 1 | `1101` | `1101` | (trùng lại) |
| 10 | 0 | `1010` | `1010` | |
| **Tổng match** | | **2** (bit 5, 8) | **1** (bit 5) | |

> **Đây là lý do Charter yêu cầu chạy CÙNG một chuỗi ở CẢ HAI chế độ** (ca C-4 và C-5):
> chỉ khi giữ nguyên chuỗi mới cô lập được đúng tác dụng của `overlap_en`. Dùng hai chuỗi
> khác nhau thì không kết luận được gì.
>
> Và điều thú vị: sau bit 9, hai chế độ **hội tụ lại** cùng `history = 1101`. Vì cửa sổ chỉ
> nhớ 4 bit, mọi khác biệt lịch sử **tự xoá sau 4 bit**. Đây là tính chất tự phục hồi đã
> chứng minh ở `fsm.md` §6.

## 3. Vì sao "xoá về 0" **an toàn** với mẫu `10110`

```
 sau khi XOÁ:  history = 0000
 nạp 1 bit:    cửa sổ = 0000b₁   ← bit trái nhất là 0, mẫu cần 1  ⟹ KHÔNG khớp
 nạp 2 bit:    cửa sổ = 000b₁b₂  ← bit trái nhất là 0             ⟹ KHÔNG khớp
 nạp 3 bit:    cửa sổ = 00b₁b₂b₃ ← bit trái nhất là 0             ⟹ KHÔNG khớp
 nạp 4 bit:    cửa sổ = 0b₁b₂b₃b₄← bit trái nhất là 0             ⟹ KHÔNG khớp
 nạp 5 bit:    cửa sổ = b₁b₂b₃b₄b₅ ← hoàn toàn dữ liệu mới        ⟹ có thể khớp ✅
                        ▲
                mẫu '10110' bắt đầu bằng 1, nên các số 0 dẫn đầu chặn mọi khớp giả
```

### 3.1 ⚠️ Nhưng với mẫu bắt đầu bằng `0` thì **SAI** — bẫy kinh điển

Giả sử mẫu là `01101` (bắt đầu bằng `0`):

```
 sau khi XOÁ:  history = 0000
 nạp 4 bit '1101':  cửa sổ = 0 1 1 0 1  = '01101'  ⟹ ✅ KHỚP GIẢ!
                            ▲
                   số 0 từ việc XOÁ lại KHỚP với bit đầu của mẫu
```

| | RTL (xoá về `0000`) | Mô hình Python (`window = ""`) |
|---|---|---|
| Sau 4 bit mới `1101` | cửa sổ `01101` ⟹ **khớp** | cửa sổ chỉ 4 ký tự ⟹ **không khớp** |

⟹ **Hai mô hình sẽ bất đồng**, và RTL **sai**.

| Cách sửa | Chi phí |
|---|---|
| Thêm cờ "cửa sổ chưa đầy" — chặn `match` trong 4 bit đầu sau khi xoá | +3–4 FF |
| Xoá về giá trị **không thể là tiền tố** của mẫu | 0 FF, nhưng phải phân tích riêng từng mẫu |

> **Đây là điểm dạy học quan trọng nhất của E06.** Charter mục 10 cảnh báo *"sau khi khớp,
> chế độ không chồng lấn phải xoá thanh ghi"* — đúng nhưng **chưa đủ**. Phải nói thêm:
> **xoá về 0 chỉ an toàn khi bit đầu của mẫu bằng 1.** Sinh viên chép cách này sang mẫu
> khác sẽ sai, và mô phỏng **so với golden model SV** cũng **không bắt được** (vì golden
> model viết y hệt DUT — xem `corner_cases.md` §5.2). Chỉ mô hình **Python** mới bắt được.

## 4. Ca âm tính — chuỗi `000000` (C-3)

```
 bit #    │ 1  │ 2  │ 3  │ 4  │ 5  │ 6  │

 bit_in  ───────────────────────────────────  = 0 suốt

 history ═0000╳0000╳0000╳0000╳0000╳0000╳0000═
              ▲ ĐỨNG YÊN (dịch 0 vào chuỗi 0)

 cửa sổ  ═  · ╳00000╳00000╳00000╳00000╳00000╳
                     ▲ không bao giờ bằng 10110

 match  ────────────────────────────────────  = 0 suốt
```

**Điểm bất động.** Cửa sổ `0000` nhận bit `0` cho lại `0000`. Không có ca âm tính thì một
DUT hỏng (luôn bật `match`) vẫn "PASS" mọi ca dương tính — đó là lý do Charter mục 8 yêu cầu
ca này.

## 5. Ca biên `"1011"` (C-6) — chuỗi **ngắn hơn** mẫu, dừng ở "sắp khớp"

```
 bit #    │ 1  │ 2  │ 3  │ 4  │  (hết chuỗi)

 bit_in    1    0    1    1
 history ═0000╳0001╳0010╳0101╳1011═══════════
                              ▲
                     "SẮP KHỚP" — chỉ cần thêm bit_in = 0 nữa
                     nhưng chuỗi ĐÃ HẾT

 match  ────────────────────────────────────  = 0  ✅ ĐÚNG
```

Ca này kiểm rằng mạch **không đoán trước**: nó phải có đủ **bit thứ 5** mới bật `match`.
Nếu logic so sánh chỉ nhìn 4 bit đã chốt (quên `bit_in`), ca này sẽ **khớp sai**.

## 6. Cơ chế `bit_valid` — "đóng băng thời gian"

```
 chu kỳ  │ 1  │ 2  │ 3  │ 4  │ 5  │ 6  │ 7  │ 8  │

 bit_    ┌─────────┐              ┌──────────────┐
 valid ──┘         └──────────────┘              └───
          ◀ chạy ▶  ◀ ĐÓNG BĂNG ▶  ◀─── chạy ───▶

 bit_in    1    0    ?    ?    ?    1    1    0
                     └── không quan trọng ──┘

 history ═0000╳0001╳0010╳0010╳0010╳0010╳0101╳1011╳0110
                          ▲▲▲▲▲▲▲▲▲▲▲   ▲
                       GIỮ NGUYÊN     tiếp tục từ đúng chỗ

 match  ─────────────────────────────────────────┌────┐
                                                 └    └──
```

Chuỗi bit hiệu dụng là `1,0,1,1,0` — khớp `10110` dù trải ra trên 8 chu kỳ clock.

> **E06 đếm theo SỐ BIT HỢP LỆ, không theo SỐ CHU KỲ CLOCK.** Nhờ đó nguồn bit có thể chậm
> hơn clock tuỳ ý mà không cần chia tần.
>
> ⚠️ **Nhưng `bit_valid = 0` KHÔNG xoá cửa sổ** — nó chỉ dừng thời gian. Muốn bắt đầu một
> phiên dò "sạch" **bắt buộc phải xung `rst_n`**. Đây chính là vấn đề M-2 trong
> `corner_cases.md` §5.1: testbench tưởng các chuỗi được cô lập, thực ra chúng bị nối liền.
>
> ⚠️ **Nhánh này CHƯA BAO GIỜ được mô phỏng** — lớp B-V không được phủ, và testbench không
> biên dịch được.

## 7. Reset đồng bộ

```
 CA ĐÚNG (testbench dòng 38: repeat(2) @(posedge clk))
          ┌─┐  ┌─┐  ┌─┐
 clk    ──┘ └──┘ └──┘ └──
 rst_n  ‾‾‾‾‾\______/‾‾‾‾
                 ▲
 history ═ ??? ═╳══ 0000 ══    ← reset có hiệu lực TẠI sườn
 match   ═ ??? ═╳══  0   ══

 CA SAI: rst_n = 0 nhưng clock đứng yên
 clk    ─────────────────────
 rst_n  ‾‾‾‾‾\_____________
 history ═══ ??? ═══════════   ← KHÔNG reset
```

Bằng chứng netlist: 5 ô nhớ đều là `dfxtp_1` — **không có chân `RESET_B`**. `rst_n` gộp vào
tổ hợp qua `clkinv_1 _13_` → `nor3_1 _16_`, và trực tiếp vào `nor2_1 _18_`, `o21ai_0 _20_`,
`o21ai_0 _23_`, `o211a_1 _25_`.

**Rủi ro X-propagation sau power-up:** `history` bất định ⟹ có thể báo `match` giả. Nhưng
`X` **tự trôi hết sau 4 bit hợp lệ** (cửa sổ được thay mới hoàn toàn) — **nhẹ hơn E05** nơi
`X` lan qua đường feedback `crc[7]` sang toàn bộ 8 bit.

## 8. Những gì giản đồ này **không** cho biết

| Không thấy được | Vì sao | Muốn thấy phải làm gì |
|---|---|---|
| ⚠️ **Bất cứ điều gì đã được mô phỏng xác nhận** | **COMPILE_FAIL** | Sửa testbench (`known_issues.md` §4) rồi chạy lại |
| Độ trễ `clk → match` (≈ `t_ckq` 0,29 ns) | Zero-delay | Mô phỏng gate-level (L4) |
| Vi phạm setup/hold | Mô phỏng hành vi không kiểm timing | STA (đã có: slack setup **8,41 ns**, hold **0,46 ns**) |
| Skew cây clock trên 5 FF | Chưa chạy CTS | LibreLane + PDK sky130A |
| Dạng sóng `match` với tải ngoài thật | Chưa có mô hình tải | `set_load` + P&R |

> **Nối giản đồ với con số STA:** mỗi "ô vuông" là 10 ns (chu kỳ **giả định**). Tín hiệu ổn
> định sau ~1,47 ns, trong đó **1,00 ns là giả định IO (68 %)**. Phần logic thật chỉ
> **0,47 ns = 4,7 % chu kỳ** — E06 là thiết kế **nông nhất** trong ba đề E04/E05/E06.
> Nhưng **không được** suy ra "E06 chạy ở 680 MHz": chưa có RC dây, mới một góc PVT.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
