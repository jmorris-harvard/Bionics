# Initial Setup
set topDir [pwd]
set scriptDir [file dirname [info script]]
source [file join $scriptDir "utils.tcl"]

# Set Up Project Files
set projectName [lindex $argv 0]
set projectDir "."
set buildDir [file join $projectDir "build"]
set srcDir [file join $projectDir "src"]
set ipDir [file join $projectDir "ip"]
set synthIpDir [file join $ipDir "synth"]
set readIpDir [file join $ipDir "read"]
set ipBuildDir [file join $buildDir "ip"]
file mkdir $buildDir
file mkdir $ipBuildDir

# Create Dummy Project
set partName [lindex $argv 1]
create_project -in_memory -part $partName
# set boardName [lindex $argv 2]
# set_property board_part $boardName [current_project]

# Read/Synth All IP
set synthIpFilename [file join $projectDir "synthIp.txt"]
set synthIpFile [open $synthIpFilename r]
set synthIpFileContents [read -nonewline $synthIpFile]
set synthIps [split $synthIpFileContents "\n"]
close $synthIpFile
puts "Creating ip..."
foreach s $synthIps {
  puts $s
  # Read Config File
  set configDict [UTILS_readIPConfig [file join $synthIpDir $s]]
  set infoDict [dict get $configDict "info"]
  set propertiesDict [dict get $configDict "properties"]
  # Create IP
  set moduleName [dict get $infoDict "name"]
  set localSynthIpDir [file join $ipBuildDir $moduleName]
  create_ip -vlnv [dict get $infoDict "vlnv"] \
            -dir $ipBuildDir \
            -module_name $moduleName \
            -force
  puts "Done creating $moduleName..."
  # Customize IP
  set_property -dict $propertiesDict [get_ips $moduleName] 
  set localSynthIpObj [get_ips $moduleName]
  set localSynthIpFilename [get_property "IP_FILE" $localSynthIpObj]
  set localSynthIpFile [get_files $localSynthIpFilename]
  generate_target all $localSynthIpFile -force
  # Synth IP
  synth_ip $localSynthIpObj
}

set readIpFilename [file join $projectDir "readIp.txt"]
set readIpFile [open $readIpFilename]
set readIpFileContents [read -nonewline $readIpFile]
set readIps [split $readIpFileContents "\n"]
close $readIpFile
puts "Reading remaining ips..."
foreach r $readIps {
  puts $r
  # Create New IP Dir in Build and Copy
  set localReadIpDir [file join $ipBuildDir [file dirname $r]]
  file mkdir $localReadIpDir
  file copy [file join $readIpDir $r] [file join $ipBuildDir $r]
  read_ip [file join $ipBuildDir $r]
  set localReadIpObj [get_ips [file rootname [file tail $r]]]
  set localReadIpFilename [get_property "IP_FILE" $localReadIpObj]
  set localReadIpFile [get_files $localReadIpFilename]
  generate_target all $localReadIpObj -force
  # Synth IP
  synth_ip $localReadIpObj
}

# Read All Sources
set srcFilename [file join $projectDir "src.txt"]
set srcFile [open $srcFilename r]
set srcFileContents [read -nonewline $srcFile]
set srcs [split $srcFileContents "\n"]
close $srcFile
puts "Reading sources..."
foreach s $srcs {
  puts $s
  read_verilog [file join $srcDir $s]
}

# Read XDC File
set xdcFile [file join $srcDir [join [list $partName ".xdc"] ""]]
read_xdc $xdcFile

# Run Synthesis / Optimization / Place and Route
set topModule [lindex $argv 2]
synth_design -top $topModule -part $partName
opt_design
place_design
route_design
report_utilization -file $buildDir/utilization.rpt
report_timing -file $buildDir/timing.rpt
report_power -file $buildDir/power.rpt

# Write Checkpoint
write_checkpoint -force $buildDir/synth.dcp

# Write Bitstream
write_verilog -force $buildDir/synth.v
write_bitstream -force $buildDir/synth.bit
