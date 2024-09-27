#!/usr/bin/python3

import argparse
import pandas as pd
import sys 

def defineArguments ():
	parser = argparse.ArgumentParser (
			prog = 'editXDC',
			description = '',
			epilog = '')

	parser.add_argument ('signal')
	parser.add_argument ('pin')
	parser.add_argument ('-f','--xdc', default = 'xem7310.xdc', dest = 'xdc')
	parser.add_argument ('-c','--config', default = 'xem7310.csv', dest = 'config')

	args = parser.parse_args ()
	print ('Attaching %s to %s' % (args.signal, args.pin))
	return args

def main ():
	args = defineArguments ()
	signal = args.signal
	pin = args.pin
	configFile = args.config
	xdcFile = args.xdc

	config = pd.read_csv (configFile)
	pinData = config[config['FPGA Pin'] == pin]
	pinName = pinData['Connector'].values[0] + '-' + str(pinData['Pin'].values[0])
	ioStandard = pinData['XDC IOStandard'].values[0]
	print ('FPGA Pin:', pinData['FPGA Pin'].values[0])
	print ('Connector Name:', pinName)
	print ('I/O Bank:', int (pinData['I/O Bank'].values[0]))
	print ('I/O Standard:', ioStandard)

	inLines = None
	with open (xdcFile) as xdc:
		inLines = xdc.readlines ()

	outLines = []
	i = 0
	lineCount = len (inLines)
	while i < lineCount:
		if pinName in inLines[i]:
			outLines.append (inLines[i])
			i = i + 1
			outLines.append ('set_property PACKAGE_PIN %s [get_ports {%s}]\n' % (pin, signal))
			i = i + 1
			outLines.append ('set_property IOSTANDARD %s [get_ports {%s}]\n' % (ioStandard, signal))

		else:
			outLines.append (inLines[i])
		i = i + 1

	with open (xdcFile, 'w') as xdc:
		xdc.writelines (outLines)

if __name__ == '__main__':
	main ()
