import json
import sys

class TopModule:
  DefaultTopJSONFile = 'Top.json'
  def __init__ (Self, Filename = DefaultTopJSONFile):
    Self.Filename = Filename
    Self.HasJSONData = False
    Self.ParseJSON ()

  def ParseJSON (Self, Filename = None):
    if Filename:
      Self.Filename = Filename

    Self.HasJSONData = False
    if not Self.Filename:
      return # Error

    with open (Self.Filename, 'r') as JSON:
      Self.Data = json.load (JSON)
    for Peripheral in Self.Data['peripherals']:
      # Load all peripheral data
      with open (Peripheral['file'], 'r') as JSON:
        Peripheral['data'] = json.load (JSON)
    Self.HasJSONData = True

  def CreateTopModule (Self, OutFilename = None):
    if not Self.HasJSONData:
      return # Error

    OutFile = OutFilename if OutFilename else 'Top.sv'

    Output = []
    # Add Header
    Output.append ('`timescale 1ns / 1ps\n')
    
    Output.append ('module Top (\n')
    Output.append ('\t// Clocks and Resets\n')
    Output.append ('\tinput wire CLK,\n')
    Output.append ('\tinput wire RESETn,\n')
    Output.append ('\n')

    Output.append ('\t// Core Debug Signals\n')
    Output.append ('\tinput wire SWCLKTCK,\n')
    Output.append ('\tinput wire SWRSTn,\n')
    Output.append ('\t// input wire nTRST,\n')
    Output.append ('\tinput wire SWDITMS,\n')
    Output.append ('\t// input wire TDI,\n')
    Output.append ('\toutput wire SWDO,\n')
    Output.append ('\toutput wire SWDOEN,\n')
    Output.append ('\t// output wire TDO,\n')
    Output.append ('\t// output wire nTDOEN,\n')
    Output.append ('\n')

    # Exposed Memories
    for Memory in Self.Data['memories']:
      if Memory['expose'] == True:
        # Expose all AHB Comm Ports
        Output.append ('\t// Exposed %s\n' % (Memory['name']))
        Output.append ('\toutput wire %s_hclk,\n' % (Memory['name']))
        Output.append ('\toutput wire %s_hresetn,\n' % (Memory['name']))
        Output.append ('\toutput wire [%d:0] %s_haddr,\n' % (Self.Data['bitwidth'] - 1, Memory['name']))
        Output.append ('\toutput wire [2:0] %s_hburst,\n' % (Memory['name']))
        Output.append ('\toutput wire %s_hmastlock,\n' % (Memory['name']))
        Output.append ('\toutput wire [3:0] %s_hprot,\n' % (Memory['name']))
        Output.append ('\toutput wire [2:0] %s_hsize,\n' % (Memory['name']))
        Output.append ('\toutput wire [1:0] %s_htrans,\n' % (Memory['name']))
        Output.append ('\toutput wire [%d:0] %s_hwdata,\n' % (Self.Data['bitwidth'] - 1, Memory['name']))
        Output.append ('\toutput wire %s_hwrite,\n' % (Memory['name']))
        Output.append ('\toutput wire %s_hsel,\n' % (Memory['name']))
        Output.append ('\tinput wire [%d:0] %s_hrdata,\n' % (Self.Data['bitwidth'] - 1, Memory['name']))
        Output.append ('\tinput wire %s_hready,\n' % (Memory['name']))
        Output.append ('\tinput wire %s_hresp,\n' % (Memory['name']))
        Output.append ('\n')

    # Exposed Peripherals
    for Peripheral in Self.Data['peripherals']:
      if not Peripheral['expose'] == False:
        # Expose all AHB Comm Ports
        Output.append ('\t// Exposed %s\n' % (Peripheral['name']))
        Output.append ('\toutput wire %s_hclk,\n' % (Peripheral['name']))
        Output.append ('\toutput wire %s_hresetn,\n' % (Peripheral['name']))
        Output.append ('\toutput wire [%d:0] %s_haddr,\n' % (Self.Data['bitwidth'] - 1, Peripheral['name']))
        Output.append ('\toutput wire [2:0] %s_hburst,\n' % (Peripheral['name']))
        Output.append ('\toutput wire %s_hmastlock,\n' % (Peripheral['name']))
        Output.append ('\toutput wire [3:0] %s_hprot,\n' % (Peripheral['name']))
        Output.append ('\toutput wire [2:0] %s_hsize,\n' % (Peripheral['name']))
        Output.append ('\toutput wire [1:0] %s_htrans,\n' % (Peripheral['name']))
        Output.append ('\toutput wire [%d:0] %s_hwdata,\n' % (Self.Data['bitwidth'] - 1, Peripheral['name']))
        Output.append ('\toutput wire %s_hwrite,\n' % (Peripheral['name']))
        Output.append ('\toutput wire %s_hsel,\n' % (Peripheral['name']))
        Output.append ('\tinput wire [%d:0] %s_hrdata,\n' % (Self.Data['bitwidth'] - 1, Peripheral['name']))
        Output.append ('\tinput wire %s_hready,\n' % (Peripheral['name']))
        Output.append ('\tinput wire %s_hresp,\n' % (Peripheral['name']))
        # Expose IRQ to Core
        if Peripheral['data']['ports'].get ('irq') == True:
          Output.append ('\tinput wire %s_irq,\n' % (Peripheral['name']))
        Output.append ('\n')
      else:
        # Expose GPIO
        for GPIO in Peripheral['data']['ports'].get ('gpio'):
          Output.append ('\t%s [%d:0] %s_%s,\n' % (GPIO['direction'], GPIO['bitwidth'] - 1, Peripheral['name'], GPIO['name']))
        Output.append ('\n')

    # Clean
    while Output[-1] == '\n':
      Output.pop ()
    if ',' in Output[-1]:
      Output[-1] = Output[-1].replace (',', '')
    Output.append (');\n')
    Output.append ('\n')

    # Signals
    # -- Core
    Output.append ('\t// Signals\n')
    Output.append ('\t// -- Core\n')
    Output.append ('\twire\t\tmcu_clk;\n')
    Output.append ('\twire\t\tmcu_hresetn;\n')
    Output.append ('\twire\t\tmcu_hsel = 1\'b1;\n')
    Output.append ('\twire [%d:0] mcu_haddr;\n' % (Self.Data['bitwidth'] - 1))
    Output.append ('\twire [2:0] mcu_hburst;\n')
    Output.append ('\twire\t\tmcu_hmastlock;\n')
    Output.append ('\twire [3:0] mcu_hprot;\n')
    Output.append ('\twire [2:0] mcu_hsize;\n')
    Output.append ('\twire [1:0] mcu_htrans;\n')
    Output.append ('\twire [%d:0] mcu_hwdata;\n' % (Self.Data['bitwidth'] - 1))
    Output.append ('\twire\t\tmcu_hwrite;\n')
    Output.append ('\twire [%d:0] mcu_hrdata;\n' % (Self.Data['bitwidth'] - 1))
    Output.append ('\twire\t\tmcu_hready;\n')
    Output.append ('\twire\t\tmcu_hresp;\n')
    Output.append ('\twire\t\tmcu_hmaster;\n')
    Output.append ('\twire\t\tmcu_dbgrestart = 1\'b0;\n')
    Output.append ('\twire\t\tmcu_edbgrq = 1\'b0;\n')
    Output.append ('\twire\t\tmcu_nmi = 1\'b0;\n')
    Output.append ('\twire [31:0] mcu_irq;\n')
    Output.append ('\n')

    # -- Memories
    for Memory in Self.Data['memories']:
      if Memory['expose'] == False:
        # Expose all AHB Comm Ports
        Output.append ('\t// -- %s\n' % (Memory['name']))
        Output.append ('\twire %s_hclk;\n' % (Memory['name']))
        Output.append ('\twire %s_hresetn;\n' % (Memory['name']))
        Output.append ('\twire [%d:0] %s_haddr;\n' % (Self.Data['bitwidth'] - 1, Memory['name']))
        Output.append ('\twire [2:0] %s_hburst;\n' % (Memory['name']))
        Output.append ('\twire %s_hmastlock;\n' % (Memory['name']))
        Output.append ('\twire [3:0] %s_hprot;\n' % (Memory['name']))
        Output.append ('\twire [2:0] %s_hsize;\n' % (Memory['name']))
        Output.append ('\twire [1:0] %s_htrans;\n' % (Memory['name']))
        Output.append ('\twire [%d:0] %s_hwdata;\n' % (Self.Data['bitwidth'] - 1, Memory['name']))
        Output.append ('\twire %s_hwrite;\n' % (Memory['name']))
        Output.append ('\twire %s_hsel;\n' % (Memory['name']))
        Output.append ('\twire %s_hready;\n' % (Memory['name']))
        Output.append ('\twire [%d:0] %s_hrdata;\n' % (Self.Data['bitwidth'] - 1, Memory['name']))
        Output.append ('\twire %s_hresp;\n' % (Memory['name']))
        Output.append ('\n')

    # -- Peripherals
    for Peripheral in Self.Data['peripherals']:
      if Peripheral['expose'] == False:
        # Expose all AHB Comm Ports
        Output.append ('\t// -- %s\n' % (Peripheral['name']))
        Output.append ('\twire %s_hclk;\n' % (Peripheral['name']))
        Output.append ('\twire %s_hresetn;\n' % (Peripheral['name']))
        Output.append ('\twire [%d:0] %s_haddr;\n' % (Self.Data['bitwidth'] - 1, Peripheral['name']))
        Output.append ('\twire [2:0] %s_hburst;\n' % (Peripheral['name']))
        Output.append ('\twire %s_hmastlock;\n' % (Peripheral['name']))
        Output.append ('\twire [3:0] %s_hprot;\n' % (Peripheral['name']))
        Output.append ('\twire [2:0] %s_hsize;\n' % (Peripheral['name']))
        Output.append ('\twire [1:0] %s_htrans;\n' % (Peripheral['name']))
        Output.append ('\twire [%d:0] %s_hwdata;\n' % (Self.Data['bitwidth'] - 1, Peripheral['name']))
        Output.append ('\twire %s_hwrite;\n' % (Peripheral['name']))
        Output.append ('\twire %s_hsel;\n' % (Peripheral['name']))
        Output.append ('\twire %s_hready;\n' % (Peripheral['name']))
        Output.append ('\twire [%d:0] %s_hrdata;\n' % (Self.Data['bitwidth'] - 1, Peripheral['name']))
        Output.append ('\twire %s_hresp;\n' % (Peripheral['name']))
        # Expose IRQ to Core
        if Peripheral['data']['ports'].get ('irq') == True:
          Output.append ('\twire %s_irq;\n' % (Peripheral['name']))
        Output.append ('\n')

    # Routing
    Output.append ('\t// Routing\n')
    # -- Core
    Output.append ('\t// -- Core\n')
    Output.append ('\tassign mcu_clk = CLK;\n')
    I = 0
    for Peripheral in Self.Data['peripherals']:
      if Peripheral['data']['ports'].get ('irq') == True:
        Output.append ('\tassign mcu_irq[%d] = %s_irq;\n' % (I, Peripheral['name']))
        I = I + 1
    if I < 32:
      Output.append ('\tassign mcu_irq[31:%d] = {(%d){1\'b0}};\n' % (I, 32 - I))
    Output.append ('\n')

    # -- Memorys
    for Memory in Self.Data['memories']:
      Output.append ('\t// -- %s\n' % (Memory['name']))
      Output.append ('\tassign %s_hclk = mcu_clk;\n' % (Memory['name']))
      Output.append ('\tassign %s_hresetn = mcu_hresetn;\n' % (Memory['name']))
      Output.append ('\tassign %s_hmastlock = 1\'b0;\n' % (Memory['name']))
      Output.append ('\n')

    # -- Peripherals
    for Peripheral in Self.Data['peripherals']:
      Output.append ('\t// -- %s\n' % (Peripheral['name']))
      Output.append ('\tassign %s_hclk = mcu_clk;\n' % (Peripheral['name']))
      Output.append ('\tassign %s_hresetn = mcu_hresetn;\n' % (Peripheral['name']))
      Output.append ('\tassign %s_hmastlock = 1\'b0;\n' % (Peripheral['name']))
      Output.append ('\n')

    # Instantiations
    Output.append ('\t// Instantiations\n')
    # -- Core
    Output.append ('\t// -- Core\n')
    Output.append ('\tCM0DbgAHB #(\n')
    Output.append ('\t\t.ACG (0),\n')
    Output.append ('\t\t.BE (0),\n')
    Output.append ('\t\t.BKPT (4),\n')
    Output.append ('\t\t.DBG (1),\n')
    Output.append ('\t\t.JTAGnSW (0),\n')
    Output.append ('\t\t.NUMIRQ (32),\n')
    Output.append ('\t\t.RAR (0),\n')
    Output.append ('\t\t.SMUL (0),\n')
    Output.append ('\t\t.SYST (1),\n')
    Output.append ('\t\t.WIC (1),\n')
    Output.append ('\t\t.WICLINES (34),\n')
    Output.append ('\t\t.WPT (2)\n')
    Output.append ('\t) u_core (\n')
    Output.append ('\t\t.CLK (mcu_clk),\n')
    Output.append ('\t\t.SWCLKTCK (SWCLKTCK),\n')
    Output.append ('\t\t.SWRSTn (SWRSTn),\n')
    Output.append ('\t\t.nTRST (1\'b1),\n')
    Output.append ('\t\t.SYSRESETn (RESETn),\n')
    Output.append ('\t\t.HRESETn (mcu_hresetn),\n')
    Output.append ('\n')
    Output.append ('\t\t.SWDITMS (SWDITMS),\n')
    Output.append ('\t\t.TDI (1\'b0),\n')
    Output.append ('\t\t.SWDO (SWDO),\n')
    Output.append ('\t\t.SWDOEN (SWDOEN),\n')
    Output.append ('\t\t.TDO (),\n')
    Output.append ('\t\t.nTDOEN (),\n')
    Output.append ('\t\t.DBGRESTART (mcu_dbgrestart),\n')
    Output.append ('\t\t.DBGRESTARTED (DBGRESTARTED),\n')
    Output.append ('\t\t.EDBGRQ (mcu_edbgrq),\n')
    Output.append ('\t\t.HALTED (HALTED),\n')
    Output.append ('\n')
    Output.append ('\t\t.HADDR (mcu_haddr),\n')
    Output.append ('\t\t.HBURST (mcu_hburst),\n')
    Output.append ('\t\t.HMASTLOCK (mcu_mastlock),\n')
    Output.append ('\t\t.HPROT (mcu_hprot),\n')
    Output.append ('\t\t.HSIZE (mcu_hsize),\n')
    Output.append ('\t\t.HTRANS (mcu_htrans),\n')
    Output.append ('\t\t.HWDATA (mcu_hwdata),\n')
    Output.append ('\t\t.HWRITE (mcu_hwrite),\n')
    Output.append ('\t\t.HRDATA (mcu_hrdata),\n')
    Output.append ('\t\t.HREADY (mcu_hready),\n')
    Output.append ('\t\t.HRESP (mcu_hresp),\n')
    Output.append ('\t\t.HMASTER (mcu_hmaster),\n')
    Output.append ('\n')
    Output.append ('\t\t.NMI (mcu_nmi),\n')
    Output.append ('\t\t.IRQ (mcu_irq),\n')
    Output.append ('\t\t.LOCKUP (LOCKUP)\n')
    Output.append ('\t);\n')
    Output.append ('\n')

    # -- AHB Interconnect
    Output.append ('\t// Interconnect\n')
    Output.append ('\tahb_interconnect #(\n')
    Output.append ('\t\t.DATA_WIDTH (%d),\n' % (Self.Data['bitwidth']))
    Output.append ('\t\t.ADDR_WIDTH (%d),\n' % (Self.Data['bitwidth']))
    Output.append ('\n')

    I = 0
    for Memory in Self.Data['memories']:
      Output.append ('\t\t.M%01d_PASSTHROUGH (0),\n' % (I))
      Output.append ('\t\t.M%01d_BASEADDR (32\'h%s),\n' % (I, Memory['base']))
      Output.append ('\t\t.M%01d_SIZE (32\'h%s),\n' % (I, Memory['size']))
      Output.append ('\n')
      I = I + 1

    for Peripheral in Self.Data['peripherals']:
      Output.append ('\t\t.M%01d_PASSTHROUGH (0),\n' % (I))
      Output.append ('\t\t.M%01d_BASEADDR (32\'h%s),\n' % (I, Peripheral['base']))
      Output.append ('\t\t.M%01d_SIZE (32\'h%s),\n' % (I, Peripheral['size']))
      Output.append ('\n')
      I = I + 1
    if Output[-1] == '\n':
      Output.pop ()
    if ',' in Output[-1]:
      Output[-1] = Output[-1].replace (',', '')

    Output.append ('\t) u_interconnect (\n')
    Output.append ('\t\t.HCLK (mcu_clk),\n')
    Output.append ('\t\t.HRESETn (mcu_hresetn),\n')
    Output.append ('\n')

    Output.append ('\t\t.S0_HSEL (mcu_hsel),\n')
    Output.append ('\t\t.S0_HADDR (mcu_haddr),\n')
    Output.append ('\t\t.S0_HWRITE (mcu_hwrite),\n')
    Output.append ('\t\t.S0_HSIZE (mcu_hsize),\n')
    Output.append ('\t\t.S0_HBURST (mcu_hburst),\n')
    Output.append ('\t\t.S0_HPROT (mcu_hprot),\n')
    Output.append ('\t\t.S0_HTRANS (mcu_htrans),\n')
    Output.append ('\t\t.S0_HMASTLOCK (mcu_hmastlock),\n')
    Output.append ('\t\t.S0_HWDATA (mcu_hwdata),\n')
    Output.append ('\t\t.S0_HREADY (mcu_hready),\n')
    Output.append ('\t\t.S0_HRESP (mcu_hresp),\n')
    Output.append ('\t\t.S0_HRDATA (mcu_hrdata),\n')
    Output.append ('\n')
    
    I = 0
    for Memory in Self.Data['memories']:
      Output.append ('\t\t.M%01d_HSEL (%s_hsel),\n' % (I, Memory['name']))
      Output.append ('\t\t.M%01d_HADDR (%s_haddr),\n' % (I, Memory['name']))
      Output.append ('\t\t.M%01d_HWRITE (%s_hwrite),\n' % (I, Memory['name']))
      Output.append ('\t\t.M%01d_HSIZE (%s_hsize),\n' % (I, Memory['name']))
      Output.append ('\t\t.M%01d_HBURST (%s_hburst),\n' % (I, Memory['name']))
      Output.append ('\t\t.M%01d_HPROT (%s_hprot),\n' % (I, Memory['name']))
      Output.append ('\t\t.M%01d_HTRANS (%s_htrans),\n' % (I, Memory['name']))
      Output.append ('\t\t.M%01d_HMASTLOCK (%s_hmastlock),\n' % (I, Memory['name']))
      Output.append ('\t\t.M%01d_HWDATA (%s_hwdata),\n' % (I, Memory['name']))
      Output.append ('\t\t.M%01d_HREADY (%s_hready),\n' % (I, Memory['name']))
      Output.append ('\t\t.M%01d_HRESP (%s_hresp),\n' % (I, Memory['name']))
      Output.append ('\t\t.M%01d_HRDATA (%s_hrdata),\n' % (I, Memory['name']))
      Output.append ('\n')
      I = I + 1

    for Peripheral in Self.Data['peripherals']:
      Output.append ('\t\t.M%01d_HSEL (%s_hsel),\n' % (I, Peripheral['name']))
      Output.append ('\t\t.M%01d_HADDR (%s_haddr),\n' % (I, Peripheral['name']))
      Output.append ('\t\t.M%01d_HWRITE (%s_hwrite),\n' % (I, Peripheral['name']))
      Output.append ('\t\t.M%01d_HSIZE (%s_hsize),\n' % (I, Peripheral['name']))
      Output.append ('\t\t.M%01d_HBURST (%s_hburst),\n' % (I, Peripheral['name']))
      Output.append ('\t\t.M%01d_HPROT (%s_hprot),\n' % (I, Peripheral['name']))
      Output.append ('\t\t.M%01d_HTRANS (%s_htrans),\n' % (I, Peripheral['name']))
      Output.append ('\t\t.M%01d_HMASTLOCK (%s_hmastlock),\n' % (I, Peripheral['name']))
      Output.append ('\t\t.M%01d_HWDATA (%s_hwdata),\n' % (I, Peripheral['name']))
      Output.append ('\t\t.M%01d_HREADY (%s_hready),\n' % (I, Peripheral['name']))
      Output.append ('\t\t.M%01d_HRESP (%s_hresp),\n' % (I, Peripheral['name']))
      Output.append ('\t\t.M%01d_HRDATA (%s_hrdata),\n' % (I, Peripheral['name']))
      Output.append ('\n')
      I = I + 1

    if Output[-1] == '\n':
      Output.pop ()
    if ',' in Output[-1]:
      Output[-1] = Output[-1].replace (',', '')
    Output.append ('\t);\n')
    Output.append ('\n')

    # -- Memories
    for Memory in Self.Data['memories']:
      if Memory['expose'] == False:
        Output.append ('\t%s #(\n' % (Memory['module']))
        Output.append ('\t\t.DATA_WIDTH (%d),\n' % (Self.Data['bitwidth']))
        Output.append ('\t\t.MEM_BYTES (32\'h%s)\n' % (Memory['size']))
        Output.append ('\t) %s_inst (\n' % (Memory['name']))
        Output.append ('\t\t.HCLK (%s_hclk),\n' % (Memory['name']))
        Output.append ('\t\t.HRESETn (%s_hresetn),\n' % (Memory['name']))
        Output.append ('\n')
        Output.append ('\t\t.HADDR (%s_haddr),\n' % (Memory['name']))
        Output.append ('\t\t.HBURST (%s_hburst),\n' % (Memory['name']))
        Output.append ('\t\t.HPROT (%s_hprot),\n' % (Memory['name']))
        Output.append ('\t\t.HSIZE (%s_hsize),\n' % (Memory['name']))
        Output.append ('\t\t.HTRANS (%s_htrans),\n' % (Memory['name']))
        Output.append ('\t\t.HMASTLOCK (%s_hmastlock),\n' % (Memory['name']))
        Output.append ('\t\t.HWDATA (%s_hwdata),\n' % (Memory['name']))
        Output.append ('\t\t.HWRITE (%s_hwrite),\n' % (Memory['name']))
        Output.append ('\t\t.HSEL (%s_hsel),\n' % (Memory['name']))
        Output.append ('\t\t.HREADYIN (%s_hready),\n' % (Memory['name']))
        Output.append ('\t\t.HRDATA (%s_hrdata),\n' % (Memory['name']))
        Output.append ('\t\t.HREADYOUT (%s_hready),\n' % (Memory['name']))
        Output.append ('\t\t.HRESP (%s_hresp)\n' % (Memory['name']))
        Output.append ('\t);\n')
        Output.append ('\n')

    # -- Peripherals
    for Peripheral in Self.Data['peripherals']:
      if Peripheral['expose'] == False:
        Output.append ('\t%s #(\n' % (Peripheral['module']))
        Output.append ('\t\t.DATA_WIDTH (%d)\n' % (Self.Data['bitwidth']))
        Output.append ('\t) %s_inst (\n' % (Peripheral['name']))
        Output.append ('\t\t.HCLK (%s_hclk),\n' % (Peripheral['name']))
        Output.append ('\t\t.HRESETn (%s_hresetn),\n' % (Peripheral['name']))
        Output.append ('\n')
        Output.append ('\t\t.HADDR (%s_haddr),\n' % (Peripheral['name']))
        Output.append ('\t\t.HBURST (%s_hburst),\n' % (Peripheral['name']))
        Output.append ('\t\t.HPROT (%s_hprot),\n' % (Peripheral['name']))
        Output.append ('\t\t.HSIZE (%s_hsize),\n' % (Peripheral['name']))
        Output.append ('\t\t.HTRANS (%s_htrans),\n' % (Peripheral['name']))
        Output.append ('\t\t.HMASTLOCK (%s_hmastlock),\n' % (Peripheral['name']))
        Output.append ('\t\t.HWDATA (%s_hwdata),\n' % (Peripheral['name']))
        Output.append ('\t\t.HWRITE (%s_hwrite),\n' % (Peripheral['name']))
        Output.append ('\t\t.HSEL (%s_hsel),\n' % (Peripheral['name']))
        Output.append ('\t\t.HREADYIN (%s_hready),\n' % (Peripheral['name']))
        Output.append ('\t\t.HRDATA (%s_hrdata),\n' % (Peripheral['name']))
        Output.append ('\t\t.HREADYOUT (%s_hready),\n' % (Peripheral['name']))
        Output.append ('\t\t.HRESP (%s_hresp),\n' % (Peripheral['name']))
        for GPIO in Peripheral['data']['ports'].get ('gpio'):
          Output.append ('\t\t.%s (%s_%s),\n' % (GPIO['name'], Peripheral['name'], GPIO['name']))
        if Peripheral['data']['ports'].get ('irq') == True:
          Output.append ('\t\t.IRQ (%s_irq)\n' % (Peripheral['name']))
        if ',' in Output[-1]:
          Output[-1] = Output[-1].replace (',', '')
        Output.append ('\t);\n')
        Output.append ('\n')

    Output.append ('endmodule\n')

    with open (OutFile, 'w') as Verilog:
      Verilog.writelines (Output)

if __name__ == '__main__':
  top = TopModule ()
  top.CreateTopModule ()
