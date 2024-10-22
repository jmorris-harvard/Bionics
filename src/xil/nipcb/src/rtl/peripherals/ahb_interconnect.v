module ahb_interconnect
#(
	parameter DATA_WIDTH = 32,
	parameter ADDR_WIDTH = 32,

	parameter IDLE_ENABLE = 1,
	parameter IDLE_BASEADDR = 32'hE000_0000,
	parameter IDLE_SIZE = 32'h2000_0000,

	parameter MASTERS_COUNT = 4,

	parameter M0_PASSTHROUGH = 0,
	parameter M0_BASEADDR = 32'h0000_0000,
	parameter M0_SIZE = 32'h0010_0000,

	parameter M1_PASSTHROUGH = 0,
	parameter M1_BASEADDR = 32'h0000_0000,
	parameter M1_SIZE = 32'h0010_0000,

	parameter M2_PASSTHROUGH = 0,
	parameter M2_BASEADDR = 32'h0000_0000,
	parameter M2_SIZE = 32'h0010_0000,

	parameter M3_PASSTHROUGH = 0,
	parameter M3_BASEADDR = 32'h0000_0000,
	parameter M3_SIZE = 32'h0010_0000
)
(
	// COMMON
	input  wire        HCLK,
	input  wire        HRESETn,

	// SLAVES
	// -- #0
	input  wire        S0_HSEL,
	input  wire [ADDR_WIDTH-1:0]  S0_HADDR,
	input  wire        S0_HWRITE,
	input  wire [2:0]  S0_HSIZE,
	input  wire [2:0]  S0_HBURST,
	input  wire [3:0]  S0_HPROT,
	input  wire [1:0]  S0_HTRANS,
	input  wire        S0_HMASTLOCK,
	input  wire [DATA_WIDTH-1:0]  S0_HWDATA,
	input  wire        S0_HMASTER,

	output wire        S0_HREADY,
	output wire        S0_HRESP,
	output wire [DATA_WIDTH-1:0]  S0_HRDATA,

	// MASTERS
	// -- #0
	output wire        M0_HSEL,
	output wire [ADDR_WIDTH-1:0]  M0_HADDR,
	output wire        M0_HWRITE,
	output wire [2:0]  M0_HSIZE,
	output wire [2:0]  M0_HBURST,
	output wire [3:0]  M0_HPROT,
	output wire [1:0]  M0_HTRANS,
	output wire        M0_HMASTLOCK,
	output wire [DATA_WIDTH-1:0]  M0_HWDATA,

	input  wire        M0_HREADY,
	input  wire        M0_HRESP,
	input  wire [DATA_WIDTH-1:0]  M0_HRDATA,

	// -- #1
	output wire        M1_HSEL,
	output wire [ADDR_WIDTH-1:0]  M1_HADDR,
	output wire        M1_HWRITE,
	output wire [2:0]  M1_HSIZE,
	output wire [2:0]  M1_HBURST,
	output wire [3:0]  M1_HPROT,
	output wire [1:0]  M1_HTRANS,
	output wire        M1_HMASTLOCK,
	output wire [DATA_WIDTH-1:0]  M1_HWDATA,

	input  wire        M1_HREADY,
	input  wire        M1_HRESP,
	input  wire [DATA_WIDTH-1:0]  M1_HRDATA,

	// -- #2
	output wire        M2_HSEL,
	output wire [ADDR_WIDTH-1:0]  M2_HADDR,
	output wire        M2_HWRITE,
	output wire [2:0]  M2_HSIZE,
	output wire [2:0]  M2_HBURST,
	output wire [3:0]  M2_HPROT,
	output wire [1:0]  M2_HTRANS,
	output wire        M2_HMASTLOCK,
	output wire [DATA_WIDTH-1:0]  M2_HWDATA,

	input  wire        M2_HREADY,
	input  wire        M2_HRESP,
	input  wire [DATA_WIDTH-1:0]  M2_HRDATA,

	// -- #3
	output wire        M3_HSEL,
	output wire [ADDR_WIDTH-1:0]  M3_HADDR,
	output wire        M3_HWRITE,
	output wire [2:0]  M3_HSIZE,
	output wire [2:0]  M3_HBURST,
	output wire [3:0]  M3_HPROT,
	output wire [1:0]  M3_HTRANS,
	output wire        M3_HMASTLOCK,
	output wire [DATA_WIDTH-1:0]  M3_HWDATA,

	input  wire        M3_HREADY,
	input  wire        M3_HRESP,
	input  wire [DATA_WIDTH-1:0]  M3_HRDATA
);


	// INCLUDES
	`include "ahb_defs.v"


	// PARAMETERS
	localparam M_PASSTHROUGH = ( MASTERS_COUNT > 0 ? M0_PASSTHROUGH : 0 )
	                        || ( MASTERS_COUNT > 1 ? M1_PASSTHROUGH : 0 )
	                        || ( MASTERS_COUNT > 2 ? M2_PASSTHROUGH : 0 )
	                        || ( MASTERS_COUNT > 3 ? M3_PASSTHROUGH : 0 );
	localparam IDLE_HEAD = $clog2(IDLE_SIZE);


	// SIGNALS
	// -- Common
	wire        hsel;
	wire [ADDR_WIDTH-1:0]  haddr;
	wire        hwrite;
	wire [2:0]  hsize;
	wire [2:0]  hburst;
	wire [3:0]  hprot;
	wire [1:0]  htrans;
	wire        hmastlock;
	wire [DATA_WIDTH-1:0]  hwdata;
	wire        hmaster;

	wire        hready;
	wire        hresp;
	wire [DATA_WIDTH-1:0]  hrdata;

	reg         _trans;
	reg         _idle;
	reg         _debugger;
	// -- Masters
	// ---- #0
	wire        m0_hready;
	wire        m0_hready_en;
	wire        m0_hresp;
	wire        m0_hresp_en;
	wire [DATA_WIDTH-1:0]  m0_hrdata;
	wire        m0_hrdata_en;
	// ---- #1
	wire        m1_hready;
	wire        m1_hready_en;
	wire        m1_hresp;
	wire        m1_hresp_en;
	wire [DATA_WIDTH-1:0]  m1_hrdata;
	wire        m1_hrdata_en;
	// ---- #2
	wire        m2_hready;
	wire        m2_hready_en;
	wire        m2_hresp;
	wire        m2_hresp_en;
	wire [DATA_WIDTH-1:0]  m2_hrdata;
	wire        m2_hrdata_en;
	// ---- #3
	wire        m3_hready;
	wire        m3_hready_en;
	wire        m3_hresp;
	wire        m3_hresp_en;
	wire [DATA_WIDTH-1:0]  m3_hrdata;
	wire        m3_hrdata_en;


	// ROUTING
	// -- Slaves
	assign hsel      = S0_HSEL;
	assign haddr     = S0_HADDR;
	assign hwrite    = S0_HWRITE;
	assign hsize     = S0_HSIZE;
	assign hburst    = S0_HBURST;
	assign hprot     = S0_HPROT;
	assign htrans    = S0_HTRANS;
	assign hmastlock = S0_HMASTLOCK;
	assign hwdata    = S0_HWDATA;
	assign hmaster   = S0_HMASTER;
	assign S0_HREADY = hready;
	assign S0_HRESP  = hresp;
	assign S0_HRDATA = hrdata;
	// -- Masters
	assign hresp = m0_hresp_en ? M0_HRESP
	             : m1_hresp_en ? M1_HRESP
	             : m2_hresp_en ? M2_HRESP
	             : m3_hresp_en ? M3_HRESP
	             : (!M_PASSTHROUGH & !_idle & !_debugger && _trans) ? `AHB_RSP_ERROR
	             : `AHB_RSP_OKAY;
	assign hready = m0_hready_en ? M0_HREADY
	              : m1_hready_en ? M1_HREADY
	              : m2_hready_en ? M2_HREADY
	              : m3_hready_en ? M3_HREADY
	              : (!M_PASSTHROUGH & !_idle & !_debugger && _trans) ? 1'b0
	              : 1'b1;
	assign hrdata = m0_hrdata_en ? M0_HRDATA
	              : m1_hrdata_en ? M1_HRDATA
	              : m2_hrdata_en ? M2_HRDATA
	              : m3_hrdata_en ? M3_HRDATA
				  : {DATA_WIDTH{1'bZ}};


	// LOGIC
	// -- Idle
	always @ (posedge HCLK) begin
		if ( !HRESETn ) begin
			_idle <= 1'b0;
			_debugger <= 1'b0;
			_trans <= 1'b0;
		end
		else begin
			_idle <= (IDLE_ENABLE ? haddr[ADDR_WIDTH-1:IDLE_HEAD] == IDLE_BASEADDR[ADDR_WIDTH-1:IDLE_HEAD] : 1'b0);
			_debugger <= (hmaster == 1'b1);
			_trans <= (htrans != 2'b00);
		end
	end


	// INSTANTIATIONS
	// -- Masters
	generate
		if ( MASTERS_COUNT > 0 ) begin
			ahb_interconnect_master #(
				.DATA_WIDTH (DATA_WIDTH),
				.ADDR_WIDTH (ADDR_WIDTH),
				.PASSTHROUGH(M0_PASSTHROUGH),
				.BASEADDR   (M0_BASEADDR),
				.SIZE       (M0_SIZE)
			) M0 (
				.HCLK   (HCLK),
				.HRESETn(HRESETn),

				.S_HADDR    (haddr),
				.S_HBURST   (hburst),
				.S_HMASTLOCK(hmastlock),
				.S_HPROT    (hprot),
				.S_HSIZE    (hsize),
				.S_HTRANS   (htrans),
				.S_HWDATA   (hwdata),
				.S_HWRITE   (hwrite),
				.S_HSEL     (hsel),

				.S_HRDATA(m0_hrdata),
				.S_HREADY(m0_hready),
				.S_HRESP (m0_hresp),

				.M_HADDR    (M0_HADDR),
				.M_HBURST   (M0_HBURST),
				.M_HMASTLOCK(M0_HMASTLOCK),
				.M_HPROT    (M0_HPROT),
				.M_HSIZE    (M0_HSIZE),
				.M_HTRANS   (M0_HTRANS),
				.M_HWDATA   (M0_HWDATA),
				.M_HWRITE   (M0_HWRITE),
				.M_HSEL     (M0_HSEL),

				.M_HRDATA(M0_HRDATA),
				.M_HREADY(M0_HREADY),
				.M_HRESP (M0_HRESP),

				.M_HREADYen(m0_hready_en),
				.M_HRESPen (m0_hresp_en),
				.M_HRDATAen(m0_hrdata_en)
			);
		end
		else begin
			assign m0_hready_en = 0;
			assign m0_hresp_en = 0;
			assign m0_hrdata_en = 0;
		end
	endgenerate
	generate
		if ( MASTERS_COUNT > 1 ) begin
			ahb_interconnect_master #(
				.DATA_WIDTH (DATA_WIDTH),
				.ADDR_WIDTH (ADDR_WIDTH),
				.PASSTHROUGH(M1_PASSTHROUGH),
				.BASEADDR   (M1_BASEADDR),
				.SIZE       (M1_SIZE)
			) M1 (
				.HCLK   (HCLK),
				.HRESETn(HRESETn),

				.S_HADDR    (haddr),
				.S_HBURST   (hburst),
				.S_HMASTLOCK(hmastlock),
				.S_HPROT    (hprot),
				.S_HSIZE    (hsize),
				.S_HTRANS   (htrans),
				.S_HWDATA   (hwdata),
				.S_HWRITE   (hwrite),
				.S_HSEL     (hsel),

				.S_HRDATA(m1_hrdata),
				.S_HREADY(m1_hready),
				.S_HRESP (m1_hresp),

				.M_HADDR    (M1_HADDR),
				.M_HBURST   (M1_HBURST),
				.M_HMASTLOCK(M1_HMASTLOCK),
				.M_HPROT    (M1_HPROT),
				.M_HSIZE    (M1_HSIZE),
				.M_HTRANS   (M1_HTRANS),
				.M_HWDATA   (M1_HWDATA),
				.M_HWRITE   (M1_HWRITE),
				.M_HSEL     (M1_HSEL),

				.M_HRDATA(M1_HRDATA),
				.M_HREADY(M1_HREADY),
				.M_HRESP (M1_HRESP),

				.M_HREADYen(m1_hready_en),
				.M_HRESPen (m1_hresp_en),
				.M_HRDATAen(m1_hrdata_en)
			);
		end
		else begin
			assign m1_hready_en = 0;
			assign m1_hresp_en = 0;
			assign m1_hrdata_en = 0;
		end
	endgenerate
	generate
		if ( MASTERS_COUNT > 2 ) begin
			ahb_interconnect_master #(
				.DATA_WIDTH (DATA_WIDTH),
				.ADDR_WIDTH (ADDR_WIDTH),
				.PASSTHROUGH(M2_PASSTHROUGH),
				.BASEADDR   (M2_BASEADDR),
				.SIZE       (M2_SIZE)
			) M2 (
				.HCLK   (HCLK),
				.HRESETn(HRESETn),

				.S_HADDR    (haddr),
				.S_HBURST   (hburst),
				.S_HMASTLOCK(hmastlock),
				.S_HPROT    (hprot),
				.S_HSIZE    (hsize),
				.S_HTRANS   (htrans),
				.S_HWDATA   (hwdata),
				.S_HWRITE   (hwrite),
				.S_HSEL     (hsel),

				.S_HRDATA(m2_hrdata),
				.S_HREADY(m2_hready),
				.S_HRESP (m2_hresp),

				.M_HADDR    (M2_HADDR),
				.M_HBURST   (M2_HBURST),
				.M_HMASTLOCK(M2_HMASTLOCK),
				.M_HPROT    (M2_HPROT),
				.M_HSIZE    (M2_HSIZE),
				.M_HTRANS   (M2_HTRANS),
				.M_HWDATA   (M2_HWDATA),
				.M_HWRITE   (M2_HWRITE),
				.M_HSEL     (M2_HSEL),

				.M_HRDATA(M2_HRDATA),
				.M_HREADY(M2_HREADY),
				.M_HRESP (M2_HRESP),

				.M_HREADYen(m2_hready_en),
				.M_HRESPen (m2_hresp_en),
				.M_HRDATAen(m2_hrdata_en)
			);
		end
		else begin
			assign m2_hready_en = 0;
			assign m2_hresp_en = 0;
			assign m2_hrdata_en = 0;
		end
	endgenerate
	generate
		if ( MASTERS_COUNT > 3 ) begin
			ahb_interconnect_master #(
				.DATA_WIDTH (DATA_WIDTH),
				.ADDR_WIDTH (ADDR_WIDTH),
				.PASSTHROUGH(M3_PASSTHROUGH),
				.BASEADDR   (M3_BASEADDR),
				.SIZE       (M3_SIZE)
			) M3 (
				.HCLK   (HCLK),
				.HRESETn(HRESETn),

				.S_HADDR    (haddr),
				.S_HBURST   (hburst),
				.S_HMASTLOCK(hmastlock),
				.S_HPROT    (hprot),
				.S_HSIZE    (hsize),
				.S_HTRANS   (htrans),
				.S_HWDATA   (hwdata),
				.S_HWRITE   (hwrite),
				.S_HSEL     (hsel),

				.S_HRDATA(m3_hrdata),
				.S_HREADY(m3_hready),
				.S_HRESP (m3_hresp),

				.M_HADDR    (M3_HADDR),
				.M_HBURST   (M3_HBURST),
				.M_HMASTLOCK(M3_HMASTLOCK),
				.M_HPROT    (M3_HPROT),
				.M_HSIZE    (M3_HSIZE),
				.M_HTRANS   (M3_HTRANS),
				.M_HWDATA   (M3_HWDATA),
				.M_HWRITE   (M3_HWRITE),
				.M_HSEL     (M3_HSEL),

				.M_HRDATA(M3_HRDATA),
				.M_HREADY(M3_HREADY),
				.M_HRESP (M3_HRESP),

				.M_HREADYen(m3_hready_en),
				.M_HRESPen (m3_hresp_en),
				.M_HRDATAen(m3_hrdata_en)
			);
		end
		else begin
			assign m3_hready_en = 0;
			assign m3_hresp_en = 0;
			assign m3_hrdata_en = 0;
		end
	endgenerate


endmodule
