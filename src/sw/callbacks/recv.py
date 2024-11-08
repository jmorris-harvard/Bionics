#!/usr/bin/python3.8

import time

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

