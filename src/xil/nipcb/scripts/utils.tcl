proc UTILS_readIPConfig {configFilename} {
  puts "Reading $configFilename..."
  set configFile [open $configFilename r]
  set configFileContents [read -nonewline $configFile]
  set configData [split $configFileContents "\n"]
  set configDict [dict create]
  set infoDict [dict create]
  set propertiesDict [dict create]
  foreach c $configData {
    set keyValuePair [split $c " "]
    set key [lindex $keyValuePair 0]
    set value [lindex $keyValuePair 1]
    if {[string match $key "vlnv"] || [string match $key "name"]} {
      dict set infoDict $key $value
    } else {
      dict set propertiesDict "CONFIG.$key" $value
    }
  }
  puts "Info Dictionary:"
  dict for {key value} $infoDict {
    puts "$key $value"
  }
  puts "Properties Dictionary:"
  dict for {key value} $propertiesDict {
    puts "$key $value"
  }
  dict set configDict "info" $infoDict
  dict set configDict "properties" $propertiesDict
  close $configFile
  return $configDict
}
