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
create_project -in_memory
set_part $partName

# Create list to write out gen output
set outputs {}

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
  # Customize IP
  set localSynthIpObj [get_ips $moduleName]
  set localSynthIpFilename [get_property "IP_FILE" $localSynthIpObj]
  set localSynthIpFile [get_files $localSynthIpFilename]
  if {[llength $propertiesDict]} {
    set_property -dict $propertiesDict $localSynthIpObj
  }
  # Print Properties To File
  set propertiesFilename [file join $localSynthIpDir "$moduleName.prop"]
  set propertiesFile [open $propertiesFilename "w"]
  set propertyKeys [list_property $localSynthIpObj]
  foreach pKey $propertyKeys {
    set pVal [get_property $pKey $localSynthIpObj] 
    puts $propertiesFile "$pKey $pVal"
  }
  close $propertiesFile
  generate_target {instantiation_template} $localSynthIpObj -force 
  
  lappend outputs [file join $localSynthIpDir "$moduleName.xci"]
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
  set localReadIpOutputDir [get_property "IP_OUTPUT_DIR" $localReadIpObj]
  set localReadIpSharedDir [get_property "IP_SHARED_DIR" $localReadIpObj]
  set localReadIpFile [get_files $localReadIpFilename]
  # Print Properties To File
  set propertiesFilename [file join $localReadIpDir "$moduleName.prop"]
  set propertiesFile [open $propertiesFilename "w"]
  set propertyKeys [list_property $localReadIpObj]
  foreach pKey $propertyKeys {
    set pVal [get_property $pKey $localReadIpObj] 
    puts $propertiesFile "$pKey $pVal"
  }
  close $propertiesFile
  generate_target {instantiation_template} $localReadIpFile -force

  lappend outputs [file join $ipBuildDir $r]
}

# Write out contents
set genFilename [file join $ipBuildDir "gen.txt"]
set genFile [open $genFilename "w"]
foreach o $outputs {
  puts $genFile $o
}
close $genFile
