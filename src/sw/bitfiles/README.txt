copy bitfile to ../nipcb.bit that is used directly by the nipcb script

bitfile details + memory map
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
name:							synth_11-07
module contents:	oklib
									cortex-m0
module details:
	oklib:
		- PURPOSE		ADDR		NAME			DESC
			wire in		0x00		ctrl			bit 0: reset (active high)
																	bit 1: enable program mem access
																	bit 2: write program mem
			wire out	0x20		<none>		<none>
			pipe in		0x80		prog			program mem buffer when reprogramming cortex-m0
			pipe out	0xa0		adc 0			adc 0 data output
			pipe out	0xa1		adc 1			adc 1 data output	

	cortex-m0:
		- memory map
			MODULE		ADDR				SIZE				DESC
			flash			0x00000000	0x00002000	program mem
			sram			0x20000000	0x00002000	data mem
			nipcb-0		0x40000000	0x00001000	nipcb 0 ctrl
				-				0x40000000		-						nipcb triggers
																					bit 0: start stimulation
																					bit 1: start recording
																					bit 2: clear recording fifo
				-				0x40000004		-						nipcb flags
																					bit 0: stimulation running
																					bit 1: recording running
				-				0x40000008		-						<none>
				-				0x4000000C		-						stimulation channel select (channel number encoded)
				-				0x40000010		-						stimulation cycles high
				-				0x40000014		-						stimulation cycles low
				-				0x40000018		-						stimulation cycles delay
				-				0x4000001C		-						stimulation cycles stall
				-				0x40000020		-						stimulation cycles count
				-				0x40000024		-						stimulation magnitude high
				-				0x40000028		-						stimulation magnitude low
				-				0x4000002C		-						recording channels select (bit select encoded)
				-				0x40000030		-						recording cycles stall
				-				0x40000034		-						recording pga gain set
			led				0x40001000	0x00001000	led control (8 - bit)
			nipcb-1		0x40002000	0x00001000	nipcb 1 ctrl
				-				0x40002000		-						nipcb triggers
																					bit 0: start stimulation
																					bit 1: start recording
																					bit 2: clear recording fifo
				-				0x40002004		-						nipcb flags
																					bit 0: stimulation running
																					bit 1: recording running
				-				0x40002008		-						<none>
				-				0x4000200C		-						stimulation channel select (channel number encoded)
				-				0x40002010		-						stimulation cycles high
				-				0x40002014		-						stimulation cycles low
				-				0x40002018		-						stimulation cycles delay
				-				0x4000201C		-						stimulation cycles stall
				-				0x40002020		-						stimulation cycles count
				-				0x40002024		-						stimulation magnitude high
				-				0x40002028		-						stimulation magnitude low
				-				0x4000202C		-						recording channels select (bit select encoded)
				-				0x40002030		-						recording cycles stall
				-				0x40002034		-						recording pga gain set
