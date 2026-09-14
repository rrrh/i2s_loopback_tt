module i2s_tx #(
    parameter DATA_WIDTH = 24
)(
    input  wire                  rst_n,      // Active-low reset
    input  wire                  bclk,       // Bit clock
    input  wire                  ws,         // Word select (0 = Left, 1 = Right)
    input  wire [DATA_WIDTH-1:0] left_data,  // Parallel input from ADC (Left)
    input  wire [DATA_WIDTH-1:0] right_data, // Parallel input from ADC (Right)
    output reg                   sdata       // Serial data out
);

    reg [DATA_WIDTH-1:0] shift_reg;
    reg ws_d1;
    reg [5:0] bit_cnt;

    // Drive data on the negative edge of BCLK
    always @(negedge bclk or negedge rst_n) begin
        if (!rst_n) begin
            ws_d1     <= 1'b0;
            shift_reg <= {DATA_WIDTH{1'b0}};
            sdata     <= 1'b0;
            bit_cnt   <= 0;
        end else begin
            ws_d1 <= ws;

            // WS transitioned: prepare the shift register
            if (ws ^ ws_d1) begin
                bit_cnt <= 1;
                // I2S requires 1 clock cycle delay before MSB is sent.
                // We load the data now, and the first bit goes out on the NEXT falling edge.
                if (ws == 1'b0) 
                    shift_reg <= left_data;
                else            
                    shift_reg <= right_data;
                
                sdata <= 1'b0; // I2S padding/delay bit
            end 
            // Shift data out (MSB first)
            else if (bit_cnt <= DATA_WIDTH) begin
                sdata     <= shift_reg[DATA_WIDTH-1];
                shift_reg <= {shift_reg[DATA_WIDTH-2:0], 1'b0};
                bit_cnt   <= bit_cnt + 1;
            end 
            // Pad remaining clocks in the frame with zeros
            else begin
                sdata <= 1'b0;
            end
        end
    end
endmodule
