#!/usr/bin/python3.8

import sw_xem_library as sw
import time

def startUp (filename = './synth.bit'):
	dev = sw.Device ()
	dev.Initialize ()
	dev.downloadFile (filename)
	return dev

def test_dac_1 ():
	# reset
	dev.setWire (0x00, 0x1)
	time.sleep (0.25)
	dev.setWire (0x00, 0x0)
	# leds
	dev.setWire (0x05, 0x3)
	# test dac 1
	input ('Start DAC Test?')
	while 1:
		# write to dac value register
		dev.setWire (0x02, 0x55)
		# trigger output
		dev.setTrigger (0x41, 0x0)
		# redo?
		resp = input ('Again (Y or N)?')
		if resp.upper () == 'N':
			break
		else:
			pass
	# test config 1
	input ('Start Config Test')
	dev.setWire (0x04, 0x010101)
	# test adc 1
	input ('Start ADC Test?')
	while 1:
		# trigger read
		dev.setTrigger (0x41, 0x1)
		# read value
		print ('Got value:', dev.getWire (0x21) & 0x3FFF)
		# redo?
		resp = input ('Again (Y or N)?')
		if resp.upper () == 'N':
			break
		else:
			pass

def adc_test_1 ():
	# reset
	dev.setWire (0x00, 0x1)
	time.sleep (0.25)
	dev.setWire (0x00, 0x0)
	# leds
	dev.setWire (0x05, 0x3)
	# trigger read
	dev.setTrigger (0x40, 0x2) 
	# read value


if __name__ == '__main__':
	dev = startUp ()
	print (dev.checkFrontPanel ())


