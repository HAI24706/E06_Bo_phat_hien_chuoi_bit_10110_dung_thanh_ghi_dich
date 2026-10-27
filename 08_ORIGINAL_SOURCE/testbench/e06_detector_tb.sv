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

    task send_stream(input string s);
        integer i;
        begin
            for (i=0;i<s.len();i=i+1)
                send_bit(s.getc(i)-48);
            bit_valid=1'b0;
        end
    endtask

    initial begin
        clk=0; rst_n=0; bit_valid=0; bit_in=0; overlap_en=1;
        repeat(2) @(posedge clk);
        rst_n=1;

        // Official: beginning/end/no match.
        send_stream("10110");
        send_stream("0010110");
        send_stream("000000");

        // Official overlap stream.
        overlap_en=1;
        send_stream("1011011010");

        // Official non-overlap behavior.
        overlap_en=0;
        send_stream("1011011010");

        // Student boundary cases.
        overlap_en=1;
        send_stream("1011");
        send_stream("11111");
        send_stream("101100");

        $display("E06 TB PASS");
        $finish;
    end
endmodule
