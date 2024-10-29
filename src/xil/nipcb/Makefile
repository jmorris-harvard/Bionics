PROJECT:=nipcb
PART:=xc7a200tfbg484-1
TOP:=TopWrapper
# BOARD:=digilentinc.com:arty-a7-100:part0:1.0


MASTERSCRIPTDIR:=../../scripts/tcl
TEMPDIR:=./temp
BUILDDIR:=./build
SCRIPTSDIR:=./scripts
SIMDIR:=./sim
SRCDIR:=./src

LOGFILE:=$(TEMPDIR)/$(PROJECT)_$(PART).log

VIVADO:=vivado
VIVADOLOGFILE:=$(TEMPDIR)/$(PROJECT)_vivado.log

VCS:=vcs
VCSLOGFILE:=$(TEMPDIR)/$(PROJECT)_vcs.log

all:

preprocessing: clean synthIpFile readIpFile srcFile 
	@mkdir -p $(TEMPDIR) # Make Directory For Temporary Files
	@cp $(MASTERSCRIPTDIR)/* ./scripts

srcFile:
	@find $(SRCDIR) -name "*.v" -o -name "*.sv" | grep "" | sed "s/.\/src\///g" > src.txt

synthIpFile: 
	@find ./ip/synth -name "*.config" | grep "" | sed "s/.\/ip\/synth\///g" > synthIp.txt

readIpFile: 
	@find ./ip/read -name "*.xci" | grep "" | sed "s/.\/ip\/read\///g" > readIp.txt

simFile:
	@find ./sim -name "*.v" -o -name "*.sv" | grep "" > sim.txt
	@find ./src \( -name "*.v" -o -name "*.sv" \) -not -name "*$(TOP)*" -not -name "ok*.v" | grep "" >> sim.txt
	
sim: simFile
	@vcs -full64 \
			-sverilog \
			-f "sim.txt" \
			-o "$(SIMDIR)/output.vcs" \
			-vcd "$(SIMDIR)/output.vcd" \
			-Mupdate -R \
			-debug_acc+all \
			+incdir+$(SIMDIR) \
			+incdir+$(SRCDIR)/rtl/ \
			+incdir+$(SRCDIR)/rtl/core \
			+incdir+$(SRCDIR)/rtl/peripherals \
			+lint=TFIPC-L \
			+define+VCS \
			+vcs+dumparrays+131072 \
			+mda \
	| tee $(VCSLOGFILE)

genIp: preprocessing
	$(VIVADO) -nojournal \
						-log $(LOGFILE) \
						-mode batch \
						-source $(SCRIPTSDIR)/genIp.tcl \
						-tclargs $(PROJECT)_$(PART) $(PART)

synth: preprocessing
	$(VIVADO) -nojournal \
						-log $(LOGFILE) \
						-mode batch \
						-source $(SCRIPTSDIR)/synth.tcl \
						-tclargs $(PROJECT)_$(PART) $(PART) $(TOP) \
	| tee $(VIVADOLOGFILE)

createProj: genIp
	$(VIVADO) -nojournal \
						-log $(LOGFILE) \
						-mode tcl \
						-source $(SCRIPTSDIR)/createProj.tcl \
						-tclargs $(PROJECT)_$(PART) $(PART)

clean:
	rm -rf $(BUILDDIR) $(TEMPDIR) .Xil/
