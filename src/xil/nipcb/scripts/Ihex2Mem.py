import sys

HexCodes = {
	'0': 0,
	'1': 1,
	'2': 2,
	'3': 3,
	'4': 4,
	'5': 5,
	'6': 6,
	'7': 7,
	'8': 8,
	'9': 9,
	'A': 10,
	'B': 11,
	'C': 12,
	'D': 13,
	'E': 14,
	'F': 15
}

def Ihex2Mem (Filename, WordSize):
	Ihex = None
	with open (Filename + '.hex', 'r') as IhexFile:
		Ihex = IhexFile.readlines ()
	
	with open (Filename + '.mem', 'w') as MemFile:
		CurrentAddress = 0
		Total = 0
		for Line in Ihex:
			# Skip Header :
			Line = Line[1:]
			
			# Get Total Number Bytes in Data Line
			Count = HexCodes[Line[0]] * 16 + HexCodes[Line[1]]
			CharacterCount = Count * 2 # 1 Byte Equals 2 Hex Characters
			Line = Line[2:]
			
			# Get Address
			Address = HexCodes[Line[0]] * 4096 + HexCodes[Line[1]] * 256 + HexCodes[Line[2]] * 16 + HexCodes[Line[3]]
			Line = Line[4:]

			# Ensure This Is Data
			RecordCode = HexCodes[Line[1]]
			if RecordCode != 0:
				print ('Skipping Record Code %d\n' % (RecordCode)) 
				continue
			Line = Line[2:]
			
			#	"Seek" to Current Address in Mem File
			if Address != CurrentAddress:
				print ('Seeking Address %d to Address %d' % (CurrentAddress, Address))
				while CurrentAddress < Address:
					NumToAdd = WordSize
					if CurrentAddress + NumToAdd > Address:
						NumToAdd = Address - CurrentAddress
					MemFile.write (('00' * NumToAdd) + '\n')
					CurrentAddress = CurrentAddress + NumToAdd

			# Write Out Bytes Line by Line
			Temp = 0
			print ('Outputting %d Bytes Starting at Address %d' % (Count, Address))
			while Temp < CharacterCount:
				NumToGrab = WordSize * 2 # Total Hex Characters is NumBytes * 2
				if Temp + NumToGrab > CharacterCount:
					NumToGrab = CharacterCount - Temp
				NextWord = Line[Temp:Temp + NumToGrab]
				# Convert From Little Endian
				WordAsBytes = []
				for i in range (0, len (NextWord), 2):
					WordAsBytes.append (NextWord[i:i+2])
				LittleEndian = WordAsBytes[::-1]
				LittleEndianStr = ''.join (LittleEndian) 
				print (LittleEndianStr, end = '')
				MemFile.write (LittleEndianStr + '\n')
				Temp = Temp + NumToGrab
			CurrentAddress = Address + Count
			Total = Total + Count 
			print ('\n\n')

		MemFile.write ('\n')
		print (Total)
		print (int (Total / WordSize))

def main ():
	Filename = sys.argv[1]
	WordSize = int (sys.argv[2])
	Ihex2Mem (Filename, WordSize)

if __name__ == '__main__':
	main ()

