module e06_detector_tb;
    logic clk, rst_n, bit_valid, bit_in, overlap_en;
    logic match, match_ref;

    e06_detector dut(
        .clk(clk), .rst_n(rst_n), .bit_valid(bit_valid),
        .bit_in(bit_in), .overlap_en(overlap_en), .match(match)
    );

    e06_reference ref_i(
        .clk(clk), .rst_n(rst_n), .bit_valid(bit_valid),
        .bit_in(bit_in), .overlap_en(overlap_en), .match_ref(match_ref)
    );

    always #5 clk = ~clk;

    task send_bit(input logic b);
        begin
            bit_in = b;
            bit_valid = 1'b1;
            @(posedge clk); #1;
            assert(match === match_ref)
                else $fatal(1,"match mismatch b=%b dut=%b ref=%b",b,match,match_ref);
        end
    endtask

    // Co lap that su giua hai chuoi: 'bit_valid=0' chi lam khoi dong bang,
    // KHONG xoa history. Phai xung rst_n moi xoa duoc cua so.
    task reset_window;
        begin
            bit_valid = 1'b0; rst_n = 1'b0;
            repeat (2) @(posedge clk);
            rst_n = 1'b1;
        end
    endtask

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

    initial begin
        clk=0; rst_n=0; bit_valid=0; bit_in=0; overlap_en=1;
        repeat(2) @(posedge clk);
        rst_n=1;

        // Official: beginning/end/no match.
        send_stream(32'b10110,          5);   // "10110"
        send_stream(32'b0010110,        7);   // "0010110"
        send_stream(32'b000000,         6);   // "000000"

        // Official overlap stream.
        overlap_en=1;
        send_stream(32'b1011011010,    10);   // "1011011010"

        // Official non-overlap behavior.
        overlap_en=0;
        send_stream(32'b1011011010,    10);   // "1011011010"

        // Student boundary cases.
        overlap_en=1;
        send_stream(32'b1011,           4);   // "1011"
        send_stream(32'b11111,          5);   // "11111"
        send_stream(32'b101100,         6);   // "101100"

        $display("E06 TB PASS");
        $finish;
    end
endmodule
