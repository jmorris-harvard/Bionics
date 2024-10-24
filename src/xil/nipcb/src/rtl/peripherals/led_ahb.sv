module led #(
	parameter integer DATA_WIDTH = 32
) (
	input	CLK,
	input	RESETn,

	// Input Registers
	input		[DATA_WIDTH - 1:0]		I_led_in,

	// Output Registers
	output		[DATA_WIDTH - 1:0]		O_led_out,

	// GPIO
	output		[7:0]		led_gpio
);
	// Routing
	// Custom Implementation

	// -- Begin Custom RTL --

  assign O_led_out = I_led_in;

  assign led_gpio = I_led_in[7:0];

	// -- End Custom RTL --

endmodule

module led_register_io #(
	parameter integer DATA_WIDTH = 32,

	localparam integer TRIG_COUNT = 0,
	localparam integer FLAG_COUNT = 0,
	localparam integer CONF_COUNT = 0,
	localparam integer IREG_COUNT = 1,
	localparam integer OREG_COUNT = 1,
	localparam integer DATA_BYTES = DATA_WIDTH / 8,
	localparam integer REGS_COUNT = TRIG_COUNT + FLAG_COUNT + CONF_COUNT + IREG_COUNT + OREG_COUNT,
	localparam integer ADDR_WIDTH = $clog2 (DATA_BYTES * REGS_COUNT) + 1
) (
	input		CLK,
	input		RESETn,

	input	[ADDR_WIDTH - 1:0]	WADDR,
	input	[DATA_WIDTH - 1:0]	WDATA,
	input		WVALID,
	output		WERROR,

	input	[ADDR_WIDTH - 1:0]	RADDR,
	output	[DATA_WIDTH - 1:0]	RDATA,
	input		RVALID,
	output		RERROR,

	// Peripheral Ports
	output	[7:0]	led_gpio
);

	// Signals
	// -- I/O
	reg werror = 0;
	reg rerror = 0;
	reg [DATA_WIDTH - 1:0] rdata;
	reg winterrupt;
	reg rinterrupt;

	// -- Register File
	reg [DATA_WIDTH - 1:0] iregs	[0:IREG_COUNT - 1];
	reg [DATA_WIDTH - 1:0] oregs	[0:OREG_COUNT - 1];

	// Routing
	assign WERROR = werror;
	assign RERROR = rerror;
	assign RDATA = rdata;

	// Logic
	// -- Read
	always @(*) begin
		if ( ~RESETn ) begin
			rerror <= 1'b0;
		end else begin
			if ( RVALID ) begin
				if ( RADDR < TRIG_COUNT ) begin
					rerror <= 1'b0;
				end else if ( RADDR < TRIG_COUNT + FLAG_COUNT ) begin
					rerror <= 1'b0;
				end else if ( RADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT ) begin
					rerror <= 1'b0;
				end else if ( RADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT + IREG_COUNT ) begin
					rerror <= 1'b0;
				end else if ( RADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT + IREG_COUNT + OREG_COUNT ) begin
					rerror <= 1'b0;
				end else begin
					rerror <= 1'b1;
				end
			end else begin
				rerror <= 1'b0;
			end
		end
	end

	// -- Execute Read
	always @(posedge CLK) begin
		if ( ~RESETn ) begin
			rdata <= 0;
		end else begin
			if ( RVALID && ~rerror ) begin
				if ( RADDR < TRIG_COUNT ) begin
					// No Triggers
				end else if ( RADDR < TRIG_COUNT + FLAG_COUNT ) begin
					// No Flags
				end else if ( RADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT ) begin
					// No Configs
				end else if ( RADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT + IREG_COUNT ) begin
					rdata <= iregs[RADDR - TRIG_COUNT - FLAG_COUNT - CONF_COUNT];
				end else if ( RADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT + IREG_COUNT + OREG_COUNT ) begin
					rdata <= oregs[RADDR - TRIG_COUNT - FLAG_COUNT - CONF_COUNT - IREG_COUNT];
				end
			end
		end
	end

	// -- Write
	always @(*) begin
		if ( ~RESETn ) begin
			werror <= 1'b0;
		end else begin
			if ( WVALID ) begin
				if ( WADDR < TRIG_COUNT ) begin
					werror <= 1'b0;
				end else if ( WADDR < TRIG_COUNT + FLAG_COUNT ) begin
					werror <= 1'b1;
				end else if ( WADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT ) begin
					werror <= 1'b0;
				end else if ( WADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT + IREG_COUNT ) begin
					werror <= 1'b0;
				end else if ( WADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT + IREG_COUNT + OREG_COUNT ) begin
					werror <= 1'b1;
				end else begin
					werror <= 1'b1;
				end
			end else begin
				werror <= 1'b0;
			end
		end
	end

	// -- Execute Write
	always @(posedge CLK) begin
		if ( ~RESETn ) begin
			for ( integer i = 0; i < IREG_COUNT; i = i + 1 ) begin
				iregs[i] = 0;
			end
		end else begin
			if ( WVALID && ~werror ) begin
				if ( WADDR < TRIG_COUNT ) begin
					// No Triggers
				end else if ( WADDR < TRIG_COUNT + FLAG_COUNT ) begin
					// Illegal
				end else if ( WADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT ) begin
					// No Configs
				end else if ( WADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT + IREG_COUNT ) begin
					iregs[RADDR - TRIG_COUNT - FLAG_COUNT - CONF_COUNT] <= WDATA;
				end else if ( WADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT + IREG_COUNT + OREG_COUNT ) begin
					// Illegal
				end
			end
		end
	end

	// Custom Implementation

	// -- Begin Custom RTL --


	// -- End Custom RTL --

	led #(
		.DATA_WIDTH (DATA_WIDTH)	) led_inst (
		.CLK (CLK),
		.RESETn (RESETn),

		.I_led_in (iregs[0]),
		.O_led_out (oregs[0]),

		.led_gpio (led_gpio)
	);

endmodule

module led_ahb_interpreter #(
	parameter integer DATA_WIDTH = 32,
	parameter integer ADDR_BASE = 0,

	localparam integer TRIG_COUNT = 0,
	localparam integer FLAG_COUNT = 0,
	localparam integer CONF_COUNT = 0,
	localparam integer IREG_COUNT = 1,
	localparam integer OREG_COUNT = 1,
	localparam integer DATA_BYTES = DATA_WIDTH / 8,
	localparam integer REGS_COUNT = TRIG_COUNT + FLAG_COUNT + CONF_COUNT + IREG_COUNT + OREG_COUNT,
	localparam integer MEM_BYTES = DATA_BYTES * REGS_COUNT,
	localparam integer ADDR_WIDTH = $clog2 (MEM_BYTES) + 1
) (
	input wire		HCLK,
	input wire		HRESETn,
	input wire [ADDR_WIDTH - 1:0] HADDR,
	input wire [2:0] HBURST,
	input wire		HMASTLOCK,
	input wire [3:0] HPROT,
	input wire [2:0] HSIZE,
	input wire [1:0] HTRANS,
	input wire [DATA_WIDTH - 1:0] HWDATA,
	input wire HWRITE,
	input wire HSEL,
	input wire HREADYIN,
	output wire [DATA_WIDTH - 1:0] HRDATA,
	output wire HREADYOUT,
	output wire HRESP,

	output wire MCLK,
	output wire MRESETn,
	output wire MEN,
	output wire [ADDR_WIDTH - 1:0] MADDR,
	output wire [DATA_WIDTH - 1:0] MDIN,
	output wire [DATA_BYTES - 1:0] MWE,
	input wire MDONE,
	input wire MERROR,
	input wire [DATA_WIDTH - 1:0] MDOUT
);

  `define AHB_RSP_OKAY  1'b0
  `define AHB_RSP_ERROR 1'b1

	// Bus Registers
	reg [ADDR_WIDTH - 1:0] haddr;
	reg [DATA_WIDTH - 1:0] hrdata;
	reg [DATA_WIDTH - 1:0] hwdata;
	reg hresp;

	// Memory Registers
	reg men;
	reg [DATA_BYTES - 1:0] mwe;
	reg [DATA_WIDTH - 1:0] mdin;

	// Transactions
	wire transreq;
	wire transvalid;
	wire transwrite;
	wire transread;

	// Errors
	reg erroraddr;

	// Memory
	wire [ADDR_WIDTH - 1:0] memaddr;
	reg memreq;
	reg memren;
	reg memwen;
	reg [DATA_WIDTH - 1:0] memdout;
	wire memdone;
	reg memerror;

	// Bus Routing
	assign HREADYOUT = memdone | transreq;
	assign HRESP = hresp;
	assign HRDATA = memren ? MDOUT : {DATA_WIDTH{1'bZ}};

	// Memory Routing
	assign MEN = men | transread;
	assign MWE = mwe;
	assign MCLK = HCLK;
	assign MRESETn = HRESETn;
	assign MADDR = transread ? memaddr
		: memwen ? haddr
		: {(ADDR_WIDTH){1'bZ}};
	assign MDIN = ( memwen ? HWDATA : {(DATA_WIDTH){1'bZ}} );

	// Internal Routing
	assign memaddr = HADDR;
	assign memdone = MDONE;
	assign transreq = HSEL & HTRANS[1] & HREADYIN;
	assign transvalid = transreq & ~erroraddr;
	assign transwrite = transvalid & HWRITE;
	assign transread = transvalid & ~HWRITE;
	wire error = erroraddr | MERROR;
	wire rerror = memerror;
	wire werror = memwen & MERROR;

	// Logic
	// -- Memories
	// ---- Enables
	always @(posedge HCLK) begin
		if ( ~HRESETn ) begin
			men <= 1'b0;
			memren <= 1'b0;
			memwen <= 1'b0;
		end else begin
			memreq <= transreq;
			men <= (transwrite | transread) & ~error;
			memren <= transread & ~error;
			memwen <= transwrite & ~error;
			memerror <= erroraddr | error;
		end
	end

	// ---- Write
	always @(posedge HCLK) begin
		if ( ~HRESETn ) begin
			mwe <= {(DATA_BYTES){1'b0}};
		end else begin
			if ( transwrite ) begin
				if ( HSIZE == 3'b010 ) begin
					mwe <= {(DATA_BYTES){1'b1}};
				end else if ( HSIZE == 3'b001 ) begin
					mwe <= {(DATA_BYTES){1'b0}};
					if ( HADDR[1:0] == 2'b00 ) begin
						mwe[1:0] <= 2'b11;
					end else if ( HADDR[1:0] == 2'b01 ) begin
						mwe[2:1] <= 2'b11;
					end else if ( HADDR[1:0] == 2'b10 ) begin
						mwe[3:2] <= 2'b11;
					end
				end else if ( HSIZE == 3'b000 ) begin
					mwe <= {(DATA_BYTES){1'b0}};
					mwe[HADDR[1:0]] <= 1'b1;
				end
			end else begin
				mwe <= {(DATA_BYTES){1'b0}};
			end
		end
	end

	// -- Bus
	// ---- Address
	always @(*) begin
		if ( ~HRESETn ) begin
			 erroraddr <= 1'b0;
		end else begin
			if ( (HADDR >= ADDR_BASE) && (HADDR <= (ADDR_BASE + MEM_BYTES - 1)) ) begin
				erroraddr <= 1'b0;
			end else begin
				erroraddr <= 1'b1;
			end
		end
	end

	// ---- Write
	always @(posedge HCLK) begin
		if ( ~HRESETn ) begin
			haddr <= 0;
			hwdata <= 0;
		end else begin
			haddr <= memaddr;
			hwdata <= HWDATA;
		end
	end

	// ---- Response
	always @(negedge HCLK) begin
		if ( ~HRESETn ) begin
			hresp <= `AHB_RSP_OKAY;
		end else if ( HREADYOUT ) begin
			if ( memreq ) begin
				hresp <= ((rerror | werror) ? `AHB_RSP_ERROR : `AHB_RSP_OKAY);
			end else begin
				hresp <= `AHB_RSP_OKAY;
			end
		end
	end

endmodule

module led_ahb #(
	parameter integer DATA_WIDTH = 32,

	localparam integer TRIG_COUNT = 0,
	localparam integer FLAG_COUNT = 0,
	localparam integer CONF_COUNT = 0,
	localparam integer IREG_COUNT = 1,
	localparam integer OREG_COUNT = 1,
	localparam integer DATA_BYTES = DATA_WIDTH / 8,
	localparam integer REGS_COUNT = TRIG_COUNT + FLAG_COUNT + CONF_COUNT + IREG_COUNT + OREG_COUNT,
	localparam integer MEM_BYTES = DATA_BYTES * REGS_COUNT,
	localparam integer ADDR_WIDTH = $clog2 (MEM_BYTES) + 1,
	localparam integer ADDR_LSB = (DATA_WIDTH / 32) + 1,
	localparam integer ADDR_MSB = ADDR_WIDTH - 1
) (
	input wire		HCLK,
	input wire		HRESETn,
	input wire [ADDR_WIDTH - 1:0] HADDR,
	input wire [2:0] HBURST,
	input wire		HMASTLOCK,
	input wire [3:0] HPROT,
	input wire [2:0] HSIZE,
	input wire [1:0] HTRANS,
	input wire [DATA_WIDTH - 1:0] HWDATA,
	input wire HWRITE,
	input wire HSEL,
	input wire HREADYIN,
	output wire [DATA_WIDTH - 1:0] HRDATA,
	output wire HREADYOUT,
	output wire HRESP,

	// Peripheral Ports
	output	[7:0]	led_gpio
);

	// Signals
	// -- Bus
	wire [ADDR_WIDTH - 1:0] addr;
	wire wren;
	wire rden;
	wire rerror;
	wire werror;

	// -- Memory
	wire memclk;
	wire memresetn;
	wire memen;
	wire [ADDR_WIDTH - 1:0] memaddr;
	wire [DATA_WIDTH - 1:0] memdin;
	wire [(DATA_WIDTH / 8) - 1:0] memwe;
	wire memerror;
	wire [DATA_WIDTH - 1:0] memdout;

	// -- Routing
	assign memerror = werror | rerror;
	assign addr = memaddr [ADDR_MSB:ADDR_LSB];
	assign wren = memen && (memwe != 0);
	assign rden = memen && (memwe == 0);
	// Instantiations
	led_ahb_interpreter #(
		.DATA_WIDTH (DATA_WIDTH)
	) led_ahb_interpreter_inst (
		.HCLK (HCLK),
		.HRESETn (HRESETn),
		.HADDR (HADDR),
		.HBURST (HBURST),
		.HMASTLOCK (HMASTLOCK),
		.HPROT (HPROT),
		.HSIZE (HSIZE),
		.HTRANS (HTRANS),
		.HWDATA (HWDATA),
		.HWRITE (HWRITE),
		.HSEL (HSEL),
		.HREADYIN (HREADYIN),
		.HRDATA (HRDATA),
		.HREADYOUT (HREADYOUT),
		.HRESP (HRESP),
		.MCLK (memclk),
		.MRESETn (memresetn),
		.MEN (memen),
		.MADDR (memaddr),
		.MDIN (memdin),
		.MWE (memwe),
		.MDONE (1'b1),
		.MERROR (memerror),
		.MDOUT (memdout)
	);

	led_register_io #(
		.DATA_WIDTH (DATA_WIDTH)
	) led_register_io_inst (
		.CLK (HCLK),
		.RESETn (HRESETn),

		.WADDR (addr),
		.WDATA (memdin),
		.WVALID (wren),
		.WERROR (werror),
		.RADDR (addr),
		.RDATA (memdout),
		.RVALID (rden),
		.RERROR (rerror),

		.led_gpio (led_gpio)
	);

endmodule
