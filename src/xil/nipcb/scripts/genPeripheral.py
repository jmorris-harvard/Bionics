# Creates M0 AHB Peripheral From JSON Configuration File

# Known Issues
# > With no IRQ extra commas in module definition
#
#

import json
import sys

class AHBPeripheral:
  def __init__ (Self, Filename = None):
    Self.Filename = Filename
    Self.HasJSONData = False
    
    if Self.Filename:
      Self.ParseJSON ()

  def ParseJSON (Self, Filename = None):
    if Filename:
      Self.Filename = Filename

    Self.HasJSONData = False
    if not Self.Filename:
      print ('Not File Given')
      return # Error

    with open (Self.Filename, 'r') as JSON:
      Self.Data = json.load (JSON)

    Self.HasJSONData = True

  def CreatePeripheral (Self, OutFilename = None):
    if not Self.HasJSONData:
      print ('No data available')
      return # Error

    OutFile = OutFilename if OutFilename else '%s_ahb.sv' % (Self.Data['name'])

    Output = []
    # Add Header
    Output.append ('`timescale 1ns / 1ps\n')

    # Peripheral Template
    Output.append ('module %s #(\n' % (Self.Data['name']))
    Output.append ('\tparameter integer DATA_WIDTH = 32\n')
    Output.append (') (\n')
    Output.append ('\tinput\tCLK,\n')
    Output.append ('\tinput\tRESETn,\n')
    
    # -- Ports
    # ---- Triggers
    TriggerList = Self.Data['ports'].get ('triggers')
    if TriggerList:
      Output.append ('\n\t// Triggers\n')
      for Trigger in TriggerList:
        Output.append ('\tinput\t\t[DATA_WIDTH - 1:0]\t\tT_%s,\n' % (Trigger['name']))

    # ---- Flags
    FlagList = Self.Data['ports'].get ('flags')
    if FlagList:
      Output.append ('\n\t// Flags\n')
      for Flag in FlagList:
        Output.append ('\toutput\t\t[DATA_WIDTH - 1:0]\t\tF_%s,\n' % (Flag['name']))

    # ---- Configurations
    ConfigList = Self.Data['ports'].get ('configs')
    if ConfigList:
      Output.append ('\n\t// Configurations\n')
      for Config in ConfigList:
        Output.append ('\tinput\t\t[DATA_WIDTH - 1:0]\t\tC_%s,\n' % (Config['name']))

    # ---- Inputs
    InputList = Self.Data['ports'].get ('iregs')
    if InputList:
      Output.append ('\n\t// Input Registers\n')
      for Ireg in InputList:
        Output.append ('\tinput\t\t[DATA_WIDTH - 1:0]\t\tI_%s,\n' % (Ireg['name']))

    # ---- Outputs
    OutputList = Self.Data['ports'].get ('oregs')
    if OutputList:
      Output.append ('\n\t// Output Registers\n')
      for Oreg in Self.Data['ports'].get ('oregs'):
        Output.append ('\toutput\t\t[DATA_WIDTH - 1:0]\t\tO_%s,\n' % (Oreg['name']))

    # ---- GPIO
    GPIOList = Self.Data['ports'].get ('gpio')
    if GPIOList:
      Output.append ('\n\t// GPIO\n')
      for GPIO in GPIOList:
        Output.append ('\t%s\t\t[%d:0]\t\t%s,\n' % (GPIO['direction'], GPIO['bitwidth'] - 1, GPIO['name']))

    # ---- IRQ
    if Self.Data['ports'].get ('irq') == True:
      Output.append ('\t// IRQ\n')
      Output.append ('\toutput\t\tIRQ\n')

    if ',' in Output[-1]:
      Output[-1] = Output[-1].replace (',', '')
    Output.append (');\n')

    # -- Routing
    Output.append ('\t// Routing\n')

    # ---- Triggers
    TriggerList = Self.Data['ports'].get ('triggers')
    if TriggerList:
      Output.append ('\t// -- Triggers\n')
      for Trigger in TriggerList:
        Output.append ('\t// ---- Bits\n')
        for I, Bit in enumerate (Trigger['bits']):
          Output.append ('\twire T_%s_b%d_%s;\n' % (Trigger['name'], I, Bit['name']))
          Output.append ('\tassign T_%s_b%d_%s = T_%s[%d];\n' % (Trigger['name'], I, Bit['name'], Trigger['name'], I))
        Output.append ('\n')

    # ---- Flags
    FlagList = Self.Data['ports'].get ('flags')
    if FlagList:
      Output.append ('\t// -- Flags\n')
      for Flag in FlagList:
        Output.append ('\tlocalparam integer F_%s_FLAG_BIT_N = %s;\n' % (Flag['name'], len (Flag['bits'])))
        Output.append ('\n')
        Output.append ('\t// ---- Bits\n')
        BitArray = []
        for I, Bit in enumerate (Flag['bits']):
          Output.append ('\twire F_%s_b%d_%s;\n' % (Flag['name'], I, Bit['name']))
          BitArray.append ('F_%s_b%d_%s' % (Flag['name'], I, Bit['name']))
        Output.append ('\n')
        Output.append ('\t// ---- Locations\n')
        Output.append ('\tassign F_%s[F_%s_FLAG_BIT_N - 1:0] = {%s};\n' % (Flag['name'], Flag['name'], ', '.join (reversed (BitArray))))
        Output.append ('\tassign F_%s[DATA_WIDTH - 1:F_%s_FLAG_BIT_N] = {(DATA_WIDTH - F_%s_FLAG_BIT_N - 1){1\'b0}};\n' % (Flag['name'], Flag['name'], Flag['name']))
        Output.append ('\n')

    # ---- Configurations
    ConfigList = Self.Data['ports'].get ('configs')
    if ConfigList:
      Output.append ('\t// -- Configurations\n')
      for Config in ConfigList:
        Output.append ('\t// ---- Bits\n')
        for I, Bit in enumerate (Config['bits']):
          Output.append ('\twire C_%s_b%d_%s;\n' % (Config['name'], I, Bit['name']))
          Output.append ('\tassign C_%s_b%d_%s = C_%s[%d];\n' % (Config['name'], I, Bit['name'], Config['name'], I))
        Output.append ('\n')

    # -- Custom Logic
    Output.append ('\t// Custom Implementation\n\n')
    Output.append ('\t// -- Begin Custom RTL --\n\n\n')
    Output.append ('\t// -- End Custom RTL --\n\n')
    Output.append ('endmodule\n')

    Output.append ('\n')

    # Register File Module
    # -- Parameters
    Output.append ('module %s_register_io #(\n' % (Self.Data['name']))
    Output.append ('\tparameter integer DATA_WIDTH = 32,\n')
    Output.append ('\n')
    if Self.Data['ports'].get ('triggers'):
      Output.append ('\tlocalparam integer TRIG_COUNT = %d,\n' % (len (Self.Data['ports'].get('triggers'))))
    else:
      Output.append ('\tlocalparam integer TRIG_COUNT = 0,\n')

    if Self.Data['ports'].get ('flags'):
      Output.append ('\tlocalparam integer FLAG_COUNT = %d,\n' % (len (Self.Data['ports'].get('flags'))))
    else:
      Output.append ('\tlocalparam integer FLAG_COUNT = 0,\n')

    if Self.Data['ports'].get ('configs'):
      Output.append ('\tlocalparam integer CONF_COUNT = %d,\n' % (len (Self.Data['ports'].get('configs'))))
    else:
      Output.append ('\tlocalparam integer CONF_COUNT = 0,\n')

    if Self.Data['ports'].get ('iregs'):
      Output.append ('\tlocalparam integer IREG_COUNT = %d,\n' % (len (Self.Data['ports'].get('iregs'))))
    else:
      Output.append ('\tlocalparam integer IREG_COUNT = 0,\n')

    if Self.Data['ports'].get ('oregs'):
      Output.append ('\tlocalparam integer OREG_COUNT = %d,\n' % (len (Self.Data['ports'].get('oregs'))))
    else:
      Output.append ('\tlocalparam integer OREG_COUNT = 0,\n')

    Output.append ('\tlocalparam integer DATA_BYTES = DATA_WIDTH / 8,\n')
    Output.append ('\tlocalparam integer REGS_COUNT = TRIG_COUNT + FLAG_COUNT + CONF_COUNT + IREG_COUNT + OREG_COUNT,\n')
    Output.append ('\tlocalparam integer ADDR_WIDTH = $clog2 (DATA_BYTES * REGS_COUNT) + 1\n')
    Output.append (') (\n')

    # -- Ports
    Output.append ('\tinput\t\tCLK,\n')
    Output.append ('\tinput\t\tRESETn,\n')
    Output.append ('\n')
    Output.append ('\tinput\t[ADDR_WIDTH - 1:0]\tWADDR,\n')
    Output.append ('\tinput\t[DATA_WIDTH - 1:0]\tWDATA,\n')
    Output.append ('\tinput\t\tWVALID,\n')
    Output.append ('\toutput\t\tWERROR,\n')
    Output.append ('\n')
    Output.append ('\tinput\t[ADDR_WIDTH - 1:0]\tRADDR,\n')
    Output.append ('\toutput\t[DATA_WIDTH - 1:0]\tRDATA,\n')
    Output.append ('\tinput\t\tRVALID,\n')
    Output.append ('\toutput\t\tRERROR,\n')

    # ---- Unique Ports
    GPIOList = Self.Data['ports'].get ('gpio')
    if GPIOList:
      Output.append ('\n')
      Output.append ('\t// Peripheral Ports\n')
      for GPIO in GPIOList:
        Output.append ('\t%s\t[%d:0]\t%s,\n' % (GPIO['direction'], GPIO['bitwidth'] - 1, GPIO['name']))

    # ---- IRQ
    if Self.Data['ports'].get ('irq') == True:
      Output.append ('\t// IRQ\n')
      Output.append ('\toutput\t\tIRQ\n')
    if ',' in Output[-1]:
      Output[-1] = Output[-1].replace (',', '')
    Output.append (');\n\n')

    Output.append ('\t// Signals\n')
    Output.append ('\t// -- I/O\n')
    Output.append ('\treg werror = 0;\n')
    Output.append ('\treg rerror = 0;\n')
    Output.append ('\treg [DATA_WIDTH - 1:0] rdata;\n')
    Output.append ('\treg winterrupt;\n') # Rethink?
    Output.append ('\treg rinterrupt;\n')
    Output.append ('\n')

    Output.append ('\t// -- Register File\n')
    if Self.Data['ports'].get ('triggers'):
      Output.append ('\treg [DATA_WIDTH - 1:0] triggers\t[0:TRIG_COUNT - 1];\n')
    if Self.Data['ports'].get ('flags'):
      Output.append ('\treg [DATA_WIDTH - 1:0] flags\t[0:FLAG_COUNT - 1];\n')
    if Self.Data['ports'].get ('configs'):
      Output.append ('\treg [DATA_WIDTH - 1:0] configs\t[0:CONF_COUNT - 1];\n')
    if Self.Data['ports'].get ('iregs'):
      Output.append ('\treg [DATA_WIDTH - 1:0] iregs\t[0:IREG_COUNT - 1];\n')
    if Self.Data['ports'].get ('oregs'):
      Output.append ('\treg [DATA_WIDTH - 1:0] oregs\t[0:OREG_COUNT - 1];\n')
    Output.append ('\n')

    Output.append ('\t// Routing\n')
    Output.append ('\tassign WERROR = werror;\n')
    Output.append ('\tassign RERROR = rerror;\n')
    Output.append ('\tassign RDATA = rdata;\n')
    Output.append ('\n')

    # State Machines
    Output.append ('\t// Logic\n')

    # -- Read
    Output.append ('\t// -- Read\n')
    Output.append ('\talways @(*) begin\n')
    Output.append ('\t\tif ( ~RESETn ) begin\n')
    Output.append ('\t\t\trerror <= 1\'b0;\n')
    Output.append ('\t\tend else begin\n')
    Output.append ('\t\t\tif ( RVALID ) begin\n')
    Output.append ('\t\t\t\tif ( RADDR < TRIG_COUNT ) begin\n')
    Output.append ('\t\t\t\t\trerror <= 1\'b0;\n')
    Output.append ('\t\t\t\tend else if ( RADDR < TRIG_COUNT + FLAG_COUNT ) begin\n')
    Output.append ('\t\t\t\t\trerror <= 1\'b0;\n')
    Output.append ('\t\t\t\tend else if ( RADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT ) begin\n')
    Output.append ('\t\t\t\t\trerror <= 1\'b0;\n')
    Output.append ('\t\t\t\tend else if ( RADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT + IREG_COUNT ) begin\n')
    Output.append ('\t\t\t\t\trerror <= 1\'b0;\n')
    Output.append ('\t\t\t\tend else if ( RADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT + IREG_COUNT + OREG_COUNT ) begin\n')
    Output.append ('\t\t\t\t\trerror <= 1\'b0;\n')
    Output.append ('\t\t\t\tend else begin\n')
    Output.append ('\t\t\t\t\trerror <= 1\'b1;\n')
    Output.append ('\t\t\t\tend\n')
    Output.append ('\t\t\tend else begin\n')
    Output.append ('\t\t\t\trerror <= 1\'b0;\n')
    Output.append ('\t\t\tend\n')
    Output.append ('\t\tend\n')
    Output.append ('\tend\n')
    Output.append ('\n')

    # -- Execute Read
    Output.append ('\t// -- Execute Read\n')
    Output.append ('\talways @(posedge CLK) begin\n')
    Output.append ('\t\tif ( ~RESETn ) begin\n')
    Output.append ('\t\t\trdata <= 0;\n')
    Output.append ('\t\tend else begin\n')
    Output.append ('\t\t\tif ( RVALID && ~rerror ) begin\n')
    Output.append ('\t\t\t\tif ( RADDR < TRIG_COUNT ) begin\n')
    if Self.Data['ports'].get ('triggers'):
      Output.append ('\t\t\t\t\trdata <= triggers[RADDR];\n')
    else:
      Output.append ('\t\t\t\t\t// No Triggers\n')
    Output.append ('\t\t\t\tend else if ( RADDR < TRIG_COUNT + FLAG_COUNT ) begin\n')
    if Self.Data['ports'].get ('flags'):
      Output.append ('\t\t\t\t\trdata <= flags[RADDR - TRIG_COUNT];\n')
    else:
      Output.append ('\t\t\t\t\t// No Flags\n')
    Output.append ('\t\t\t\tend else if ( RADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT ) begin\n')
    if Self.Data['ports'].get ('configs'):
      Output.append ('\t\t\t\t\trdata <= configs[RADDR - TRIG_COUNT - FLAG_COUNT];\n')
    else:
      Output.append ('\t\t\t\t\t// No Configs\n')
    Output.append ('\t\t\t\tend else if ( RADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT + IREG_COUNT ) begin\n')
    if Self.Data['ports'].get ('iregs'):
      Output.append ('\t\t\t\t\trdata <= iregs[RADDR - TRIG_COUNT - FLAG_COUNT - CONF_COUNT];\n')
    else:
      Output.append ('\t\t\t\t\t// No Iregs\n')
    Output.append ('\t\t\t\tend else if ( RADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT + IREG_COUNT + OREG_COUNT ) begin\n')
    if Self.Data['ports'].get ('oregs'):
      Output.append ('\t\t\t\t\trdata <= oregs[RADDR - TRIG_COUNT - FLAG_COUNT - CONF_COUNT - IREG_COUNT];\n')
    else:
      Output.append ('\t\t\t\t\t// No Oregs\n')
    Output.append ('\t\t\t\tend\n')
    Output.append ('\t\t\tend\n')
    Output.append ('\t\tend\n')
    Output.append ('\tend\n')
    Output.append ('\n')

    # -- Write
    Output.append ('\t// -- Write\n')
    Output.append ('\talways @(*) begin\n')
    Output.append ('\t\tif ( ~RESETn ) begin\n')
    Output.append ('\t\t\twerror <= 1\'b0;\n')
    Output.append ('\t\tend else begin\n')
    Output.append ('\t\t\tif ( WVALID ) begin\n')
    Output.append ('\t\t\t\tif ( WADDR < TRIG_COUNT ) begin\n')
    Output.append ('\t\t\t\t\twerror <= 1\'b0;\n')
    Output.append ('\t\t\t\tend else if ( WADDR < TRIG_COUNT + FLAG_COUNT ) begin\n')
    Output.append ('\t\t\t\t\twerror <= 1\'b1;\n')
    Output.append ('\t\t\t\tend else if ( WADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT ) begin\n')
    Output.append ('\t\t\t\t\twerror <= 1\'b0;\n')
    Output.append ('\t\t\t\tend else if ( WADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT + IREG_COUNT ) begin\n')
    Output.append ('\t\t\t\t\twerror <= 1\'b0;\n')
    Output.append ('\t\t\t\tend else if ( WADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT + IREG_COUNT + OREG_COUNT ) begin\n')
    Output.append ('\t\t\t\t\twerror <= 1\'b1;\n')
    Output.append ('\t\t\t\tend else begin\n')
    Output.append ('\t\t\t\t\twerror <= 1\'b1;\n')
    Output.append ('\t\t\t\tend\n')
    Output.append ('\t\t\tend else begin\n')
    Output.append ('\t\t\t\twerror <= 1\'b0;\n')
    Output.append ('\t\t\tend\n')
    Output.append ('\t\tend\n')
    Output.append ('\tend\n')
    Output.append ('\n')

    # -- Execute Write
    Output.append ('\t// -- Execute Write\n')
    Output.append ('\talways @(posedge CLK) begin\n')
    Output.append ('\t\tif ( ~RESETn ) begin\n')
    if Self.Data['ports'].get ('triggers'):
      Output.append ('\t\t\tfor ( integer i = 0; i < TRIG_COUNT; i = i + 1 ) begin\n')
      Output.append ('\t\t\t\ttriggers[i] = 0;\n')
      Output.append ('\t\t\tend\n')
    if Self.Data['ports'].get ('configs'): 
      Output.append ('\t\t\tfor ( integer i = 0; i < CONF_COUNT; i = i + 1 ) begin\n')
      Output.append ('\t\t\t\tconfigs[i] = 0;\n')
      Output.append ('\t\t\tend\n')
    if Self.Data['ports'].get ('iregs'): 
      Output.append ('\t\t\tfor ( integer i = 0; i < IREG_COUNT; i = i + 1 ) begin\n')
      Output.append ('\t\t\t\tiregs[i] = 0;\n')
      Output.append ('\t\t\tend\n')
    Output.append ('\t\tend else begin\n')
    if Self.Data['ports'].get ('triggers'): 
      Output.append ('\t\t\tfor ( integer i = 0; i < TRIG_COUNT; i = i + 1) begin\n')
      Output.append ('\t\t\t\ttriggers[i] <= 0;\n')
      Output.append ('\t\t\tend\n')
    Output.append ('\t\t\tif ( WVALID && ~werror ) begin\n')
    Output.append ('\t\t\t\tif ( WADDR < TRIG_COUNT ) begin\n')
    if Self.Data['ports'].get ('triggers'):
      Output.append ('\t\t\t\t\ttriggers[WADDR] <= WDATA;\n')
    else:
      Output.append ('\t\t\t\t\t// No Triggers\n')
    Output.append ('\t\t\t\tend else if ( WADDR < TRIG_COUNT + FLAG_COUNT ) begin\n')
    Output.append ('\t\t\t\t\t// Illegal\n')
    Output.append ('\t\t\t\tend else if ( WADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT ) begin\n')
    if Self.Data['ports'].get ('configs'): 
      Output.append ('\t\t\t\t\tconfigs[RADDR - TRIG_COUNT - FLAG_COUNT] <= WDATA;\n')
    else:
      Output.append ('\t\t\t\t\t// No Configs\n')
    Output.append ('\t\t\t\tend else if ( WADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT + IREG_COUNT ) begin\n')
    if Self.Data['ports'].get ('iregs'):
      Output.append ('\t\t\t\t\tiregs[RADDR - TRIG_COUNT - FLAG_COUNT - CONF_COUNT] <= WDATA;\n')
    else:
      Output.append ('\t\t\t\t\t// No Iregs\n')
    Output.append ('\t\t\t\tend else if ( WADDR < TRIG_COUNT + FLAG_COUNT + CONF_COUNT + IREG_COUNT + OREG_COUNT ) begin\n')
    Output.append ('\t\t\t\t\t// Illegal\n')
    Output.append ('\t\t\t\tend\n')
    Output.append ('\t\t\tend\n')
    Output.append ('\t\tend\n')
    Output.append ('\tend\n')
    Output.append ('\n')

    # -- Custom Logic
    Output.append ('\t// Custom Implementation\n\n')
    Output.append ('\t// -- Begin Custom RTL --\n\n\n')
    Output.append ('\t// -- End Custom RTL --\n\n')

    # Instantiation
    Output.append ('\t%s #(\n' % (Self.Data['name']))
    Output.append ('\t\t.DATA_WIDTH (DATA_WIDTH)')
    Output.append ('\t) %s_inst (\n' % (Self.Data['name']))
    Output.append ('\t\t.CLK (CLK),\n')
    Output.append ('\t\t.RESETn (RESETn),\n\n')
    for I, Trigger in enumerate (Self.Data['ports'].get ('triggers')):
      Output.append ('\t\t.T_%s (triggers[%d]),\n' % (Trigger['name'], I))
    for I, Flag in enumerate (Self.Data['ports'].get ('flags')):
      Output.append ('\t\t.F_%s (flags[%d]),\n' % (Flag['name'], I))
    for I, Config in enumerate (Self.Data['ports'].get ('configs')):
      Output.append ('\t\t.C_%s (configs[%d]),\n' % (Config['name'], I))
    for I, Ireg in enumerate (Self.Data['ports'].get ('iregs')):
      Output.append ('\t\t.I_%s (iregs[%d]),\n' % (Ireg['name'], I))
    for I, Oreg in enumerate (Self.Data['ports'].get ('oregs')):
      Output.append ('\t\t.O_%s (oregs[%d]),\n' % (Oreg['name'], I))
    GPIOList = Self.Data['ports'].get ('gpio')
    if GPIOList:
      Output.append ('\n')
      for GPIO in GPIOList:
        Output.append ('\t\t.%s (%s),\n' % (GPIO['name'], GPIO['name']))
    if Self.Data['ports'].get ('irq') == True:
      Output.append ('\n')
      Output.append ('\t\t.IRQ (IRQ)\n')
    if ',' in Output[-1]:
      Output[-1] = Output[-1].replace (',', '')
    Output.append ('\t);\n\n')
    Output.append ('endmodule\n')
    Output.append ('\n')

    # AHB Interpreter
    Output.append ('module %s_ahb_interpreter #(\n' % (Self.Data['name']))
    # Parameters
    Output.append ('\tparameter integer DATA_WIDTH = 32,\n')
    Output.append ('\tparameter integer ADDR_BASE = 0,\n')
    Output.append ('\n')
    if Self.Data['ports'].get ('triggers'):
      Output.append ('\tlocalparam integer TRIG_COUNT = %d,\n' % (len (Self.Data['ports'].get('triggers'))))
    else:
      Output.append ('\tlocalparam integer TRIG_COUNT = 0,\n')

    if Self.Data['ports'].get ('flags'):
      Output.append ('\tlocalparam integer FLAG_COUNT = %d,\n' % (len (Self.Data['ports'].get('flags'))))
    else:
      Output.append ('\tlocalparam integer FLAG_COUNT = 0,\n')

    if Self.Data['ports'].get ('configs'):
      Output.append ('\tlocalparam integer CONF_COUNT = %d,\n' % (len (Self.Data['ports'].get('configs'))))
    else:
      Output.append ('\tlocalparam integer CONF_COUNT = 0,\n')

    if Self.Data['ports'].get ('iregs'):
      Output.append ('\tlocalparam integer IREG_COUNT = %d,\n' % (len (Self.Data['ports'].get('iregs'))))
    else:
      Output.append ('\tlocalparam integer IREG_COUNT = 0,\n')

    if Self.Data['ports'].get ('oregs'):
      Output.append ('\tlocalparam integer OREG_COUNT = %d,\n' % (len (Self.Data['ports'].get('oregs'))))
    else:
      Output.append ('\tlocalparam integer OREG_COUNT = 0,\n')

    Output.append ('\tlocalparam integer DATA_BYTES = DATA_WIDTH / 8,\n')
    Output.append ('\tlocalparam integer REGS_COUNT = TRIG_COUNT + FLAG_COUNT + CONF_COUNT + IREG_COUNT + OREG_COUNT,\n')
    Output.append ('\tlocalparam integer MEM_BYTES = DATA_BYTES * REGS_COUNT,\n')
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
    Output.append ('\t`define AHB_RSP_OKAY 1\'b0"\n\n')
    Output.append ('\t`define AHB_RSP_ERROR 1\'b1"\n\n')

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
    Output.append ('module %s_ahb #(\n' % (Self.Data['name']))
    Output.append ('\tparameter integer DATA_WIDTH = 32,\n')
    Output.append ('\n')
    if Self.Data['ports'].get ('triggers'):
      Output.append ('\tlocalparam integer TRIG_COUNT = %d,\n' % (len (Self.Data['ports'].get('triggers'))))
    else:
      Output.append ('\tlocalparam integer TRIG_COUNT = 0,\n')

    if Self.Data['ports'].get ('flags'):
      Output.append ('\tlocalparam integer FLAG_COUNT = %d,\n' % (len (Self.Data['ports'].get('flags'))))
    else:
      Output.append ('\tlocalparam integer FLAG_COUNT = 0,\n')

    if Self.Data['ports'].get ('configs'):
      Output.append ('\tlocalparam integer CONF_COUNT = %d,\n' % (len (Self.Data['ports'].get('configs'))))
    else:
      Output.append ('\tlocalparam integer CONF_COUNT = 0,\n')

    if Self.Data['ports'].get ('iregs'):
      Output.append ('\tlocalparam integer IREG_COUNT = %d,\n' % (len (Self.Data['ports'].get('iregs'))))
    else:
      Output.append ('\tlocalparam integer IREG_COUNT = 0,\n')

    if Self.Data['ports'].get ('oregs'):
      Output.append ('\tlocalparam integer OREG_COUNT = %d,\n' % (len (Self.Data['ports'].get('oregs'))))
    else:
      Output.append ('\tlocalparam integer OREG_COUNT = 0,\n')

    Output.append ('\tlocalparam integer DATA_BYTES = DATA_WIDTH / 8,\n')
    Output.append ('\tlocalparam integer REGS_COUNT = TRIG_COUNT + FLAG_COUNT + CONF_COUNT + IREG_COUNT + OREG_COUNT,\n')
    Output.append ('\tlocalparam integer MEM_BYTES = DATA_BYTES * REGS_COUNT,\n')
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
    Output.append ('\toutput wire HRESP,\n')

    # Unique Ports
    GPIOList = Self.Data['ports'].get ('gpio')
    if GPIOList:
      Output.append ('\n\t// Peripheral Ports\n')
      for GPIO in GPIOList:
        Output.append ('\t%s\t[%d:0]\t%s,\n' % (GPIO['direction'], GPIO['bitwidth'] - 1, GPIO['name']))

    # IRQ
    if Self.Data['ports'].get ('irq') == True:
      Output.append ('\n\t// IRQ\n')
      Output.append ('\toutput\t\tIRQ\n')
    if ',' in Output[-1]:
      Output[-1] = Output[-1].replace (',', '')
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
    Output.append ('\twire memerror;\n')
    Output.append ('\twire [DATA_WIDTH - 1:0] memdout;\n')
    Output.append ('\n')

    # -- Routing
    Output.append ('\t// -- Routing\n')
    Output.append ('\tassign memerror = werror | rerror;\n')
    Output.append ('\tassign addr = memaddr [ADDR_MSB:ADDR_LSB];\n')
    Output.append ('\tassign wren = memen && (memwe != 0);\n')
    Output.append ('\tassign rden = memen && (memwe == 0);\n')

    # Instantiations
    Output.append ('\t// Instantiations\n')
    Output.append ('\t%s_ahb_interpreter #(\n' % (Self.Data['name']))
    Output.append ('\t\t.DATA_WIDTH (DATA_WIDTH)\n')
    Output.append ('\t) %s_ahb_interpreter_inst (\n' % (Self.Data['name']))
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
    Output.append ('\t\t.MERROR (memerror),\n')
    Output.append ('\t\t.MDOUT (memdout)\n')
    Output.append ('\t);\n')
    Output.append ('\n')

    Output.append ('\t%s_register_io #(\n' % (Self.Data['name']))
    Output.append ('\t\t.DATA_WIDTH (DATA_WIDTH)\n')
    Output.append ('\t) %s_register_io_inst (\n' % (Self.Data['name']))
    Output.append ('\t\t.CLK (HCLK),\n')
    Output.append ('\t\t.RESETn (HRESETn),\n')
    Output.append ('\n')
    Output.append ('\t\t.WADDR (addr),\n')
    Output.append ('\t\t.WDATA (memdin),\n')
    Output.append ('\t\t.WVALID (wren),\n')
    Output.append ('\t\t.WERROR (werror),\n')
    Output.append ('\t\t.RADDR (addr),\n')
    Output.append ('\t\t.RDATA (memdout),\n')
    Output.append ('\t\t.RVALID (rden),\n')
    Output.append ('\t\t.RERROR (rerror),\n')

    GPIOList = Self.Data['ports'].get ('gpio')
    if GPIOList:
      Output.append ('\n')
      for GPIO in GPIOList:
        Output.append ('\t\t.%s (%s),\n' % (GPIO['name'], GPIO['name']))
    if Self.Data['ports'].get ('irq') == True:
      Output.append ('\n')
      Output.append ('\t\t.IRQ (IRQ)\n')
    if ',' in Output[-1]:
      Output[-1] = Output[-1].replace (',', '')
    Output.append ('\t);\n\n')
    Output.append ('endmodule\n')

    with open (OutFile, 'w') as Verilog:
      Verilog.writelines (Output)
    print ("Done... Wrote File To %s" % (OutFile))

if __name__ == '__main__':
  print (sys.argv[1])
  p = AHBPeripheral (sys.argv[1])
  p.CreatePeripheral ()

