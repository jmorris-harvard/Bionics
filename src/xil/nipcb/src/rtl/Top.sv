`timescale 1ns / 1ps
module Top (
	// Clocks and Resets
	input wire CLK,
	input wire RESETn,

	// Core Debug Signals
	input wire SWCLKTCK,
	input wire SWRSTn,
	// input wire nTRST,
	input wire SWDITMS,
	// input wire TDI,
	output wire SWDO,
	output wire SWDOEN,
	// output wire TDO,
	// output wire nTDOEN,

	// Exposed flash
	output wire flash_mclk,
	output wire flash_mresetn,
	output wire flash_men,
	output wire [31:0] flash_maddr,
	output wire [31:0] flash_mdin,
	output wire [3:0] flash_mwe,
	input wire [31:0] flash_mdout,

	// Exposed sram
	output wire sram_mclk,
	output wire sram_mresetn,
	output wire sram_men,
	output wire [31:0] sram_maddr,
	output wire [31:0] sram_mdin,
	output wire [3:0] sram_mwe,
	input wire [31:0] sram_mdout,

	output [0:0] nipcb_0_ni_csn_hp_dac,
	output [0:0] nipcb_0_ni_csn_adc,
	inout [0:0] nipcb_0_ni_sdio,
	output [0:0] nipcb_0_ni_sclk,
	output [2:0] nipcb_0_ni_pga_gain,
	output [3:0] nipcb_0_ni_sel_ch,
	output [3:0] nipcb_0_ni_en_ch,

	output [7:0] led_0_led_gpio
);

	// Signals
	// -- Core
	wire		mcu_clk;
	wire		mcu_hresetn;
	wire		mcu_hsel = 1'b1;
	wire [31:0] mcu_haddr;
	wire [2:0] mcu_hburst;
	wire		mcu_hmastlock;
	wire [3:0] mcu_hprot;
	wire [2:0] mcu_hsize;
	wire [1:0] mcu_htrans;
	wire [31:0] mcu_hwdata;
	wire		mcu_hwrite;
	wire [31:0] mcu_hrdata;
	wire		mcu_hready;
	wire		mcu_hresp;
	wire		mcu_hmaster;
	wire		mcu_dbgrestart = 1'b0;
	wire		mcu_edbgrq = 1'b0;
	wire		mcu_nmi = 1'b0;
	wire [31:0] mcu_irq;

	// -- flash
	wire flash_hclk;
	wire flash_hresetn;
	wire [31:0] flash_haddr;
	wire [2:0] flash_hburst;
	wire flash_hmastlock;
	wire [3:0] flash_hprot;
	wire [2:0] flash_hsize;
	wire [1:0] flash_htrans;
	wire [31:0] flash_hwdata;
	wire flash_hwrite;
	wire flash_hsel;
	wire flash_hready;
	wire [31:0] flash_hrdata;
	wire flash_hresp;

	// -- sram
	wire sram_hclk;
	wire sram_hresetn;
	wire [31:0] sram_haddr;
	wire [2:0] sram_hburst;
	wire sram_hmastlock;
	wire [3:0] sram_hprot;
	wire [2:0] sram_hsize;
	wire [1:0] sram_htrans;
	wire [31:0] sram_hwdata;
	wire sram_hwrite;
	wire sram_hsel;
	wire sram_hready;
	wire [31:0] sram_hrdata;
	wire sram_hresp;

	// -- nipcb_0
	wire nipcb_0_hclk;
	wire nipcb_0_hresetn;
	wire [31:0] nipcb_0_haddr;
	wire [2:0] nipcb_0_hburst;
	wire nipcb_0_hmastlock;
	wire [3:0] nipcb_0_hprot;
	wire [2:0] nipcb_0_hsize;
	wire [1:0] nipcb_0_htrans;
	wire [31:0] nipcb_0_hwdata;
	wire nipcb_0_hwrite;
	wire nipcb_0_hsel;
	wire nipcb_0_hready;
	wire [31:0] nipcb_0_hrdata;
	wire nipcb_0_hresp;
	wire nipcb_0_irq;

	// -- led_0
	wire led_0_hclk;
	wire led_0_hresetn;
	wire [31:0] led_0_haddr;
	wire [2:0] led_0_hburst;
	wire led_0_hmastlock;
	wire [3:0] led_0_hprot;
	wire [2:0] led_0_hsize;
	wire [1:0] led_0_htrans;
	wire [31:0] led_0_hwdata;
	wire led_0_hwrite;
	wire led_0_hsel;
	wire led_0_hready;
	wire [31:0] led_0_hrdata;
	wire led_0_hresp;

	// Routing
	// -- Core
	assign mcu_clk = CLK;
	assign mcu_irq[0] = nipcb_0_irq;
	assign mcu_irq[31:1] = {(31){1'b0}};

	// -- flash
	assign flash_hclk = mcu_clk;
	assign flash_hresetn = mcu_hresetn;
	assign flash_hmastlock = 1'b0;

	// -- sram
	assign sram_hclk = mcu_clk;
	assign sram_hresetn = mcu_hresetn;
	assign sram_hmastlock = 1'b0;

	// -- nipcb_0
	assign nipcb_0_hclk = mcu_clk;
	assign nipcb_0_hresetn = mcu_hresetn;
	assign nipcb_0_hmastlock = 1'b0;

	// -- led_0
	assign led_0_hclk = mcu_clk;
	assign led_0_hresetn = mcu_hresetn;
	assign led_0_hmastlock = 1'b0;

	// Instantiations
	// -- Core
	CM0DbgAHB #(
		.ACG (0),
		.BE (0),
		.BKPT (4),
		.DBG (1),
		.JTAGnSW (0),
		.NUMIRQ (32),
		.RAR (0),
		.SMUL (0),
		.SYST (1),
		.WIC (1),
		.WICLINES (34),
		.WPT (2)
	) u_core (
		.CLK (mcu_clk),
		.SWCLKTCK (SWCLKTCK),
		.SWRSTn (SWRSTn),
		.nTRST (1'b1),
		.SYSRESETn (RESETn),
		.HRESETn (mcu_hresetn),

		.SWDITMS (SWDITMS),
		.TDI (1'b0),
		.SWDO (SWDO),
		.SWDOEN (SWDOEN),
		.TDO (),
		.nTDOEN (),
		.DBGRESTART (mcu_dbgrestart),
		.DBGRESTARTED (DBGRESTARTED),
		.EDBGRQ (mcu_edbgrq),
		.HALTED (HALTED),

		.HADDR (mcu_haddr),
		.HBURST (mcu_hburst),
		.HMASTLOCK (mcu_mastlock),
		.HPROT (mcu_hprot),
		.HSIZE (mcu_hsize),
		.HTRANS (mcu_htrans),
		.HWDATA (mcu_hwdata),
		.HWRITE (mcu_hwrite),
		.HRDATA (mcu_hrdata),
		.HREADY (mcu_hready),
		.HRESP (mcu_hresp),
		.HMASTER (mcu_hmaster),

		.NMI (mcu_nmi),
		.IRQ (mcu_irq),
		.LOCKUP (LOCKUP)
	);

	// Interconnect
	ahb_interconnect #(
		.DATA_WIDTH (32),
		.ADDR_WIDTH (32),

		.M0_PASSTHROUGH (0),
		.M0_BASEADDR (32'h0000_0000),
		.M0_SIZE (32'h0000_8000),

		.M1_PASSTHROUGH (0),
		.M1_BASEADDR (32'h2000_0000),
		.M1_SIZE (32'h0000_2000),

		.M2_PASSTHROUGH (0),
		.M2_BASEADDR (32'h4000_0000),
		.M2_SIZE (32'h0000_1000),

		.M3_PASSTHROUGH (0),
		.M3_BASEADDR (32'h4000_1000),
		.M3_SIZE (32'h0000_1000)
	) u_interconnect (
		.HCLK (mcu_clk),
		.HRESETn (mcu_hresetn),

		.S0_HSEL (mcu_hsel),
		.S0_HADDR (mcu_haddr),
		.S0_HWRITE (mcu_hwrite),
		.S0_HSIZE (mcu_hsize),
		.S0_HBURST (mcu_hburst),
		.S0_HPROT (mcu_hprot),
		.S0_HTRANS (mcu_htrans),
		.S0_HMASTLOCK (mcu_hmastlock),
		.S0_HWDATA (mcu_hwdata),
		.S0_HREADY (mcu_hready),
		.S0_HRESP (mcu_hresp),
		.S0_HRDATA (mcu_hrdata),

		.M0_HSEL (flash_hsel),
		.M0_HADDR (flash_haddr),
		.M0_HWRITE (flash_hwrite),
		.M0_HSIZE (flash_hsize),
		.M0_HBURST (flash_hburst),
		.M0_HPROT (flash_hprot),
		.M0_HTRANS (flash_htrans),
		.M0_HMASTLOCK (flash_hmastlock),
		.M0_HWDATA (flash_hwdata),
		.M0_HREADY (flash_hready),
		.M0_HRESP (flash_hresp),
		.M0_HRDATA (flash_hrdata),

		.M1_HSEL (sram_hsel),
		.M1_HADDR (sram_haddr),
		.M1_HWRITE (sram_hwrite),
		.M1_HSIZE (sram_hsize),
		.M1_HBURST (sram_hburst),
		.M1_HPROT (sram_hprot),
		.M1_HTRANS (sram_htrans),
		.M1_HMASTLOCK (sram_hmastlock),
		.M1_HWDATA (sram_hwdata),
		.M1_HREADY (sram_hready),
		.M1_HRESP (sram_hresp),
		.M1_HRDATA (sram_hrdata),

		.M2_HSEL (nipcb_0_hsel),
		.M2_HADDR (nipcb_0_haddr),
		.M2_HWRITE (nipcb_0_hwrite),
		.M2_HSIZE (nipcb_0_hsize),
		.M2_HBURST (nipcb_0_hburst),
		.M2_HPROT (nipcb_0_hprot),
		.M2_HTRANS (nipcb_0_htrans),
		.M2_HMASTLOCK (nipcb_0_hmastlock),
		.M2_HWDATA (nipcb_0_hwdata),
		.M2_HREADY (nipcb_0_hready),
		.M2_HRESP (nipcb_0_hresp),
		.M2_HRDATA (nipcb_0_hrdata),

		.M3_HSEL (led_0_hsel),
		.M3_HADDR (led_0_haddr),
		.M3_HWRITE (led_0_hwrite),
		.M3_HSIZE (led_0_hsize),
		.M3_HBURST (led_0_hburst),
		.M3_HPROT (led_0_hprot),
		.M3_HTRANS (led_0_htrans),
		.M3_HMASTLOCK (led_0_hmastlock),
		.M3_HWDATA (led_0_hwdata),
		.M3_HREADY (led_0_hready),
		.M3_HRESP (led_0_hresp),
		.M3_HRDATA (led_0_hrdata)
	);

	mem_ahb_interpreter #(
		.DATA_WIDTH (32),
		.MEM_BYTES (32'h0000_8000)
	) flash_mem_interpreter_inst (
		.HCLK (flash_hclk),
		.HRESETn (flash_hresetn),

		.HADDR (flash_haddr),
		.HBURST (flash_hburst),
		.HPROT (flash_hprot),
		.HSIZE (flash_hsize),
		.HTRANS (flash_htrans),
		.HMASTLOCK (flash_hmastlock),
		.HWDATA (flash_hwdata),
		.HWRITE (flash_hwrite),
		.HSEL (flash_hsel),
		.HREADYIN (flash_hready),
		.HRDATA (flash_hrdata),
		.HREADYOUT (flash_hready),
		.HRESP (flash_hresp),

		.MCLK (flash_mclk),
		.MRESETn (flash_mresetn),
		.MEN (flash_men),
		.MADDR (flash_maddr),
		.MDIN (flash_mdin),
		.MWE (flash_mwe),
		.MDONE (1'b1),
		.MERROR (1'b0),
		.MDOUT (flash_mdout)
	);

	mem_ahb_interpreter #(
		.DATA_WIDTH (32),
		.MEM_BYTES (32'h0000_2000)
	) sram_mem_interpreter_inst (
		.HCLK (sram_hclk),
		.HRESETn (sram_hresetn),

		.HADDR (sram_haddr),
		.HBURST (sram_hburst),
		.HPROT (sram_hprot),
		.HSIZE (sram_hsize),
		.HTRANS (sram_htrans),
		.HMASTLOCK (sram_hmastlock),
		.HWDATA (sram_hwdata),
		.HWRITE (sram_hwrite),
		.HSEL (sram_hsel),
		.HREADYIN (sram_hready),
		.HRDATA (sram_hrdata),
		.HREADYOUT (sram_hready),
		.HRESP (sram_hresp),

		.MCLK (sram_mclk),
		.MRESETn (sram_mresetn),
		.MEN (sram_men),
		.MADDR (sram_maddr),
		.MDIN (sram_mdin),
		.MWE (sram_mwe),
		.MDONE (1'b1),
		.MERROR (1'b0),
		.MDOUT (sram_mdout)
	);

	nipcb_ahb #(
		.DATA_WIDTH (32)
	) nipcb_0_inst (
		.HCLK (nipcb_0_hclk),
		.HRESETn (nipcb_0_hresetn),

		.HADDR (nipcb_0_haddr),
		.HBURST (nipcb_0_hburst),
		.HPROT (nipcb_0_hprot),
		.HSIZE (nipcb_0_hsize),
		.HTRANS (nipcb_0_htrans),
		.HMASTLOCK (nipcb_0_hmastlock),
		.HWDATA (nipcb_0_hwdata),
		.HWRITE (nipcb_0_hwrite),
		.HSEL (nipcb_0_hsel),
		.HREADYIN (nipcb_0_hready),
		.HRDATA (nipcb_0_hrdata),
		.HREADYOUT (nipcb_0_hready),
		.HRESP (nipcb_0_hresp),
		.ni_csn_hp_dac (nipcb_0_ni_csn_hp_dac),
		.ni_csn_adc (nipcb_0_ni_csn_adc),
		.ni_sdio (nipcb_0_ni_sdio),
		.ni_sclk (nipcb_0_ni_sclk),
		.ni_pga_gain (nipcb_0_ni_pga_gain),
		.ni_sel_ch (nipcb_0_ni_sel_ch),
		.ni_en_ch (nipcb_0_ni_en_ch),
		.IRQ (nipcb_0_irq)
	);

	led_ahb #(
		.DATA_WIDTH (32)
	) led_0_inst (
		.HCLK (led_0_hclk),
		.HRESETn (led_0_hresetn),

		.HADDR (led_0_haddr),
		.HBURST (led_0_hburst),
		.HPROT (led_0_hprot),
		.HSIZE (led_0_hsize),
		.HTRANS (led_0_htrans),
		.HMASTLOCK (led_0_hmastlock),
		.HWDATA (led_0_hwdata),
		.HWRITE (led_0_hwrite),
		.HSEL (led_0_hsel),
		.HREADYIN (led_0_hready),
		.HRDATA (led_0_hrdata),
		.HREADYOUT (led_0_hready),
		.HRESP (led_0_hresp),
		.led_gpio (led_0_led_gpio)
	);

endmodule
