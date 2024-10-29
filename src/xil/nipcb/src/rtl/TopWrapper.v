//------------------------------------------------------------------------
// TopWrapper.v
//------------------------------------------------------------------------
`default_nettype none
`timescale 1ns / 1ps

module TopWrapper (
    input  wire [4:0]  okUH,
    output wire [2:0]  okHU,
    inout  wire [31:0] okUHU,
    inout  wire        okAA,
    
    // -- ios
    input  wire        sys_clkn,
    input  wire        sys_clkp,
    
    // nicpcb ports
    output wire nipcb_0_ni_csn_hp_dac,
    output wire nipcb_0_ni_csn_adc,
    inout wire nipcb_0_ni_sdio,
    output wire nipcb_0_ni_sclk,
    output wire [2:0] nipcb_0_ni_pga_gain,
    output wire [3:0] nipcb_0_ni_sel_ch,
    output wire [3:0] nipcb_0_ni_en_ch,

    // led
    output wire [7:0]    led
);

// signals
// -- ok library
wire        okClk;
wire[112:0] okHE;
wire[64:0]  okEH;

// --- wires
// ---- ins
wire [31:0] wire_in_00; // configuration
// wire_in_00[0] = reset (active high)
// wire_in_00[1] = program_reset (active high)
// wire_in_00[2] = write_mem (active high)

wire [31:0] wire_in_01; // reading byte count

// ---- outs
wire  [31:0] wire_out_20;

// --- triggers

// --- Pipes
// ---- Ins
wire [31:0] pipe_in_data;
wire        pipe_in_write;

// ---- Outs
wire [31:0] pipe_out_data;
wire        pipe_out_read;

// --- Globals
wire        core_clk;
wire        sys_clk;

wire        reset;
wire        program_reset;

// -- memories
wire flash_mclk;
wire flash_mresetn;
wire flash_men;
wire [31:0] flash_maddr;
wire [31:0] flash_mdin;
wire [3:0] flash_mwe;
wire [31:0] flash_mdout;

wire sram_mclk;
wire sram_mresetn;
wire sram_men;
wire [31:0] sram_maddr;
wire [31:0] sram_mdin;
wire [3:0] sram_mwe;
wire [31:0] sram_mdout;

// --- programming port
wire clka;
wire wea;
wire ena;
wire [31:0] dina;
wire [31:0] adra;
wire [31:0] douta;

reg         web;
reg  [31:0] addrb;
wire  [31:0] dinb;
wire [31:0] doutb;

// --- fifo
wire write_mem;

wire pipe_in_full;
wire pipe_in_empty;

wire pipe_out_full;
wire pipe_out_empty;
reg pipe_out_wr;

// --- led gpio
wire [7:0] led_0_led_gpio;

// logic
// -- globals
assign reset          = wire_in_00[0];
assign program_reset  = wire_in_00[1];

genvar i;
generate
for (i = 0; i < 8; i = i + 1) begin
  assign led[i] = ( program_reset ) ? ( addrb[i + 2] ) ? 1'b0 : 1'bz : 
                  ( led_0_led_gpio[i] ) ? 1'b0 : 1'bz;
end
endgenerate

// -- prog port
assign clka = ( ~program_reset ) ? flash_mclk : core_clk;
assign adra = ( ~program_reset ) ? flash_maddr : addrb;
assign dina = ( ~program_reset ) ? flash_mdin : dinb;
assign wea =  ( ~program_reset ) ? |flash_mwe : web;
assign ena =  ( ~program_reset ) ? flash_men : 1'b1;

assign flash_mdout = douta;
assign doutb = douta;

// -- fifo
assign write_mem      = wire_in_00[2];

// instantiations
// -- sys clock
IBUFGDS osc_clk_buf(.O(sys_clk), .I(sys_clkp), .IB(sys_clkn));

// -- clock wizard
wizard wiz_inst (
  .clk_out1 (core_clk),
  .clk_in1  (sys_clk)
);

// -- memories
rom rom_inst (
  .addra  (adra[31:2]),
  .ena    (ena),
  .dina   (dina),
  .clka   (clka),
  .wea    (wea),
  .douta  (douta)
);

ram ram_inst (
  .addra  (sram_maddr[31:2]),
  .ena    (sram_men),
  .dina   (sram_mdin),
  .clka   (sram_mclk),
  .wea    (|sram_mwe),
  .douta  (sram_mdout)
);

// -- top module
Top Top_inst (
  // globals
  .CLK (core_clk),
  .RESETn (~reset & ~program_reset),

  // SWD / JTAG
  .SWCLKTCK (1'b0), // input tie low
  .SWRSTn (1'b1), // reset tie high (active low)
  .SWDITMS (1'b0), // input tie low
  .SWDO (), // output ignore
  .SWDOEN (), // output ignore

  // program memory
  .flash_mclk (flash_mclk),
  .flash_mresetn (flash_mresetn),
  .flash_men (flash_men),
  .flash_maddr (flash_maddr),
  .flash_mdin (flash_mdin),
  .flash_mwe (flash_mwe),
  .flash_mdout (flash_mdout),

  // data memory
  .sram_mclk (sram_mclk),
  .sram_mresetn (sram_mresetn),
  .sram_men (sram_men),
  .sram_maddr (sram_maddr),
  .sram_mdin (sram_mdin),
  .sram_mwe (sram_mwe),
  .sram_mdout (sram_mdout),

  // nipcb
  .nipcb_0_ni_csn_hp_dac (nipcb_0_ni_csn_hp_dac),
  .nipcb_0_ni_csn_adc (nipcb_0_ni_csn_adc),
  .nipcb_0_ni_sdio (nipcb_0_ni_sdio),
  .nipcb_0_ni_sclk (nipcb_0_ni_sclk),
  .nipcb_0_ni_pga_gain (nipcb_0_ni_pga_gain),
  .nipcb_0_ni_sel_ch (nipcb_0_ni_sel_ch),
  .nipcb_0_ni_en_ch (nipcb_0_ni_en_ch),

  // led
  .led_0_led_gpio (led_0_led_gpio)
);

// -- fifo
fifo pipe_in_fifo (
  .rst (~program_reset),
  .wr_clk (okClk),
  .rd_clk (core_clk),
  .din (pipe_in_data),
  .wr_en (pipe_in_write),
  .rd_en (web),
  .dout (dinb),
  .full (pipe_in_full),
  .empty (pipe_in_empty),
  .wr_rst_busy (),
  .rd_rst_busy ()
);

fifo pipe_out_fifo (
  .rst (~program_reset),
  .wr_clk (core_clk),
  .rd_clk (okClk),
  .din (doutb),
  .wr_en (pipe_out_wr),
  .rd_en (pipe_out_read),
  .dout (pipe_out_data),
  .full (pipe_out_full),
  .empty (pipe_out_empty),
  .wr_rst_busy (),
  .rd_rst_busy ()
);

// state machines
// -- programming
localparam ROMSIZE = 32'h8000; 
always @(posedge core_clk) begin
  if ( ~program_reset ) begin
    addrb <= 32'hFFFFFFFC;
  end else begin
    web <= 1'b0;
    if ( write_mem ) begin 
      if ( ~pipe_in_empty & ~web ) begin
        addrb <= addrb + 32'h4;
        web <= 1'b1;
      end
    end else begin 
      if ( addrb != ROMSIZE ) begin
        addrb <= addrb + 32'h4;
        pipe_out_wr <= 1'b1;
      end
    end
  end
end 

// OK Library
localparam nEHx = 3;
wire [65*nEHx-1:0]  okEHx;
okHost okHI(
	.okUH(okUH),
	.okHU(okHU),
	.okUHU(okUHU),
	.okAA(okAA),
	.okClk(okClk),
	.okHE(okHE),
	.okEH(okEH)
);

okWireOR # (.N(nEHx)) wireOR (okEH, okEHx);

// Wire Ins -- 0x00 - 0x1F
okWireIn     ep00 (.okHE(okHE),                             .ep_addr(8'h00), .ep_dataout(wire_in_00));

// Wire Outs -- 0x20 - 0x3F 
okWireOut    ep20 (.okHE(okHE), .okEH(okEHx[ 0*65 +: 65 ]), .ep_addr(8'h20), .ep_datain(wire_out_20));

// Pipe Ins -- 0x80 - 0x9F
okPipeIn     ep80 (.okHE(okHE), .okEH(okEHx[ 1*65 +: 65 ]), .ep_addr(8'h80), .ep_write(pipe_in_write), .ep_dataout(pipe_in_data));

// Pipe Outs -- 0xA0 - 0xBF
okPipeOut    epA0 (.okHE(okHE), .okEH(okEHx[ 2*65 +: 65 ]), .ep_addr(8'hA0), .ep_read(pipe_out_read),   .ep_datain(pipe_out_data));

endmodule
