module tb ();

reg [4:0] okUH = 0;
wire [2:0] okHU;
wire [31:0] okUHU;
wire  okAA;

reg tb_reset = 0;
    
wire  sys_clkn;
reg  sys_clkp = 0;
    
wire  nipcb_0_ni_csn_hp_dac;
wire  nipcb_0_ni_csn_adc;
wire  nipcb_0_ni_sdio;
wire  nipcb_0_ni_sclk;
wire [2:0] nipcb_0_ni_pga_gain;
wire [3:0] nipcb_0_ni_sel_ch;
wire [3:0] nipcb_0_ni_en_ch;

wire  nipcb_1_ni_csn_hp_dac;
wire  nipcb_1_ni_csn_adc;
wire  nipcb_1_ni_sdio;
wire  nipcb_1_ni_sclk;
wire [2:0] nipcb_1_ni_pga_gain;
wire [3:0] nipcb_1_ni_sel_ch;
wire [3:0] nipcb_1_ni_en_ch;
wire [7:0] led;

TopWrapper dut (
  .okUH (okUH),
  .okHU (okHU),
  .okUHU (okUHU),
  .okAA (okAA),
    
    // -- ios
  .sys_clkn (sys_clkn),
  .sys_clkp (sys_clkp),

    // -- globals
  .tb_reset (tb_reset),
    
    // nicpcb ports
  .nipcb_0_ni_csn_hp_dac (nipcb_0_ni_csn_hp_dac),
  .nipcb_0_ni_csn_adc (nipcb_0_ni_csn_adc),
  .nipcb_0_ni_sdio (nipcb_0_ni_sdio),
  .nipcb_0_ni_sclk (nipcb_0_ni_sclk),
  .nipcb_0_ni_pga_gain (nipcb_0_ni_pga_gain),
  .nipcb_0_ni_sel_ch (nipcb_0_ni_sel_ch),
  .nipcb_0_ni_en_ch (nipcb_0_ni_en_ch),

    // nicpcb ports
  .nipcb_1_ni_csn_hp_dac (nipcb_1_ni_csn_hp_dac),
  .nipcb_1_ni_csn_adc (nipcb_1_ni_csn_adc),
  .nipcb_1_ni_sdio (nipcb_1_ni_sdio),
  .nipcb_1_ni_sclk (nipcb_1_ni_sclk),
  .nipcb_1_ni_pga_gain (nipcb_1_ni_pga_gain),
  .nipcb_1_ni_sel_ch (nipcb_1_ni_sel_ch),
  .nipcb_1_ni_en_ch (nipcb_1_ni_en_ch),

    // led
  .led (led)
);

assign sys_clkn = ~sys_clkp;

always #5 sys_clkp <= ~sys_clkp;

initial begin
  tb_reset = 1'b1;

  repeat (100) @(posedge sys_clkp) begin end;

  tb_reset = 1'b0;
end

endmodule 
