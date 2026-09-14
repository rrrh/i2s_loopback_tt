module i2s_crossover #(
    parameter DATA_WIDTH = 24
)(
    input  wire rst_n,
    input  wire bclk,
    input  wire ws,
    input  wire rx_sdata,
    output wire tx_sdata_lp, // Low-pass output (Subwoofer)
    output wire tx_sdata_hp  // High-pass output (Tweeters)
);

    wire [DATA_WIDTH-1:0] rx_left_data;
    wire [DATA_WIDTH-1:0] rx_right_data;
    wire                  rx_data_valid;

    // Cast incoming data to signed for correct arithmetic shifting
    wire signed [DATA_WIDTH-1:0] rx_l = rx_left_data;
    wire signed [DATA_WIDTH-1:0] rx_r = rx_right_data;

    // Filter accumulators (Registers)
    reg signed [DATA_WIDTH-1:0] lp_l;
    reg signed [DATA_WIDTH-1:0] lp_r;

    // High-pass signals (Combinational)
    wire signed [DATA_WIDTH-1:0] hp_l = rx_l - lp_l;
    wire signed [DATA_WIDTH-1:0] hp_r = rx_r - lp_r;

    // IIR Filter Processing
    always @(posedge bclk or negedge rst_n) begin
        if (!rst_n) begin
            lp_l <= 0;
            lp_r <= 0;
        end else if (rx_data_valid) begin
            // Arithmetic right shift (>>>) preserves the sign bit
            lp_l <= lp_l + ((rx_l - lp_l) >>> 3);
            lp_r <= lp_r + ((rx_r - lp_r) >>> 3);
        end
    end

    // I2S Receiver
    i2s_rx #(.DATA_WIDTH(DATA_WIDTH)) u_rx (
        .rst_n(rst_n), .bclk(bclk), .ws(ws), .sdata(rx_sdata),
        .left_data(rx_left_data), .right_data(rx_right_data), .data_valid(rx_data_valid)
    );

    // I2S Transmitter 1: Low-Pass
    i2s_tx #(.DATA_WIDTH(DATA_WIDTH)) u_tx_lp (
        .rst_n(rst_n), .bclk(bclk), .ws(ws),
        .left_data(lp_l), .right_data(lp_r), .sdata(tx_sdata_lp)
    );

    // I2S Transmitter 2: High-Pass
    i2s_tx #(.DATA_WIDTH(DATA_WIDTH)) u_tx_hp (
        .rst_n(rst_n), .bclk(bclk), .ws(ws),
        .left_data(hp_l), .right_data(hp_r), .sdata(tx_sdata_hp)
    );

endmodule
