`timescale 1ps / 1ps

import "DPI-C" function string getenv(input string env_name);

module tb ();
	reg CLK = 1'b0;
	reg RESETn = 1'b1;

	reg SWCLKTCK = 1'b0;
	reg SWRSTn = 1'b1;
	reg nTRST = 1'b1;

	reg SWDITMS = 1'b0;
	wire SWDO;
	wire SWDOEN;

	// -- flash
	wire flash_mclk;
	wire flash_mresetn;
	wire flash_men;
	wire [31:0] flash_maddr;
	wire [31:0] flash_mdin;
	wire [3:0] flash_mwe;
	wire [31:0] flash_mdout;

	// -- sram
	wire sram_mclk;
	wire sram_mresetn;
	wire sram_men;
	wire [31:0] sram_maddr;
	wire [31:0] sram_mdin;
	wire [3:0] sram_mwe;
	wire [31:0] sram_mdout;

	// -- nipcb_0
	wire [0:0] nipcb_0_ni_csn_hp_dac;
	wire [0:0] nipcb_0_ni_csn_adc;
	wire [0:0] nipcb_0_ni_sdio;
	wire [0:0] nipcb_0_ni_sclk;
	wire [2:0] nipcb_0_ni_pga_gain;
	wire [3:0] nipcb_0_ni_sel_ch;
	wire [3:0] nipcb_0_ni_en_ch;

	// -- led_0
	wire [7:0] led_0_led_gpio;

	Top DUT (
		.CLK (CLK),
		.RESETn (RESETn),

		.SWCLKTCK (SWCLKTCK),
		.SWRSTn (SWRSTn),
		.SWDITMS (SWDITMS),
		.SWDO (SWDO),
		.SWDOEN (SWDOEN),

		.flash_mclk (flash_mclk),
		.flash_mresetn (flash_mresetn),
		.flash_men (flash_men),
		.flash_maddr (flash_maddr),
		.flash_mdin (flash_mdin),
		.flash_mwe (flash_mwe),
		.flash_mdout (flash_mdout),

		.sram_mclk (sram_mclk),
		.sram_mresetn (sram_mresetn),
		.sram_men (sram_men),
		.sram_maddr (sram_maddr),
		.sram_mdin (sram_mdin),
		.sram_mwe (sram_mwe),
		.sram_mdout (sram_mdout),

		.nipcb_0_ni_csn_hp_dac (nipcb_0_ni_csn_hp_dac),
		.nipcb_0_ni_csn_adc (nipcb_0_ni_csn_adc),
		.nipcb_0_ni_sdio (nipcb_0_ni_sdio),
		.nipcb_0_ni_sclk (nipcb_0_ni_sclk),
		.nipcb_0_ni_pga_gain (nipcb_0_ni_pga_gain),
		.nipcb_0_ni_sel_ch (nipcb_0_ni_sel_ch),
		.nipcb_0_ni_en_ch (nipcb_0_ni_en_ch),

		.led_0_led_gpio (led_0_led_gpio)
	);

	// --- Begin flash Memory ---

	bram #(
		.MEM_DEPTH (32'h0000_8000),
    .INIT_FILE ("./sim/bram.mem")
	) flash (
		.MCLK (flash_mclk),
		.MRESETn (flash_mresetn),
		.MEN (flash_men),
		.MADDR (flash_maddr),
		.MDIN (flash_mdin),
		.MWE (flash_mwe),
		.MDOUT (flash_mdout)
	);

	// --- End flash Memory ---

	// --- Begin sram Memory ---

	bram #(
		.MEM_DEPTH (32'h0000_4000)
	) sram (
		.MCLK (sram_mclk),
		.MRESETn (sram_mresetn),
		.MEN (sram_men),
		.MADDR (sram_maddr),
		.MDIN (sram_mdin),
		.MWE (sram_mwe),
		.MDOUT (sram_mdout)
	);

	// --- End sram Memory ---

	localparam CLK_PERIOD = 5000;
	always #(CLK_PERIOD / 2) CLK <= ~CLK;

	initial begin
		$display ("Begin Testbench");
    $display ("path = %s", getenv("PWD"));
		repeat (10) @(posedge CLK) begin end;

		RESETn = 1'b0;
		repeat (10) @(posedge CLK) begin end;

		RESETn = 1'b1;
		repeat (10) @(posedge CLK) begin end;

		// Begin Custom Implementation

		repeat (30000) @(posedge CLK) begin end;

		// End Custom Implementation

		$display ("End Testbench");
		$finish();
	end

	initial begin
		$dumpvars (0, tb);
	end

	initial begin
		// Safety Kill Process
		repeat (1000000) @(posedge CLK) begin end;
		$display ("Testbench Timed Out");
		$finish ();
	end

endmodule
