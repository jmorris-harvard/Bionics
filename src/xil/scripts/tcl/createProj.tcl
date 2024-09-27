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
set xilProjectDir [file join $projectDir "xil_$projectName"]
file mkdir $buildDir
file mkdir $ipBuildDir

# Create Project
set partName [lindex $argv 1]
set boardName [lindex $argv 2]
create_project -force $projectName $xilProjectDir -part $partName

# Add Sources
set srcFilename [file join $projectDir "src.txt"]
set srcFile [open $srcFilename "r"]
set srcFileContents [read -nonewline $srcFile]
set srcs [split $srcFileContents "\n"]
close $srcFile
puts "Reading sources..."
foreach s $srcs {
  puts $s
  add_files [file join $srcDir $s]
}

# Read generated IP
set genFilename [file join $ipBuildDir "gen.txt"]
set genFile [open $genFilename "r"]
set genFileContents [read -nonewline $genFile]
set ips [split $genFileContents "\n"]
foreach i $ips {
  puts $i
  add_files $i
}

# XDC
set xdcFile [file join $srcDir [join [list $partName ".xdc"] ""]]
add_files -fileset constrs_1 $xdcFile

# Copy Src and IP Files into Project
import_files -force

# Start GUI with Project
start_gui
