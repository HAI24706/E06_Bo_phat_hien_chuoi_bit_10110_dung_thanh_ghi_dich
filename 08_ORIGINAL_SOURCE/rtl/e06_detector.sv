module e06_detector (
    input  logic clk,
    input  logic rst_n,
    input  logic bit_valid,
    input  logic bit_in,
    input  logic overlap_en,
    output logic match
);
    logic [4:0] history;
    logic [4:0] next_window;
    logic       hit;

    always_comb begin
        next_window = {history[3:0], bit_in};
        hit = bit_valid && (next_window == 5'b10110);
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            history <= 5'b00000;
            match   <= 1'b0;
        end else begin
            match <= 1'b0;
            if (bit_valid) begin
                if (hit && !overlap_en)
                    history <= 5'b00000;
                else
                    history <= next_window;
                match <= hit;
            end
        end
    end
endmodule
