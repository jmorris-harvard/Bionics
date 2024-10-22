#!/bin/bash

# VARIABLES
slaves=$1
masters=$2
filename="ahb_interconnect.v"

# PRE-PRECESSING
count=$(( slaves > masters ? slaves : masters ))
#characters = clog2(count)
characters=$(echo $count | awk '{print log($1)/log(10)}' | xargs -I {} sh -c 'echo "a={}; if ( a%1 ) (a+1)/1 else a/1"' | bc)
#characters=2

# MODULE
# -- Parameters
echo -n $'module ahb_interconnect\n#(\r\n\tparameter DATA_WIDTH = 32,\n\tparameter ADDR_WIDTH = 32,\n' > $filename
echo -n $'\n\tparameter IDLE_ENABLE = 1,\n\tparameter IDLE_BASEADDR = 32\'hE000_0000,\n\tparameter IDLE_SIZE = 32\'h2000_0000,\n' >> $filename
header=$'\n\tparameter MASTERS_COUNT = XY'
echo -n "${header//XY/$masters}" >> $filename

for (( index=0; index<$masters; index++ ))
do
	parameters=$',\n\n\tparameter MXY_PASSTHROUGH = 0,\n\tparameter MXY_BASEADDR = 32\'h0000_0000,\n\tparameter MXY_SIZE = 32\'h0010_0000'
	echo -n "${parameters//XY/$(printf "%0${characters}d" $index)}" >> $filename
done
echo -n $'\n)\n' >> $filename

# -- Ports
echo -n $'(\n' >> $filename
# ---- Slaves
echo -n $'\t// COMMON\n\tinput  wire        HCLK,\n\tinput  wire        HRESETn' >> $filename
echo -n $',\n' >> $filename
echo -n $'\n\t// SLAVES\n' >> $filename
for (( index=0; index<$slaves; index++ ))
do
	ports=$'\t// -- #XY\n\tinput  wire        SXY_HSEL,\n\tinput  wire [ADDR_WIDTH-1:0]  SXY_HADDR,\n\tinput  wire        SXY_HWRITE,\n\tinput  wire [2:0]  SXY_HSIZE,\n\tinput  wire [2:0]  SXY_HBURST,\n\tinput  wire [3:0]  SXY_HPROT,\n\tinput  wire [1:0]  SXY_HTRANS,\n\tinput  wire        SXY_HMASTLOCK,\n\tinput  wire [DATA_WIDTH-1:0]  SXY_HWDATA,\n\tinput  wire        SXY_HMASTER,\n\n\toutput wire        SXY_HREADY,\n\toutput wire        SXY_HRESP,\n\toutput wire [DATA_WIDTH-1:0]  SXY_HRDATA'
	echo -n "${ports//XY/$(printf "%0${characters}d" $index)}" >> $filename
	if [[ $index -lt $slaves-1 ]]
	then
		echo -n $',\n\n' >> $filename
	fi
done
echo -n $',\n' >> $filename
# ---- Masters
echo -n $'\n\t// MASTERS\n' >> $filename
for (( index=0; index<$masters; index++ ))
do
	ports=$'\t// -- #XY\n\toutput wire        MXY_HSEL,\n\toutput wire [ADDR_WIDTH-1:0]  MXY_HADDR,\n\toutput wire        MXY_HWRITE,\n\toutput wire [2:0]  MXY_HSIZE,\n\toutput wire [2:0]  MXY_HBURST,\n\toutput wire [3:0]  MXY_HPROT,\n\toutput wire [1:0]  MXY_HTRANS,\n\toutput wire        MXY_HMASTLOCK,\n\toutput wire [DATA_WIDTH-1:0]  MXY_HWDATA,\n\n\tinput  wire        MXY_HREADY,\n\tinput  wire        MXY_HRESP,\n\tinput  wire [DATA_WIDTH-1:0]  MXY_HRDATA'
	echo -n "${ports//XY/$(printf "%0${characters}d" $index)}" >> $filename
	if [[ $index -lt $masters-1 ]]
	then
		echo -n $',\n\n' >> $filename
	fi
done
echo -n $'\n' >> $filename
echo -n $');\n\n' >> $filename

# -- Body
echo -n $'\n\t// INCLUDES\n\t`include "ahb_defs.v"\n\n\n' >> $filename
echo -n $'\t// PARAMETERS\n' >> $filename
echo -n $'\tlocalparam M_PASSTHROUGH =' >> $filename
for (( index=0; index<$masters; index++ ))
do
	if [[ $index -ne 0 ]]
	then
		echo -n $'\t                        ||' >> $filename
	fi
	ports=$' ( MASTERS_COUNT > XY ? MXY_PASSTHROUGH : 0 )'
	echo -n "${ports//XY/$(printf "%0${characters}d" $index)}" >> $filename
	if [[ $index -lt $masters-1 ]]
	then
		echo -n $'\n' >> $filename
	else
		echo -n $';\n' >> $filename
	fi
done
echo -n $'\tlocalparam IDLE_HEAD = $clog2(IDLE_SIZE);\n' >> $filename
echo -n $'\n\n' >> $filename

# ---- Signals
echo -n $'\t// SIGNALS\n' >> $filename
# ------ Common
echo -n $'\t// -- Common\n\twire        hsel;\n\twire [ADDR_WIDTH-1:0]  haddr;\n\twire        hwrite;\n\twire [2:0]  hsize;\n\twire [2:0]  hburst;\n\twire [3:0]  hprot;\n\twire [1:0]  htrans;\n\twire        hmastlock;\n\twire [DATA_WIDTH-1:0]  hwdata;\n\twire        hmaster;\n\n\twire        hready;\n\twire        hresp;\n\twire [DATA_WIDTH-1:0]  hrdata;\n\n\treg         _trans;\n\treg         _idle;\n\treg         _debugger;\n' >> $filename
# ------ Masters
echo -n $'\t// -- Masters\n' >> $filename
for (( index=0; index<$masters; index++ ))
do
	ports=$'\t// ---- #XY\n\twire        mXY_hready;\n\twire        mXY_hready_en;\n\twire        mXY_hresp;\n\twire        mXY_hresp_en;\n\twire [DATA_WIDTH-1:0]  mXY_hrdata;\n\twire        mXY_hrdata_en;\n'
	echo -n "${ports//XY/$(printf "%0${characters}d" $index)}" >> $filename
done
echo -n $'\n\n' >> $filename

# ---- Routing
echo -n $'\t// ROUTING\n' >> $filename
# ------ Slaves
echo -n $'\t// -- Slaves\n' >> $filename
echo -n $'\tassign hsel      = S0_HSEL;\n\tassign haddr     = S0_HADDR;\n\tassign hwrite    = S0_HWRITE;\n\tassign hsize     = S0_HSIZE;\n\tassign hburst    = S0_HBURST;\n\tassign hprot     = S0_HPROT;\n\tassign htrans    = S0_HTRANS;\n\tassign hmastlock = S0_HMASTLOCK;\n\tassign hwdata    = S0_HWDATA;\n\tassign hmaster   = S0_HMASTER;\n\tassign S0_HREADY = hready;\n\tassign S0_HRESP  = hresp;\n\tassign S0_HRDATA = hrdata;\n' >> $filename
# ------ Masters
echo -n $'\t// -- Masters\n' >> $filename
echo -n $'\tassign hresp =' >> $filename
for (( index=0; index<$masters; index++ ))
do
	if [[ $index -ne 0 ]]
	then
		echo -n $'\t             :' >> $filename
	fi
	ports=$' mXY_hresp_en ? MXY_HRESP\n'
	echo -n "${ports//XY/$(printf "%0${characters}d" $index)}" >> $filename
done
echo -n $'\t             : (!M_PASSTHROUGH & !_idle & !_debugger && _trans) ? `AHB_RSP_ERROR\n' >> $filename
echo -n $'\t             : `AHB_RSP_OKAY;\n' >> $filename
echo -n $'\tassign hready =' >> $filename
for (( index=0; index<$masters; index++ ))
do
	if [[ $index -ne 0 ]]
	then
		echo -n $'\t              :' >> $filename
	fi
	ports=$' mXY_hready_en ? MXY_HREADY\n'
	echo -n "${ports//XY/$(printf "%0${characters}d" $index)}" >> $filename
done
echo -n $'\t              : (!M_PASSTHROUGH & !_idle & !_debugger && _trans) ? 1\'b0\n' >> $filename
echo -n $'\t              : 1\'b1;\n' >> $filename
echo -n $'\tassign hrdata =' >> $filename
for (( index=0; index<$masters; index++ ))
do
	if [[ $index -ne 0 ]]
	then
		echo -n $'\t              :' >> $filename
	fi
	ports=$' mXY_hrdata_en ? MXY_HRDATA\n'
	echo -n "${ports//XY/$(printf "%0${characters}d" $index)}" >> $filename
done
echo -n $'\t			  : {DATA_WIDTH{1\'bZ}};\n' >> $filename
echo -n $'\n\n' >> $filename

# ---- Logic
echo -n $'\t// LOGIC\n' >> $filename
# ------ Idle
echo -n $'\t// -- Idle\n' >> $filename
echo -n $'\talways @ (posedge HCLK) begin\n\t\tif ( !HRESETn ) begin\n\t\t\t_idle <= 1\'b0;\n\t\t\t_debugger <= 1\'b0;\n\t\t\t_trans <= 1\'b0;\n\t\tend\n\t\telse begin\n\t\t\t_idle <= (IDLE_ENABLE ? haddr[ADDR_WIDTH-1:IDLE_HEAD] == IDLE_BASEADDR[ADDR_WIDTH-1:IDLE_HEAD] : 1\'b0);\n\t\t\t_debugger <= (hmaster == 1\'b1);\n\t\t\t_trans <= (htrans != 2\'b00);\n\t\tend\n\tend\n' >> $filename
echo -n $'\n\n' >> $filename

# ---- Instantiations
echo -n $'\t// INSTANTIATIONS\n' >> $filename
# ------ Masters
echo -n $'\t// -- Masters\n' >> $filename
for (( index=0; index<$masters; index++ ))
do
	ports=$'\tgenerate\n\t\tif ( MASTERS_COUNT > XY ) begin\n\t\t\tahb_interconnect_master #(\n\t\t\t\t.DATA_WIDTH (DATA_WIDTH),\n\t\t\t\t.ADDR_WIDTH (ADDR_WIDTH),\n\t\t\t\t.PASSTHROUGH(MXY_PASSTHROUGH),\n\t\t\t\t.BASEADDR   (MXY_BASEADDR),\n\t\t\t\t.SIZE       (MXY_SIZE)\n\t\t\t) MXY (\n\t\t\t\t.HCLK   (HCLK),\n\t\t\t\t.HRESETn(HRESETn),\n\n\t\t\t\t.S_HADDR    (haddr),\n\t\t\t\t.S_HBURST   (hburst),\n\t\t\t\t.S_HMASTLOCK(hmastlock),\n\t\t\t\t.S_HPROT    (hprot),\n\t\t\t\t.S_HSIZE    (hsize),\n\t\t\t\t.S_HTRANS   (htrans),\n\t\t\t\t.S_HWDATA   (hwdata),\n\t\t\t\t.S_HWRITE   (hwrite),\n\t\t\t\t.S_HSEL     (hsel),\n\n\t\t\t\t.S_HRDATA(mXY_hrdata),\n\t\t\t\t.S_HREADY(mXY_hready),\n\t\t\t\t.S_HRESP (mXY_hresp),\n\n\t\t\t\t.M_HADDR    (MXY_HADDR),\n\t\t\t\t.M_HBURST   (MXY_HBURST),\n\t\t\t\t.M_HMASTLOCK(MXY_HMASTLOCK),\n\t\t\t\t.M_HPROT    (MXY_HPROT),\n\t\t\t\t.M_HSIZE    (MXY_HSIZE),\n\t\t\t\t.M_HTRANS   (MXY_HTRANS),\n\t\t\t\t.M_HWDATA   (MXY_HWDATA),\n\t\t\t\t.M_HWRITE   (MXY_HWRITE),\n\t\t\t\t.M_HSEL     (MXY_HSEL),\n\n\t\t\t\t.M_HRDATA(MXY_HRDATA),\n\t\t\t\t.M_HREADY(MXY_HREADY),\n\t\t\t\t.M_HRESP (MXY_HRESP),\n\n\t\t\t\t.M_HREADYen(mXY_hready_en),\n\t\t\t\t.M_HRESPen (mXY_hresp_en),\n\t\t\t\t.M_HRDATAen(mXY_hrdata_en)\n\t\t\t);\n\t\tend\n\t\telse begin\n\t\t\tassign mXY_hready_en = 0;\n\t\t\tassign mXY_hresp_en = 0;\n\t\t\tassign mXY_hrdata_en = 0;\n\t\tend\n\tendgenerate\n'
	echo -n "${ports//XY/$(printf "%0${characters}d" $index)}" >> $filename
done

echo -n $'\n\n' >> $filename
echo -n $'' >> $filename


echo -n $'endmodule\n' >> $filename
