using PortMidi, Sockets, OpenSoundControl
using Base.Threads

# Initialize PortMidi
PortMidi.Pm_Initialize()

# Get info about devices
for i in 0:PortMidi.Pm_CountDevices()-1
	info = unsafe_load(PortMidi.Pm_GetDeviceInfo(i))
	println(i, ": ", info.output > 0 ? "[Output ] " : "[Input] ", unsafe_string(info.name), " (", unsafe_string(info.interf), ")")
end

# Define the ID of your MIDI device (replace with your device ID)
device_id = 0

# Open the MIDI device as an input
stream = Ref{Ptr{PortMidi.PortMidiStream}}(C_NULL)
begin
	m_err = PortMidi.Pm_OpenInput(stream, device_id, C_NULL, 1024, C_NULL, C_NULL)
	if m_err != PortMidi.pmNoError
		error(unsafe_string(PortMidi.Pm_GetErrorText(m_err)))
	end
end

# Define the CC number for your slider (replace with your slider CC number)
slider_cc1 = 0x4a
slider_cc2 = 0x47

# Read MIDI messages
events = Vector{PortMidi.PmEvent}(undef, 2)
last_value1 = 0
last_value2 = 0
current_value1 = 0
current_value2 = 0

poll = true
@spawn :interactive while poll  # Loop forever
	global last_value1
	global last_value2
	global current_value1
	global current_value2

	if PortMidi.Pm_Poll(stream[]) == PortMidi.pmGotData
		err = PortMidi.Pm_Read(stream[], events, 1)
        	if err >= 1
        		msg = events[1].message

			if PortMidi.Pm_MessageStatus(msg) == 0xB0 && (PortMidi.Pm_MessageData1(msg) == slider_cc1 || PortMidi.Pm_MessageData1(msg) == slider_cc2)
				if PortMidi.Pm_MessageData1(msg) == slider_cc1
					current_value1 = PortMidi.Pm_MessageData2(msg)
				elseif PortMidi.Pm_MessageData1(msg) == slider_cc2
					current_value2 = PortMidi.Pm_MessageData2(msg)
				end

				if current_value1 != last_value1 || current_value2 != last_value2
					println("Slider 1 value: ", current_value1)
					println("Slider 2 value: ", current_value2)

				#	sock1 = UDPSocket()
				#	msg1 = OpenSoundControl.message("/slider", "ii", Int32(current_value1), Int32(current_value2))

				#	send(sock1, ip"127.0.0.1", 7777, msg1.data)
				#	println(msg1)

					last_value1 = current_value1
					last_value2 = current_value2
				end
			end
		end
	end
	# Sleep for a short time to avoid hogging the CPU
	PortMidi.Pt_Sleep(1)
end
poll = false

println("...")

# Don't forget to close the MIDI device when you're done
PortMidi.Pm_Close(stream[])
PortMidi.Pm_Terminate()