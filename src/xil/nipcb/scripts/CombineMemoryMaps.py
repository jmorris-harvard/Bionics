# Python Script to Combine and Remap MMI FIles Produced Using Vivado 
import sys
import xml.etree.ElementTree as ET

def AddAddressSpace (Base, New, Reformat = False, Begin = None, Size = None):
	AddressSpaceName = New.attrib['Name']

	if Base.tag != 'MemInfo':
		print ('Malformed Input')
		sys.exit (1)

	# Check Whether AddressSpace to be Added Already Exists
	Processor = Base.find ('Processor')
	for AddressSpace in Processor.findall ('AddressSpace'):
		if AddressSpace.attrib['Name'] == AddressSpaceName:
			print ('Address Space Already Exists')
			sys.exit (1)

	# Check New AddressSpace
	if New.tag != 'AddressSpace':
		print ('New Block is Not An AddressSpace')
		sys.exit (1)

	if Reformat:
		if Begin == None or Size == None:
			print ('Reformat Specified With Malformed Ranges')
			sys.exit (1)
		BeginInt = int (Begin, 16)
		SizeInt = int (Size, 16)
		EndInt = BeginInt + SizeInt - 1
		End = hex (EndInt)
		print ('Reformatting Address Space %s to [%s, %s] ([%s, %s])' % (AddressSpaceName, Begin, End, BeginInt, EndInt))

		New.attrib['Begin'] = str (BeginInt)
		New.attrib['End'] = str (EndInt)

		BusBlock = New.find ('BusBlock')
		for BitLane in BusBlock.findall ('BitLane'):
			AddressRange = BitLane.find ('AddressRange')
			AddressRange.attrib['Begin'] = str (BeginInt)
			AddressRange.attrib['End'] = str (int (BeginInt + (SizeInt / 4) - 1))

	# Add New AddressSpace
	Processor.append (New)
	return New

def main ():
	OutFileName = sys.argv[1]
	BaseFileName = sys.argv[2]
	NewFileName = sys.argv[3]

	Reformat = False
	Begin = None
	Size = None
	if len (sys.argv) > 4:
		Reformat = True
		Begin = sys.argv[4]
		Size = sys.argv[5]

	BaseFile = ET.parse (BaseFileName)
	NewFile = ET.parse (NewFileName)
	Base = BaseFile.getroot ()
	New = NewFile.getroot ().find ('./Processor/AddressSpace')

	print ('Adding Address Space %s to File %s' % (New.attrib['Name'], BaseFileName))
	Out = AddAddressSpace (Base, New, Reformat, Begin, Size)
	print ('Writing Out to', OutFileName)
	OutString = ET.tostring (Base, encoding = 'utf8').decode ('utf8')
	OutString = OutString.replace ('utf8', 'UTF-8')
	# print (OutString)
	with open (OutFileName, 'w') as OutFile:
		OutFile.write (OutString)

if __name__ == '__main__':
	main ()
