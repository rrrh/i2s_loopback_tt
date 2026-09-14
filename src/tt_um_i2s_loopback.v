`default_nettype none

module tt_um_i2s_crossover (
    input  wire [7:0] ui_in,    
    output wire [7:0] uo_out,   
    input  wire [7:0] uio_in,   
    output wire [7:0] uio_out,  
    output wire [7:0] uio_oe,   
    input  wire       ena,      
    input  wire       clk,      
    input  wire       rst_n     
);

    wire ws          = ui_in[0];
    wire rx_sdata    = ui_in[1];
    
    wire tx_sdata_lp;
    wire tx_sdata_hp;

    i2s_crossover #(
        .DATA_WIDTH(24)
    ) core (
        .rst_n(rst_n),
        .bclk(clk),        
        .ws(ws),
        .rx_sdata(rx_sdata),
        .tx_sdata_lp(tx_sdata_lp),
        .tx_sdata_hp(tx_sdata_hp)
    );

    // Output Mapping
    assign uo_out[0] = tx_sdata_lp;
    assign uo_out[1] = tx_sdata_hp;
    
    // Tie-offs
    assign uo_out[7:2] = 6'b000000;
    assign uio_out     = 8'b00000000;
    assign uio_oe      = 8'b00000000; 

    wire _unused = &{ena, ui_in[7:2], uio_in};

endmodule
