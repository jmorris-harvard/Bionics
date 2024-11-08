#!/usr/bin/python3.8

import argparse
import os
import re
import sys
import time
import xem.xem as xem

class ConfigBits:
	IDLE = 0x0
	RESET = 0x1
	PROGRAM = 0x2
	WRITE_PROG = 0x4

def startUp (filename = './nipcb.bit'):
	dev = xem.Device ()
	if not dev.Initialize ():
		print ('Could not connect to device')
		sys.exit (1)
	if not dev.downloadFile (filename):
		print ('Could not download bitstream')
		sys.exit (1)
	return dev

def doReadProgramMemory (dev, size):
	dev.setWire (0x00, ConfigBits.IDLE)
	dev.setWire (0x00, ConfigBits.PROGRAM)
	data = dev.readBuffer (0xA0, size)
	dev.setWire (0x00, ConfigBits.IDLE)
	return data

def memToByteArray (filename):
	data = None
	with open (filename) as mem:
		data = mem.read ().splitlines ()
	buf = None
	for word in data:
		by_byte = [word[i:i+2] for i in range (0,8,2)]
		reversed_by_byte = by_byte[::-1]
		byte_array = bytearray ([int(byte,16) for byte in reversed_by_byte])
		if buf == None:
			buf = byte_array
		else:
			buf += byte_array
	return buf

def recv (dev):
	filename = 'out.csv'
	rounds = 100
	length = 256 # read 256 samples at a time
	time.sleep (0.25)
	channels = [
		bytearray (0),
		bytearray (0),
		bytearray (0),
		bytearray (0)
	]
	try:
		while rounds:
			data = dev.readBuffer (0xa0, length)
			channels[0] += data[0::4]
			channels[1] += data[1::4]
			channels[2] += data[2::4]
			channels[3] += data[3::4]
			rounds = rounds - 1
	finally:
		with open (filename, 'w') as csv:
			for cdata in zip (*channels):
				row = ','.join ([str(int(c)) for c in cdata])
				csv.write (row + '\n')

def doWriteProgramMemory (dev, filename):
	dev.setWire (0x00, ConfigBits.IDLE)
	dev.setWire (0x00, ConfigBits.WRITE_PROG)
	dev.setWire (0x00, ConfigBits.WRITE_PROG | ConfigBits.PROGRAM)
	buf = memToByteArray (filename)
	dev.writeBuffer (0x80, buf)
	dev.setWire (0x00, ConfigBits.IDLE)

def main ():
	# get available programs
	pattern = r'\w+\.mem'
	files = os.listdir ('./mems')
	commands = [os.path.splitext (f)[0] for f in files if re.match (pattern, f)]
	callback_map = {}
	for command in commands:
		if command in globals () and callable (globals()[command]):
			callback_map[command] = globals()[command]
		else:
			callback_map[command] = None

	# parse arguments
	parser = argparse.ArgumentParser (
		prog = 'nipcb ctrl',
		description = 'nipcb ctrl',
		epilog = ''
	)
	parser.add_argument (
		'command',
		help = 'valid commands: ' + ' '.join (commands)
	)
	parser.add_argument (
		'-v',
		'--verbose',
		action = 'store_true',
		default = False)
	args = parser.parse_args ()
	if args.command not in commands:
		print ('invalid command given')
		sys.exit ()

	dev = startUp ()
	# reset
	dev.setWire (0x00, 0x1)
	time.sleep (0.25)
	dev.setWire (0x00, 0x0)
	time.sleep (0.25)

	# run command
	doWriteProgramMemory (dev, os.path.join ('mems/', args.command + '.mem'))
	if callback_map[args.command]:
		callback_map[args.command] (dev)

if __name__ == '__main__':
	main ()
