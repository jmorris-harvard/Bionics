import sys
from . import ok

class Device:
	def __init__(self, verbose=False):
		self.verbose = verbose
		return

	def __print(self, *obj, sep=' ', end='\n', file=sys.stdout, flush=False):
		if (self.verbose == True):
			print(*obj, sep=sep, end=end, file=file, flush=flush)

	def listDevices(self):
		return ok.FrontPanelDevices();

	def Initialize(self, serial=None):
		device = self.listDevices()
		if (device.GetCount() == 0):
			self.__print("No connected devices found!")
			return False
		
		if (serial == None):
			self.xem = device.Open() #Open the first device
		else:
			self.xem = device.Open(serial)

		if not self.xem:
			self.__print("Could not open the device!")
			return False
		
		return True

	def getInfo(self):
		# Get some general information about the device.
		self.devInfo = ok.okTDeviceInfo()
		if (self.xem.NoError != self.xem.GetDeviceInfo(self.devInfo)):
			print("Unable to retrieve device information.")
			return None
		
		return self.devInfo
	
	def setupClock(self):
		self.xem.LoadDefaultPLLConfiguration()

	def downloadFile(self, filename):
		# Download the configuration file.
		if (self.xem.NoError != self.xem.ConfigureFPGA(filename)):
			self.__print("Configuration failed.")
			return False
		return True

	def checkFrontPanel(self):
		# Check for FrontPanel support in the FPGA configuration.
		if (self.xem.IsFrontPanelEnabled() == False):
			self.__print("FrontPanel support is not available.")
			return False
		return True
	
	def pipeSize(self):
		if ~hasattr(self, 'devInfo'):
			self.getInfo();
		try:
			if (self.devInfo.deviceInterface == ok.OK_INTERFACE_USB2):
				return 2
			elif (self.devInfo.deviceInterface == ok.OK_INTERFACE_PCIE):
				return 8
			elif (self.devInfo.deviceInterface == ok.OK_INTERFACE_USB3):
				return 16
			else:
				return 2
		except:
			return 2
	
	def setWire(self, id, value, mask=0xffffffff):
		self.xem.SetWireInValue(id, value, mask)
		self.xem.UpdateWireIns()
	
	def getWire(self, id, mask=0xffffffff):
		self.xem.UpdateWireOuts()
		return self.xem.GetWireOutValue(id)
	
	def setTrigger(self, id, bit):
		self.xem.ActivateTriggerIn(id, bit)
	
	def checkTrigger(self, id, mask):
		self.xem.UpdateTriggerOuts()
		return self.xem.IsTriggered(id, mask)
	
	def writeBuffer(self, id, buffer):
		if (len(buffer) <= self.pipeSize()):
			extra = self.pipeSize() - len(buffer)
		else:
			extra = self.pipeSize () - (len(buffer) % self.pipeSize())
		buffer += bytearray(extra) #Make buffer multiple of data-width (in bytes)
		print (len(buffer))
		self.xem.WriteToPipeIn(id, buffer)
	
	def writeString(self, id, text):
		buffer = bytearray(text.encode("ascii"))
		self.writeBuffer(id, buffer)
	
	def readBuffer(self, id, length):
		if (length <= self.pipeSize()):
			extra = self.pipeSize() - length
		else:
			extra = self.pipeSize () - (length % self.pipeSize())
		buffer = bytearray(length + extra) #Make buffer multiple of data-width (in bytes)
		self.xem.ReadFromPipeOut(id, buffer)
		return buffer[0:length]
	
	def readString(self, id, length):
		buffer = self.readBuffer(id, length)
		return buffer.decode("ascii")
