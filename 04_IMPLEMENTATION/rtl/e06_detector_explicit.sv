module e06_detector_explicit (
    input  logic clk,
    input  logic rst_n,
    input  logic bit_valid,
    input  logic bit_in,
    input  logic overlap_en,
    output logic match
);
    logic [4:0] history, history_d;
    logic       match_d;

    always_comb begin
        history_d = history;
        match_d   = 1'b0;

        if (bit_valid) begin
            if ({history[3:0],bit_in} == 5'b10110) begin
                match_d = 1'b1;
                if (overlap_en)
                    history_d = {history[3:0],bit_in};
                else
                    history_d = 5'b00000;
            end else begin
                history_d = {history[3:0],bit_in};
            end
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            history <= 5'b00000;
            match   <= 1'b0;
        end else begin
            history <= history_d;
            match   <= match_d;
        end
    end
endmodule
