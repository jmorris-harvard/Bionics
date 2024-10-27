#########################################################################
#
# Usage
#
#########################################################################

# Getting Started

## Basic Directory Structure

<project-name>/
  |
  -- src/                       # general source and synthesis hdl code
      |
      -- rtl/                   # hdl source code
          |
          -- core/              # m0 core source (if necessary)
          -- peripherals/       # m0 peripheral modules (if necessary)
          -- ok/                # ok library source (if necessary)
          |
          -- <top-module>.v
      |
      -- <target-device>.xdc
  -- ip/                        # contains ip required to implement project
      |
      -- read/                  # contains <ip>.xci to copy into project
      -- synth/                 # <ip>.config to synthesize 
  -- sim/                       # simulation sources and outputs
      |
      --tb.v
  -- temp/                      # random temporary objects (logs, ...)
  -- scripts/                   # synthesis python and tcl scripts
  -- build/                     # synthesis outputs
      |
      -- ip/                    # generated ip outputs
      -- synth.bit
  |
  -- src.txt
  -- sim.txt
  -- readIp.txt
  -- synthIp.txt

## Setup Project

### Makefile

Set PROJECT:=<project-name>
Set PART:=<fpga-part-number> and ensure .xdc uses the same name
Set TOP:=<synthesis-top-module-name>

Set TEMPDIR,BUILDDIR,SCRIPTDIR,SIMDIR,SRCDIR should you wish to change the names

SET VIVADO,VCS should the toolpath not be in path

### Source Files

Write all verilog source into <project-name>/src

Add all core files into <project-name>/src/rtl/core as they will not be placed on the git

Run `make srcFile` and verify all synthesis source is in output `src.txt`

### Ip Files

Copy precompiled XCI into <project-name>/ip/read

Create config in <project-name>/ip/synth to create ip during synthesis

Run `make synthIpFile` and verify all synth configs are in output `synthIp.txt`

Run `make readIpFile` and verify all .xci files are in output `readIp.txt`

Run `make genIp` to generate ip intermediates, will be located in <project-name>/build/ip/<ip-name>
Use <ip-name>.veo to understand how ip should be instantiated in verilog
Use <ip-name>.prop to get all properties that can be used in ip config file

## Simulation

### Source Files

Place simulation sources in <project-name>/sim/, including tb.sv, simulation memory 
blocks, other ip relacements, etc.

Note: Files referenced in testbench should be relative to <project-name> directory

Run `make sim` to simulate using vcs

Output traces will be placed in <project-name>/sim

## Synthesis

Run  `make synth` to start synthesis run, output will be printed to terminal and 
copied into <project-name>/temp/<project-name>-<part-number>.log

###################################################################################
#
# M0 Development
#
###################################################################################

# Bus

Use `<project-name>/src/rtl/peripherals/ahb_interconnect.sh <num-slaves> <num-masters>` 
to generate bus with required ports (need at least 2 masters to communicate with memories

## Peripherals

Create required interface using json configs located in <project-name>/src/rtl/peripheral/config

Run `<project-name>/<script-dir>/genPeripheral.py config/<peripheral-name>.json` to generate
peripheral wrapper

Populate wrapper with custom logic

# Top Module

Create Top.json file with memories and peripheral locations and sizes

Run `<project-name>/<script-dir>/genTopModule.py` to generate Top.v

# Simulation

Run `<project-name>/<script-dir>/genTestbench.py` to generate tb.v

Populate testbench with custom test logic

###################################################################################
#
# Important Notes
#
###################################################################################

# Working With Precompiled XCI

- Ensure IP was generated under the same part number as the current target
- Go into .xci
  - Set "gen_directory" value to "."
  - Set "OUTPUTDIR" value to "."
  - Set "SHAREDDIR" value to "." 

# Valid Init Files

- Does not work with global variables

# About IP Blocks

- For memories (in particular the Block Memory Generator in Xilinx) 
  the Write_Depth should be the desired depth in WORDS (meaning total
  bytes divided by number bytes in a word)

- Also related to Block Memory Generator, the block should be indexed by
  word as opposed to by byte
