module mem_ahb_interpreter #(
	parameter integer DATA_WIDTH = 32,
	parameter integer ADDR_BASE = 0,
	parameter integer MEM_BYTES = 1024 * 1024,

	localparam integer DATA_BYTES = (DATA_WIDTH / 8),
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
