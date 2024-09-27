#!/usr/bin/python

import os
import sys

# Usage:
#   python Ihex2Mem.py <File Basename> <Word Size>
#   ./Ihex2Mem.py <File Basename> <Word Size>
#
# Arguments:
#   Required:
#       File Basename - Filename without extension (assumes .hex extension)
#   Optional:
#       Word Size - Number bytes per word (defaults to 4)
#
# Example: Assuming data.hex exists and contains binary for 32-bit processor
#   python Ihex2Mem.py data 4

def serializeIhex (filename):
    ihex = None
    with open (filename, 'r') as ihexFile:
        ihex = ihexFile.readlines ()
    serialHex = ''
    currentAddress = 0
    total = 0
    for line in ihex:
        # Skip header : character
        # Seek one character
        line = line[1:]	
        # Get total number bytes in data line
        byteCount = int (line[:2], 16)
        characterCount = byteCount * 2 # One byte equals two hex characters
        # Seek two characters
        line = line[2:]
        # Get address covert hex to decimal
        address = int (line[:4], 16)
        line = line[4:]
        # Ensure this is data
        recordCode = line[1]
        if recordCode != '0':
        	continue
        line = line[2:]
        # "Seek" to current address
        if currentAddress != address:
            serialHex = serialHex + ('0' * (address - currentAddress))
            currentAddress = address
        for i in range (characterCount):
            serialHex = serialHex + line[i]
        currentAddress = currentAddress + byteCount
    return serialHex

def convertToMem (serialHex, outputFilename, wordSize = 4, endianness = 'little'):
    numBytes = int(len (serialHex) / 2)
    if numBytes % wordSize != 0:
        print ('Warning: Bytes does not match wordSize. Appending 0s to last word.')
    with open (outputFilename, 'w') as output:
        # Grab word and write to output
        charactersPerWord = wordSize * 2
        for i in range (0, len (serialHex), charactersPerWord):
            nextWord = serialHex[i:i+charactersPerWord]
            while len(nextWord) < charactersPerWord:
                nextWord = nextWord + '0'
            if endianness == 'little':
                byteList = []
                for i in range (0, len (nextWord), 2):
                    byteList.append (nextWord[i:i+2])
                nextWord = ''.join (byteList[::-1])
            elif endianness == 'big':
                pass
            else:
                print ('Error: Invalid endianness parameter')
                sys.exit (1)
            output.write (nextWord + '\n')
    print ('Total Bytes: ', numBytes)
    print ('Total Words: ', int (numBytes / wordSize + numBytes % wordSize))

def convertToCoe (serialHex, outputFilename, wordSize = 4, endianness = 'little'):
    numBytes = len (serialHex) / 2
    if numBytes % wordSize != 0:
        print ('Warning: Bytes does not match wordSize. Appending 0s to last word.')
    with open (outputFilename, 'w') as output:
        # Write header
        output.write ('memory_initialization_radix = 16;\n')
        output.write ('memory_initialization_vector =\n')
        # Write out all bytes
        charactersPerWord = wordSize * 2
        for i in range (0, len (serialHex), charactersPerWord):
            nextWord = serialHex[i:i+charactersPerWord]
            while len (nextWord) < charactersPerWord:
                nextWord = nextWord + '0'
            if endianness == 'little':
                byteList = []
                for i in range (0, len (nextWord), 2):
                    byteList.append (nextWord[i:i+2])
                nextWord = ''.join (byteList[::-1])
            elif endianness == 'big':
                pass
            else:
                print ('Error: Invalid endianness parameter')
                sys.exit (1)
            if i + charactersPerWord < len (serialHex):
                output.write (nextWord + ',\n')
            else:
                output.write (nextWord + '\n')


def main ():
    command = sys.argv[1]
    filename = sys.argv[2]
    wordSize = None
    if len (sys.argv) > 3:
        wordSize = int (sys.argv[3])
    else:
        wordSize = 4
    endianness = None
    if len (sys.argv) > 4:
        endianness = sys.argv[4]
    else:
        endianness = 'little'
    if command == 'mem':
        convertToMem (serializeIhex (filename), os.path.splitext (filename)[0] + '.mem', wordSize, endianness)
    elif command == 'coe':
        convertToCoe (serializeIhex (filename), os.path.splitext (filename)[0] + '.coe', wordSize, endianness)
    else:
        print ('Error: Invalid command given')
        sys.exit (1)

if __name__ == '__main__':
	main ()

