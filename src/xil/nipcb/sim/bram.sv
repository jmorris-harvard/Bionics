`timescale 1 ps / 1 ps

module bram
#(
    parameter  integer MEM_DEPTH = 1024*1024,
    parameter  string  INIT_FILE = "",
	
	localparam integer ADDR_WIDTH = $clog2(MEM_DEPTH),
    localparam integer DATA_WIDTH = 32
)
(
    input  wire MCLK,
    input  wire MRESETn,
    input  wire MEN,
    input  wire [$clog2(MEM_DEPTH)-1:0] MADDR,
    input  wire [  DATA_WIDTH-1:0] MDIN,
    input  wire [DATA_WIDTH/8-1:0] MWE,
    output wire [  DATA_WIDTH-1:0] MDOUT  
);
    
	// PARAMETERS
	//   local parameter for addressing 32 bit / 64 bit DATA_WIDTH
	//   ADDR_LSB is used for addressing 32/64 bit registers/memories
	//   ADDR_LSB = 2 for 32 bits (n downto 2)
	//   ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (DATA_WIDTH/32) + 1;
	localparam integer ADDR_MSB = ADDR_WIDTH-1;
    
	localparam REGS_SIZE = MEM_DEPTH/(DATA_WIDTH/8);
	
    
	// SIGNALS
	// -- Register File
	reg  [DATA_WIDTH-1:0] regfile[0:REGS_SIZE-1];
	wire [ADDR_MSB-ADDR_LSB:0] _addr = MADDR[ADDR_MSB:ADDR_LSB];
	reg  _error;
	

	// LOGIC
	always @(*) begin
        if ( !MRESETn ) begin
            _error <= 1'b0;
        end
		else begin
            if ( _addr <= (REGS_SIZE-1) ) begin
                _error <= 1'b0;
            end
            else begin
                _error <= 1'b1;
            end
        end
    end
	
	wire __wren = (MEN && (MWE != 0) && !_error);
	always @( posedge MCLK ) begin
		if ( !MRESETn ) begin
			if ( (INIT_FILE.len() == 0) || ($system($sformatf("/usr/bin/test -f %s", INIT_FILE)) != 0) ) begin
        // $display ("Initializing mem to 0");
				for ( integer idx = 0; idx <= REGS_SIZE-1; idx = idx+1 ) begin
					regfile[_addr] <= 0;
				end
			end
			else begin
        // $display ("Loading memory with init file");
				$readmemh(INIT_FILE, regfile);
			end
        end
		else begin
            if ( __wren ) begin
				for ( integer byte_index = 0; byte_index <= (DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
					if ( MWE[byte_index] ) begin
						// Respective byte enables are asserted as per write strobes
						regfile[_addr][(byte_index*8) +: 8] <= MDIN[(byte_index*8) +: 8];
					end
				end
            end
		end
	end
	
	wire __rden = (MEN && !_error);
	reg  __rden_r = 0;
	reg  [DATA_WIDTH-1:0] __dout = 0;
	assign MDOUT = ( __rden_r ? __dout : {(DATA_WIDTH){1'b0}});
	always @( posedge MCLK ) begin
		if ( !MRESETn ) begin
            __dout   <= 0;
			__rden_r <= 0;
		end
		else begin
			__rden_r <= __rden;
			if ( __rden ) begin
				__dout <= regfile[_addr];
			end
		end
	end
	

endmodule
