module i2s_rx #(
    parameter DATA_WIDTH = 24 // Standard audio bit-depths: 16, 24, or 32
)(
    input  wire                  rst_n,      // Active-low reset
    input  wire                  bclk,       // Bit clock
    input  wire                  ws,         // Word select (0 = Left, 1 = Right)
    input  wire                  sdata,      // Serial data in
    output reg  [DATA_WIDTH-1:0] left_data,  // Parallel output to DAC (Left)
    output reg  [DATA_WIDTH-1:0] right_data, // Parallel output to DAC (Right)
    output reg                   data_valid  // Pulses high when a full L/R frame is ready
);

    reg [DATA_WIDTH-1:0] shift_reg;
    reg ws_d1;
    reg [5:0] bit_cnt;

    always @(posedge bclk or negedge rst_n) begin
        if (!rst_n) begin
            ws_d1      <= 1'b0;
            shift_reg  <= {DATA_WIDTH{1'b0}};
            left_data  <= {DATA_WIDTH{1'b0}};
            right_data <= {DATA_WIDTH{1'b0}};
            data_valid <= 1'b0;
            bit_cnt    <= 0;
        end else begin
            ws_d1      <= ws;
            data_valid <= 1'b0; 

            // Detect WS edge (start of new channel frame)
            if (ws_d1 ^ ws) begin
                bit_cnt <= 0;
                
                // Latch the completed word into the appropriate channel register
                if (ws_d1 == 1'b0) begin
                    left_data <= shift_reg;
                end else begin
                    right_data <= shift_reg;
                    data_valid <= 1'b1; // Both L and R are now updated
                end
            end else if (bit_cnt < DATA_WIDTH) begin
                bit_cnt <= bit_cnt + 1;
            end

            // Shift data in (MSB first)
            // The first BCLK edge after WS toggles captures the MSB
            if (bit_cnt < DATA_WIDTH) begin
                shift_reg <= {shift_reg[DATA_WIDTH-2:0], sdata};
            end
        end
    end
endmodule
