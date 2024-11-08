import json
import os
import sys

class Testbench ():
  DefaultTBFile = 'tb.sv'
  DefaultTopJSON = '../rtl/Top.json'
  def __init__ (Self, Filename = DefaultTopJSON):
    Self.Filename = Filename
    Self.HasJSONData = False
    if Self.Filename:
      Self.ParseJSON ()

  def ParseJSON (Self, Filename = None):
    if Filename:
      Self.Filename = Filename
    Self.HasJSONData = False

    if not Self.Filename:
      return # Error

    Dirname = os.path.dirname (Self.Filename)


    with open (Self.Filename, 'r') as JSON:
      Self.Data = json.load (JSON)

    for Peripheral in Self.Data['peripherals']:
      with open (os.path.join (Dirname, Peripheral['file']), 'r') as JSON:
        Peripheral['data'] = json.load (JSON)
      Self.HasJSONData = True

  def CreateTestbench (Self, OutFilename = DefaultTBFile):
    if not Self.HasJSONData:
      return # Error

    OutFile = OutFilename
    print (OutFile)
    Output = []
    # Add Header
    Output.append ('`timescale 1ps / 1ps\n')

    # Start TB
    Output.append ('module tb ();\n')
    
    # Core Signals
    Output.append ('\treg CLK = 1\'b0;\n')
    Output.append ('\treg RESETn = 1\'b1;\n')
    Output.append ('\n')
    Output.append ('\treg SWCLKTCK = 1\'b0;\n')
    Output.append ('\treg SWRSTn = 1\'b1;\n')
    Output.append ('\treg nTRST = 1\'b1;\n')
    Output.append ('\n')
    Output.append ('\treg SWDITMS = 1\'b0;\n')
    Output.append ('\twire SWDO;\n')
    Output.append ('\twire SWDOEN;\n')
    Output.append ('\n')

    # Memories
    for Memory in Self.Data['memories']:
      Output.append ('\t// -- %s\n' % (Memory['name']))
      Output.append ('\twire %s_mclk;\n' % (Memory['name']))
      Output.append ('\twire %s_mresetn;\n' % (Memory['name']))
      Output.append ('\twire %s_men;\n' % (Memory['name']))
      Output.append ('\twire [%d:0] %s_maddr;\n' % (Self.Data['bitwidth'] - 1, Memory['name']))
      Output.append ('\twire [%d:0] %s_mdin;\n' % (Self.Data['bitwidth'] - 1, Memory['name']))
      Output.append ('\twire [%d:0] %s_mwe;\n' % ((Self.Data['bitwidth'] / 8) - 1, Memory['name']))
      Output.append ('\twire [%d:0] %s_mdout;\n' % (Self.Data['bitwidth'] - 1, Memory['name']))
      Output.append ('\n')

    # Peripherals
    for Peripheral in Self.Data['peripherals']:
      Output.append ('\t// -- %s\n' % (Peripheral['name']))
      if not Peripheral['expose'] == False:
        # Expose all AHB Comm Ports
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
        Output.append ('\twire %s_hwrite;\n' % (Peripheral['name']))
        # Expose IRQ to Core
        if Peripheral['data']['ports'].get ('irq') == True:
          Output.append ('\twire %s_irq;\n' % (Peripheral['name']))
      # Get GPIO
      for GPIO in Peripheral['data']['ports'].get ('gpio'):
        if GPIO['direction'] == 'input':
          Output.append ('\treg [%d:0] %s_%s;\n' % (GPIO['bitwidth'] - 1, Peripheral['name'], GPIO['name']))
        else:
          Output.append ('\twire [%d:0] %s_%s;\n' % (GPIO['bitwidth'] - 1, Peripheral['name'], GPIO['name']))
      Output.append ('\n')

    # Instantiations
    # -- Top
    Output.append ('\tTop DUT (\n')
    Output.append ('\t\t.CLK (CLK),\n')
    Output.append ('\t\t.RESETn (RESETn),\n')
    Output.append ('\n')
    Output.append ('\t\t.SWCLKTCK (SWCLKTCK),\n')
    Output.append ('\t\t.SWRSTn (SWRSTn),\n')
    Output.append ('\t\t.SWDITMS (SWDITMS),\n')
    Output.append ('\t\t.SWDO (SWDO),\n')
    Output.append ('\t\t.SWDOEN (SWDOEN),\n')
    Output.append ('\n')
    

    # -- Memories
    for Memory in Self.Data['memories']:
      Output.append ('\t\t.%s_mclk (%s_mclk),\n' % (Memory['name'], Memory['name']))
      Output.append ('\t\t.%s_mresetn (%s_mresetn),\n' % (Memory['name'], Memory['name']))
      Output.append ('\t\t.%s_men (%s_men),\n' % (Memory['name'], Memory['name']))
      Output.append ('\t\t.%s_maddr (%s_maddr),\n' % (Memory['name'], Memory['name']))
      Output.append ('\t\t.%s_mdin (%s_mdin),\n' % (Memory['name'], Memory['name']))
      Output.append ('\t\t.%s_mwe (%s_mwe),\n' % (Memory['name'], Memory['name']))
      Output.append ('\t\t.%s_mdout (%s_mdout),\n' % (Memory['name'], Memory['name']))
      Output.append ('\n')

    for Peripheral in Self.Data['peripherals']:
      if not Peripheral['expose'] == False:
        Output.append ('\t\t.%s_hclk (%s_hclk),\n' % (Peripheral['name'], Peripheral['name']))
        Output.append ('\t\t.%s_hresetn (%s_hresetn),\n' % (Peripheral['name'], Peripheral['name']))
        Output.append ('\t\t.%s_haddr (%s_haddr),\n' % (Peripheral['name'], Peripheral['name']))
        Output.append ('\t\t.%s_hburst (%s_hburst),\n' % (Peripheral['name'], Peripheral['name']))
        Output.append ('\t\t.%s_hprot (%s_hprot),\n' % (Peripheral['name'], Peripheral['name']))
        Output.append ('\t\t.%s_hsize (%s_hsize),\n' % (Peripheral['name'], Peripheral['name']))
        Output.append ('\t\t.%s_htrans (%s_htrans),\n' % (Peripheral['name'], Peripheral['name']))
        Output.append ('\t\t.%s_hmastlock (%s_hmastlock),\n' % (Peripheral['name'], Peripheral['name']))
        Output.append ('\t\t.%s_hwdata (%s_hwdata),\n' % (Peripheral['name'], Peripheral['name']))
        Output.append ('\t\t.%s_hwrite (%s_hwrite),\n' % (Peripheral['name'], Peripheral['name']))
        Output.append ('\t\t.%s_hsel (%s_hsel),\n' % (Peripheral['name'], Peripheral['name']))
        Output.append ('\t\t.%s_hready (%s_hready),\n' % (Peripheral['name'], Peripheral['name']))
        Output.append ('\t\t.%s_hrdata (%s_hrdata),\n' % (Peripheral['name'], Peripheral['name']))
        Output.append ('\t\t.%s_hresp (%s_hresp),\n' % (Peripheral['name'], Peripheral['name']))
        if Peripheral['data']['ports'].get ('irq') == True:
          Output.append ('\t\t.%s_irq (%s_irq),\n' % (Peripheral['name'], Peripheral['name']))
      else:
        for GPIO in Peripheral['data']['ports'].get ('gpio'):
          Output.append ('\t\t.%s_%s (%s_%s),\n' % (Peripheral['name'], GPIO['name'], Peripheral['name'], GPIO['name']))
      Output.append ('\n')
    while Output[-1] == '\n':
      Output.pop ()
    if ',' in Output[-1]:
      Output[-1] = Output[-1].replace (',', '')
    Output.append ('\t);\n')
    Output.append ('\n')

    # Exposed Instantiations
    # -- Memories
    for Memory in Self.Data['memories']:
      Output.append ('\t// --- Begin %s Memory ---\n' % (Memory['name']))
      Output.append ('\n')
      Output.append ('\tbram #(\n')
      Output.append ('\t\t.MEM_DEPTH (32\'h%s)' % (Memory['size']))
      if Memory.get ('init') == True:
        Output.append (',\n\t\t.INIT_FILE (%s)' % (Memory['init']))
      else:
        Output.append ('\n')
      Output.append ('\t) %s (\n' % (Memory['name']))
      Output.append ('\t\t.MCLK (%s_mclk),\n' % (Memory['name']))
      Output.append ('\t\t.MRESETn (%s_mresetn),\n' % (Memory['name']))
      Output.append ('\t\t.MEN (%s_men),\n' % (Memory['name']))
      Output.append ('\t\t.MADDR (%s_maddr),\n' % (Memory['name']))
      Output.append ('\t\t.MDIN (%s_mdin),\n' % (Memory['name']))
      Output.append ('\t\t.MWE (%s_mwe),\n' % (Memory['name']))
      Output.append ('\t\t.MDOUT (%s_mdout)\n' % (Memory['name']))
      Output.append ('\t);\n')
      Output.append ('\n')
      Output.append ('\t// --- End %s Memory ---\n' % (Memory['name']))
      Output.append ('\n')

    # -- Peripherals
    for Peripheral in Self.Data['peripherals']:
      if not Peripheral['expose'] == False:
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
        Output.append ('\n')
        for GPIO in Peripheral['data']['ports'].get ('gpio'):
          Output.append ('\t\t.%s (%s_%s),\n' % (GPIO['name'], Peripheral['name'], GPIO['name']))
        if Peripheral['data']['ports'].get ('irq') == True:
          Output.append ('\t\t.IRQ (%s_irq)\n' % (Peripheral['name']))
        if ',' in Output[-1]:
          Output[-1] = Output[-1].replace (',', '')
        Output.append ('\t);\n')
        Output.append ('\n')

    # Testbench
    Output.append ('\tlocalparam CLK_PERIOD = 5000;\n')
    Output.append ('\talways #(CLK_PERIOD / 2) CLK <= ~CLK;\n')
    Output.append ('\n')
    Output.append ('\tinitial begin\n')
    Output.append ('\t\t$display ("Begin Testbench");\n')
    Output.append ('\t\trepeat (10) @(posedge CLK) begin end;\n')
    Output.append ('\n')
    Output.append ('\t\tRESETn = 1\'b0;\n')
    Output.append ('\t\trepeat (10) @(posedge CLK) begin end;\n')
    Output.append ('\n')
    Output.append ('\t\tRESETn = 1\'b1;\n')
    Output.append ('\t\trepeat (10) @(posedge CLK) begin end;\n')
    Output.append ('\n')
    Output.append ('\t\t// Begin Custom Implementation\n')
    Output.append ('\n')
    Output.append ('\t\trepeat (10000) @(posedge CLK) begin end;\n')
    Output.append ('\n')
    Output.append ('\t\t// End Custom Implementation\n')
    Output.append ('\n')
    Output.append ('\t\t$display ("End Testbench");\n')
    Output.append ('\t\t$finish();\n')
    Output.append ('\tend\n')
    Output.append ('\n')
    Output.append ('\tinitial begin\n')
    Output.append ('\t\t$dumpvars (2, tb);\n')
    Output.append ('\tend\n')
    Output.append ('\n')
    Output.append ('\tinitial begin\n')
    Output.append ('\t\t// Safety Kill Process\n')
    Output.append ('\t\trepeat (1000000) @(posedge CLK) begin end;\n')
    Output.append ('\t\t$display ("Testbench Timed Out");\n')
    Output.append ('\t\t$finish ();\n')
    Output.append ('\tend\n')
    Output.append ('\n')
    Output.append ('endmodule\n')

    with open (OutFile, 'w') as Verilog:
      Verilog.writelines (Output)

print (__name__)
if __name__ == '__main__':
  tb = Testbench (sys.argv[1])
  tb.CreateTestbench ()
