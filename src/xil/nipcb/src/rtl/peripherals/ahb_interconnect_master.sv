/**************************************************************************//**
 * @file     ahb_interconnect_master.sv
 * @brief    Decyphers requests to the AHB bus
 *           and activates on the correct address space
 * @version  v0.1
 * @author   gkyriazidis
 * @date     10. March 2023
 *
 * @notes
 *
 ******************************************************************************/


module ahb_interconnect_master
#(
	parameter DATA_WIDTH = 32,
	parameter ADDR_WIDTH = 32,

	parameter PASSTHROUGH = 0,
	parameter BASEADDR = 32'h0000_0000,
	parameter SIZE     = 1024*1024
)
(
	// COMMON
	input  wire        HCLK,
	input  wire        HRESETn,

	// SLAVE
	input  wire        S_HSEL,
	input  wire [ADDR_WIDTH-1:0]  S_HADDR,
	input  wire        S_HWRITE,
	input  wire [2:0]  S_HSIZE,
	input  wire [2:0]  S_HBURST,
	input  wire [3:0]  S_HPROT,
	input  wire [1:0]  S_HTRANS,
	input  wire        S_HMASTLOCK,
	input  wire [DATA_WIDTH-1:0]  S_HWDATA,

	output wire        S_HREADY,
	output wire        S_HRESP,
	output wire [DATA_WIDTH-1:0]  S_HRDATA,

	//MASTER
	output wire        M_HSEL,
	output wire [ADDR_WIDTH-1:0]  M_HADDR,
	output wire        M_HWRITE,
	output wire [2:0]  M_HSIZE,
	output wire [2:0]  M_HBURST,
	output wire [3:0]  M_HPROT,
	output wire [1:0]  M_HTRANS,
	output wire        M_HMASTLOCK,
	output wire [DATA_WIDTH-1:0]  M_HWDATA,

	input  wire        M_HREADY,
	input  wire        M_HRESP,
	input  wire [DATA_WIDTH-1:0]  M_HRDATA,
	
	output wire        M_HREADYen,
	output wire        M_HRESPen,
	output wire        M_HRDATAen
);
	
	
	// PARAMETERS
	localparam ADDR_HEAD = $clog2(SIZE);


	// SIGNALS
	// -- Inputs
	wire m_hsel;
	reg  m_hsel_prev = 1'b0;
	// -- Outputs
	wire [DATA_WIDTH-1:0] s_hrdata;
	wire s_hresp;
	wire s_hready;
	reg  s_hready_prev = 1'b1;
	// -- Internals
	wire _trans;


	// ROUTING
	// -- Internals
	assign _trans = m_hsel_prev | ~s_hready | ~s_hready_prev;
	// -- Outputs
	// ---- Master
	assign M_HSEL = m_hsel;
	assign M_HRESPen  = _trans;
	assign M_HREADYen = _trans;
	assign M_HRDATAen = _trans;
	// ---- Slave
	assign S_HREADY = s_hready;
	assign S_HRESP  = s_hresp;
	assign S_HRDATA = s_hrdata;
	// -- Tristates
	assign m_hsel = S_HSEL
		          & (
			        (S_HADDR[ADDR_WIDTH-1:ADDR_HEAD] == BASEADDR[ADDR_WIDTH-1:ADDR_HEAD]) |
			        PASSTHROUGH
		          );

	/*
	assign s_hresp = (m_hsel & M_HREADY) ? M_HRESP
		           : 1'bZ;
    assign s_hrdata = (m_hsel_prev & M_HREADY) ? M_HRDATA
		            : {DATA_WIDTH{1'bZ}};
    assign s_hready = m_hsel_prev ? M_HREADY
		            : 1'b1;
    */
    assign s_hresp  = M_HRESP;
    assign s_hrdata = M_HRDATA;
    assign s_hready = M_HREADY;
    
	genvar i;
	bufif1(M_HWRITE,    S_HWRITE,    m_hsel);
	bufif1(M_HMASTLOCK, S_HMASTLOCK, m_hsel);
	generate
        for (i=0; i<$size(S_HADDR); i++) begin
			//bufif1(M_HADDR[i], haddr_m[i], m_hsel);
			bufif1(M_HADDR[i], S_HADDR[i], m_hsel);
		end
        for (i=0; i<$size(S_HSIZE); i++) begin
			bufif1(M_HSIZE[i], S_HSIZE[i], m_hsel);
		end
        for (i=0; i<$size(S_HBURST); i++) begin
			bufif1(M_HBURST[i], S_HBURST[i], m_hsel);
		end
        for (i=0; i<$size(S_HPROT); i++) begin
			bufif1(M_HPROT[i], S_HPROT[i], m_hsel);
		end
        for (i=0; i<$size(S_HTRANS); i++) begin
			bufif1(M_HTRANS[i], S_HTRANS[i], m_hsel);
		end
        for (i=0; i<$size(S_HWDATA); i++) begin
			bufif1(M_HWDATA[i], S_HWDATA[i], m_hsel_prev);
		end
    endgenerate


	// LOGIC
	// -- Retain
	always @ (posedge HCLK) begin
		if (!HRESETn) begin
			m_hsel_prev <= 1'b0;
			s_hready_prev <= 1'b1;
		end
		else begin
			m_hsel_prev <= m_hsel;
			s_hready_prev <= s_hready;
		end
	end


endmodule
