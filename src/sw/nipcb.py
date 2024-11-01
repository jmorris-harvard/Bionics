#!/usr/bin/python3.8

import xem.xem as xem
import sys
import time

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
	buf += bytearray ([0x00])
	buf += bytearray ([0x00])
	buf += bytearray ([0x00])
	print (len(buf))
	return buf
	

def doWriteProgramMemory (dev, filename):
	dev.setWire (0x00, ConfigBits.IDLE)
	dev.setWire (0x00, ConfigBits.WRITE_PROG)
	dev.setWire (0x00, ConfigBits.WRITE_PROG | ConfigBits.PROGRAM)
	buf = memToByteArray (filename)
	dev.writeBuffer (0x80, buf)
	dev.setWire (0x00, ConfigBits.IDLE)

if __name__ == '__main__':
	dev = startUp ()
	print (dev.checkFrontPanel ())
	dev.setWire (0x00, 0x1)
	time.sleep (0.25)
	dev.setWire (0x00, 0x0)
	time.sleep (0.25)
	doWriteProgramMemory (dev, 'nipcb.mem')

