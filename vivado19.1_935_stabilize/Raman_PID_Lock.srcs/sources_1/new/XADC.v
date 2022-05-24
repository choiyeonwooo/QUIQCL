// continuous sampling mode:
// ADC automatically starts new conversion after current conversion cycle

module XADC(
    input dclk_in,
    // input reset_in,
    // input di_in,
    // input [6:0] daddr_in,
    // input den_in,
    // input dwe_in,
    input vp_in,
    input vn_in,
    // input start_trigger,
    // output drdy_out,
    output reg [15:0] do_out
    // output busy_out,
    // output [4:0] channel_out,
    // output eoc_out
);
    wire den_in;
    wire dwe_in;
    wire [6:0] daddr_in;
    wire reset_in;
    wire [15:0] d_out;
    wire ready_rising;
    reg ready_d1;
    reg en;
    reg [4:0] ch_out;
    assign {dwe_in, daddr_in} = {1'b0, 7'h03};

    XADC_block adc(
        // clk & reset 
        .dclk_in(dclk_in),
        // .reset_in(reset_in),
        // DRP interface
        // .di_in(di_in), //16bit for dynamic reconfiguration
        .daddr_in(daddr_in), //7bit for control/status register addr
        .den_in(den_in), //enable register for reading (active HIGH: value in adc_addr will be routed to adc_out)
        .dwe_in(dwe_in), //enable write
        .drdy_out(drdy_out), // data out is retrieved and ready
        .do_out(d_out), //16bit data read from active register in adc_addr
        // analog input
        .vp_in(vp_in),
        .vn_in(vn_in),
        //conversion status
        // .busy_out(busy_out),
        // .channel_out(channel_out),
        .eoc_out(den_in)
    );
    
    always @(posedge dclk_in)
    begin
        ready_d1 <= drdy_out;
    end

    assign ready_rising = drdy_out && !ready_d1 ? 1'b1 : 1'b0;
    
    always @ (posedge dclk_in) begin
        if(ready_rising == 1'b1)    do_out <= d_out;
    end
endmodule