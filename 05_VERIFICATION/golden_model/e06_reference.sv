module e06_reference (
    input  logic clk,
    input  logic rst_n,
    input  logic bit_valid,
    input  logic bit_in,
    input  logic overlap_en,
    output logic match_ref
);
    logic [4:0] hist;
    logic [4:0] nxt;

    always_comb begin
        nxt = {hist[3:0], bit_in};
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            hist <= 5'b0;
            match_ref <= 1'b0;
        end else begin
            match_ref <= 1'b0;
            if (bit_valid) begin
                if (nxt == 5'b10110) begin
                    match_ref <= 1'b1;
                    if (!overlap_en)
                        hist <= 5'b0;
                    else
                        hist <= nxt;
                end else begin
                    hist <= nxt;
                end
            end
        end
    end
endmodule
