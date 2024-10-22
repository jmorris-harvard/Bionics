import sys

class Memory:
  DefaultMemoryName = 'bram'
  def __init__ (Self, Name = DefaultMemoryName):
    Self.Name = Name

  def CreateMemory (Self, OutFilename = None):
    Output = []
    OutFile = OutFilename if OutFilename else '%s_ahb.sv' % (Self.Name)

    # Add Header
    Output.append ('`timescale 1ns / 1ps\n')

    # Memory
    Output.append ('module %s #(\n' % (Self.Name))
    Output.append ('\tparameter integer DATA_WIDTH = 32,\n')
    Output.append ('\tparameter integer MEM_BYTES = 1024 * 1024,\n')
    Output.append ('\n') 
    Output.append ('\tlocalparam integer ADDR_WIDTH = $clog2 (MEM_BYTES)\n')
    Output.append (') (\n')

    # -- Ports
    Output.append ('\tinput\t\tMCLK,\n')
    Output.append ('\tinput\t\tMRESETn,\n')
    Output.append ('\n')
    Output.append ('\tinput\t\tMEN,\n')
    Output.append ('\tinput\t[ADDR_WIDTH - 1:0]\tMADDR,\n')
    Output.append ('\tinput\t[DATA_WIDTH - 1:0]\tMDIN,\n')
    Output.append ('\tinput\t[(DATA_WIDTH / 8) - 1:0]\tMWE,\n')
    Output.append ('\toutput\t[DATA_WIDTH - 1:0]\tMDOUT\n')
    Output.append (');\n\n')
    
    # -- Custom Logic
    Output.append ('\t// Custom Implementation\n\n')
    Output.append ('\t// -- Begin Custom RTL --\n\n\n')
    Output.append ('\t// -- End Custom RTL --\n\n')
    Output.append ('endmodule\n')
    Output.append ('\n')

    # AHB Interpreter
    Output.append ('module %s_ahb_interpreter #(\n' % (Self.Name))
    # Parameters
    Output.append ('\tparameter integer DATA_WIDTH = 32,\n')
    Output.append ('\tparameter integer ADDR_BASE = 0,\n')
    Output.append ('\tparameter integer MEM_BYTES = 1024 * 1024,\n')
    Output.append ('\n')
    Output.append ('\tlocalparam integer DATA_BYTES = (DATA_WIDTH / 8),\n')
    Output.append ('\tlocalparam integer ADDR_WIDTH = $clog2 (MEM_BYTES) + 1\n')
    Output.append (') (\n')

    # AHB Ports
    Output.append ('\tinput wire\t\tHCLK,\n')
    Output.append ('\tinput wire\t\tHRESETn,\n')
    Output.append ('\tinput wire [ADDR_WIDTH - 1:0] HADDR,\n')
    Output.append ('\tinput wire [2:0] HBURST,\n')
    Output.append ('\tinput wire\t\tHMASTLOCK,\n')
    Output.append ('\tinput wire [3:0] HPROT,\n')
    Output.append ('\tinput wire [2:0] HSIZE,\n')
    Output.append ('\tinput wire [1:0] HTRANS,\n')
    Output.append ('\tinput wire [DATA_WIDTH - 1:0] HWDATA,\n')
    Output.append ('\tinput wire HWRITE,\n')
    Output.append ('\tinput wire HSEL,\n')
    Output.append ('\tinput wire HREADYIN,\n')
    Output.append ('\toutput wire [DATA_WIDTH - 1:0] HRDATA,\n')
    Output.append ('\toutput wire HREADYOUT,\n')
    Output.append ('\toutput wire HRESP,\n')
    Output.append ('\n')
    # Peripheral Mem Ports
    Output.append ('\toutput wire MCLK,\n')
    Output.append ('\toutput wire MRESETn,\n')
    Output.append ('\toutput wire MEN,\n')
    Output.append ('\toutput wire [ADDR_WIDTH - 1:0] MADDR,\n')
    Output.append ('\toutput wire [DATA_WIDTH - 1:0] MDIN,\n')
    Output.append ('\toutput wire [DATA_BYTES - 1:0] MWE,\n')
    Output.append ('\tinput wire MDONE,\n')
    Output.append ('\tinput wire MERROR,\n')
    Output.append ('\tinput wire [DATA_WIDTH - 1:0] MDOUT\n')
    Output.append (');\n')
    Output.append ('\n')

    # Include AHB Defines
    Output.append ('\t`include "ahb_defs.v"\n\n')

    # Signals
    # -- IO Registers
    Output.append ('\t// Bus Registers\n')
    Output.append ('\treg [ADDR_WIDTH - 1:0] haddr;\n')
    Output.append ('\treg [DATA_WIDTH - 1:0] hrdata;\n')
    Output.append ('\treg [DATA_WIDTH - 1:0] hwdata;\n')
    Output.append ('\treg hresp;\n')
    Output.append ('\n')

    # -- Memory
    Output.append ('\t// Memory Registers\n')
    Output.append ('\treg men;\n')
    Output.append ('\treg [DATA_BYTES - 1:0] mwe;\n')
    Output.append ('\treg [DATA_WIDTH - 1:0] mdin;\n')
    Output.append ('\n')

    # -- Transaction Routing
    Output.append ('\t// Transactions\n')
    Output.append ('\twire transreq;\n')
    Output.append ('\twire transvalid;\n')
    Output.append ('\twire transwrite;\n')
    Output.append ('\twire transread;\n')
    Output.append ('\n')

    # -- Errors
    Output.append ('\t// Errors\n')
    Output.append ('\treg erroraddr;\n')
    Output.append ('\n')

    # -- Memory
    Output.append ('\t// Memory\n')
    Output.append ('\twire [ADDR_WIDTH - 1:0] memaddr;\n')
    Output.append ('\treg memreq;\n')
    Output.append ('\treg memren;\n')
    Output.append ('\treg memwen;\n')
    Output.append ('\treg [DATA_WIDTH - 1:0] memdout;\n')
    Output.append ('\twire memdone;\n')
    Output.append ('\treg memerror;\n')
    Output.append ('\n')
    
    # -- AHB Routing
    Output.append ('\t// Bus Routing\n')
    Output.append ('\tassign HREADYOUT = memdone | transreq;\n')
    Output.append ('\tassign HRESP = hresp;\n')
    Output.append ('\tassign HRDATA = memren ? MDOUT : {DATA_WIDTH{1\'bZ}};\n')
    Output.append ('\n')

    # -- Memory Routing
    Output.append ('\t// Memory Routing\n')
    Output.append ('\tassign MEN = men | transread;\n')
    Output.append ('\tassign MWE = mwe;\n')
    Output.append ('\tassign MCLK = HCLK;\n')
    Output.append ('\tassign MRESETn = HRESETn;\n')
    Output.append ('\tassign MADDR = transread ? memaddr\n')
    Output.append ('\t\t: memwen ? haddr\n')
    Output.append ('\t\t: {(ADDR_WIDTH){1\'bZ}};\n')
    Output.append ('\tassign MDIN = ( memwen ? HWDATA : {(DATA_WIDTH){1\'bZ}} );\n')
    Output.append ('\n')

    # -- Internal Routing
    Output.append ('\t// Internal Routing\n')
    Output.append ('\tassign memaddr = HADDR;\n')
    Output.append ('\tassign memdone = MDONE;\n')
    Output.append ('\tassign transreq = HSEL & HTRANS[1] & HREADYIN;\n')
    Output.append ('\tassign transvalid = transreq & ~erroraddr;\n')
    Output.append ('\tassign transwrite = transvalid & HWRITE;\n')
    Output.append ('\tassign transread = transvalid & ~HWRITE;\n')
    Output.append ('\twire error = erroraddr | MERROR;\n')
    Output.append ('\twire rerror = memerror;\n')
    Output.append ('\twire werror = memwen & MERROR;\n')
    Output.append ('\n')

    # Logic
    # -- Memories
    # ---- Enables
    Output.append ('\t// Logic\n')
    Output.append ('\t// -- Memories\n')
    Output.append ('\t// ---- Enables\n')
    Output.append ('\talways @(posedge HCLK) begin\n')
    Output.append ('\t\tif ( ~HRESETn ) begin\n')
    Output.append ('\t\t\tmen <= 1\'b0;\n')
    Output.append ('\t\t\tmemren <= 1\'b0;\n')
    Output.append ('\t\t\tmemwen <= 1\'b0;\n')
    Output.append ('\t\tend else begin\n')
    Output.append ('\t\t\tmemreq <= transreq;\n')
    Output.append ('\t\t\tmen <= (transwrite | transread) & ~error;\n')
    Output.append ('\t\t\tmemren <= transread & ~error;\n')
    Output.append ('\t\t\tmemwen <= transwrite & ~error;\n')
    Output.append ('\t\t\tmemerror <= erroraddr | error;\n')
    Output.append ('\t\tend\n')
    Output.append ('\tend\n')
    Output.append ('\n')

    # ---- Write
    Output.append ('\t// ---- Write\n')
    Output.append ('\talways @(posedge HCLK) begin\n')
    Output.append ('\t\tif ( ~HRESETn ) begin\n')
    Output.append ('\t\t\tmwe <= {(DATA_BYTES){1\'b0}};\n')
    Output.append ('\t\tend else begin\n')
    Output.append ('\t\t\tif ( transwrite ) begin\n')
    Output.append ('\t\t\t\tif ( HSIZE == 3\'b010 ) begin\n')
    Output.append ('\t\t\t\t\tmwe <= {(DATA_BYTES){1\'b1}};\n')
    Output.append ('\t\t\t\tend else if ( HSIZE == 3\'b001 ) begin\n')
    Output.append ('\t\t\t\t\tmwe <= {(DATA_BYTES){1\'b0}};\n')
    Output.append ('\t\t\t\t\tif ( HADDR[1:0] == 2\'b00 ) begin\n')
    Output.append ('\t\t\t\t\t\tmwe[1:0] <= 2\'b11;\n')
    Output.append ('\t\t\t\t\tend else if ( HADDR[1:0] == 2\'b01 ) begin\n')
    Output.append ('\t\t\t\t\t\tmwe[2:1] <= 2\'b11;\n')
    Output.append ('\t\t\t\t\tend else if ( HADDR[1:0] == 2\'b10 ) begin\n')
    Output.append ('\t\t\t\t\t\tmwe[3:2] <= 2\'b11;\n')
    Output.append ('\t\t\t\t\tend\n')
    Output.append ('\t\t\t\tend else if ( HSIZE == 3\'b000 ) begin\n')
    Output.append ('\t\t\t\t\tmwe <= {(DATA_BYTES){1\'b0}};\n')
    Output.append ('\t\t\t\t\tmwe[HADDR[1:0]] <= 1\'b1;\n')
    Output.append ('\t\t\t\tend\n')
    Output.append ('\t\t\tend else begin\n')
    Output.append ('\t\t\t\tmwe <= {(DATA_BYTES){1\'b0}};\n')
    Output.append ('\t\t\tend\n')
    Output.append ('\t\tend\n')
    Output.append ('\tend\n')
    Output.append ('\n')

    # -- Bus
    # ---- Address
    Output.append ('\t// -- Bus\n')
    Output.append ('\t// ---- Address\n')
    Output.append ('\talways @(*) begin\n')
    Output.append ('\t\tif ( ~HRESETn ) begin\n')
    Output.append ('\t\t\t erroraddr <= 1\'b0;\n')
    Output.append ('\t\tend else begin\n')
    Output.append ('\t\t\tif ( (HADDR >= ADDR_BASE) && (HADDR <= (ADDR_BASE + MEM_BYTES - 1)) ) begin\n')
    Output.append ('\t\t\t\terroraddr <= 1\'b0;\n')
    Output.append ('\t\t\tend else begin\n')
    Output.append ('\t\t\t\terroraddr <= 1\'b1;\n')
    Output.append ('\t\t\tend\n')
    Output.append ('\t\tend\n')
    Output.append ('\tend\n')
    Output.append ('\n')

    # ---- Write
    Output.append ('\t// ---- Write\n')
    Output.append ('\talways @(posedge HCLK) begin\n')
    Output.append ('\t\tif ( ~HRESETn ) begin\n')
    Output.append ('\t\t\thaddr <= 0;\n')
    Output.append ('\t\t\thwdata <= 0;\n')
    Output.append ('\t\tend else begin\n')
    Output.append ('\t\t\thaddr <= memaddr;\n')
    Output.append ('\t\t\thwdata <= HWDATA;\n')
    Output.append ('\t\tend\n')
    Output.append ('\tend\n')
    Output.append ('\n')

    # ---- Response
    Output.append ('\t// ---- Response\n')
    Output.append ('\talways @(negedge HCLK) begin\n')
    Output.append ('\t\tif ( ~HRESETn ) begin\n')
    Output.append ('\t\t\thresp <= `AHB_RSP_OKAY;\n')
    Output.append ('\t\tend else if ( HREADYOUT ) begin\n')
    Output.append ('\t\t\tif ( memreq ) begin\n')
    Output.append ('\t\t\t\thresp <= ((rerror | werror) ? `AHB_RSP_ERROR : `AHB_RSP_OKAY);\n')
    Output.append ('\t\t\tend else begin\n')
    Output.append ('\t\t\t\thresp <= `AHB_RSP_OKAY;\n')
    Output.append ('\t\t\tend\n')
    Output.append ('\t\tend\n')
    Output.append ('\tend\n')
    Output.append ('\n')
    Output.append ('endmodule\n')
    Output.append ('\n')

    # Full AHB Wrapper Peripheral
    Output.append ('module %s_ahb #(\n' % (Self.Name))
    Output.append ('\tparameter integer DATA_WIDTH = 32,\n')
    Output.append ('\tparameter integer MEM_BYTES = 1024 * 1024,\n')
    Output.append ('\n')
    Output.append ('\tlocalparam integer ADDR_WIDTH = $clog2 (MEM_BYTES) + 1,\n')
    Output.append ('\tlocalparam integer ADDR_LSB = (DATA_WIDTH / 32) + 1,\n')
    Output.append ('\tlocalparam integer ADDR_MSB = ADDR_WIDTH - 1\n')
    Output.append ('')
    Output.append (') (\n')

    # AHB Ports
    Output.append ('\tinput wire\t\tHCLK,\n')
    Output.append ('\tinput wire\t\tHRESETn,\n')
    Output.append ('\tinput wire [ADDR_WIDTH - 1:0] HADDR,\n')
    Output.append ('\tinput wire [2:0] HBURST,\n')
    Output.append ('\tinput wire\t\tHMASTLOCK,\n')
    Output.append ('\tinput wire [3:0] HPROT,\n')
    Output.append ('\tinput wire [2:0] HSIZE,\n')
    Output.append ('\tinput wire [1:0] HTRANS,\n')
    Output.append ('\tinput wire [DATA_WIDTH - 1:0] HWDATA,\n')
    Output.append ('\tinput wire HWRITE,\n')
    Output.append ('\tinput wire HSEL,\n')
    Output.append ('\tinput wire HREADYIN,\n')
    Output.append ('\toutput wire [DATA_WIDTH - 1:0] HRDATA,\n')
    Output.append ('\toutput wire HREADYOUT,\n')
    Output.append ('\toutput wire HRESP\n')
    Output.append (');\n\n')

    # Signals
    # -- Bus
    Output.append ('\t// Signals\n')
    Output.append ('\t// -- Bus\n')
    Output.append ('\twire [ADDR_WIDTH - 1:0] addr;\n')
    Output.append ('\twire wren;\n')
    Output.append ('\twire rden;\n')
    Output.append ('\twire rerror;\n')
    Output.append ('\twire werror;\n')
    Output.append ('\n')

    # -- Memory
    Output.append ('\t// -- Memory\n')
    Output.append ('\twire memclk;\n')
    Output.append ('\twire memresetn;\n')
    Output.append ('\twire memen;\n')
    Output.append ('\twire [ADDR_WIDTH - 1:0] memaddr;\n')
    Output.append ('\twire [DATA_WIDTH - 1:0] memdin;\n')
    Output.append ('\twire [(DATA_WIDTH / 8) - 1:0] memwe;\n')
    Output.append ('\twire [DATA_WIDTH - 1:0] memdout;\n')
    Output.append ('\n')

    # Instantiations
    Output.append ('\t// Instantiations\n')
    Output.append ('\t%s_ahb_interpreter #(\n' % (Self.Name))
    Output.append ('\t\t.DATA_WIDTH (DATA_WIDTH),\n')
    Output.append ('\t\t.MEM_BYTES (MEM_BYTES)\n')
    Output.append ('\t) %s_ahb_interpreter_inst (\n' % (Self.Name))
    Output.append ('\t\t.HCLK (HCLK),\n')
    Output.append ('\t\t.HRESETn (HRESETn),\n')
    Output.append ('\t\t.HADDR (HADDR),\n')
    Output.append ('\t\t.HBURST (HBURST),\n')
    Output.append ('\t\t.HMASTLOCK (HMASTLOCK),\n')
    Output.append ('\t\t.HPROT (HPROT),\n')
    Output.append ('\t\t.HSIZE (HSIZE),\n')
    Output.append ('\t\t.HTRANS (HTRANS),\n')
    Output.append ('\t\t.HWDATA (HWDATA),\n')
    Output.append ('\t\t.HWRITE (HWRITE),\n')
    Output.append ('\t\t.HSEL (HSEL),\n')
    Output.append ('\t\t.HREADYIN (HREADYIN),\n')
    Output.append ('\t\t.HRDATA (HRDATA),\n')
    Output.append ('\t\t.HREADYOUT (HREADYOUT),\n')
    Output.append ('\t\t.HRESP (HRESP),\n')
    Output.append ('\t\t.MCLK (memclk),\n')
    Output.append ('\t\t.MRESETn (memresetn),\n')
    Output.append ('\t\t.MEN (memen),\n')
    Output.append ('\t\t.MADDR (memaddr),\n')
    Output.append ('\t\t.MDIN (memdin),\n')
    Output.append ('\t\t.MWE (memwe),\n')
    Output.append ('\t\t.MDONE (1\'b1),\n')
    Output.append ('\t\t.MERROR (1\'b0),\n')
    Output.append ('\t\t.MDOUT (memdout)\n')
    Output.append ('\t);\n')
    Output.append ('\n')

    Output.append ('\t%s #(\n' % (Self.Name))
    Output.append ('\t\t.DATA_WIDTH (DATA_WIDTH),\n')
    Output.append ('\t\t.MEM_BYTES (MEM_BYTES)\n')
    Output.append ('\t) %s_inst (\n' % (Self.Name))
    Output.append ('\t\t.MCLK (HCLK),\n')
    Output.append ('\t\t.MRESETn (HRESETn),\n')
    Output.append ('\n')
    Output.append ('\t\t.MEN (memen),\n')
    Output.append ('\t\t.MADDR (memaddr),\n')
    Output.append ('\t\t.MDIN (memdin),\n')
    Output.append ('\t\t.MWE (memwe),\n')
    Output.append ('\t\t.MDOUT (memdout)\n')
    Output.append ('\t);\n\n')
    Output.append ('endmodule\n')

    with open (OutFile, 'w') as Verilog:
      Verilog.writelines (Output)

if __name__ == '__main__':
  m = Memory (sys.argv[1])
  m.CreateMemory ()
