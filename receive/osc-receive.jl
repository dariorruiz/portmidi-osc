using Sockets, OpenSoundControl

sock2 = UDPSocket()
bind(sock2, ip"127.0.0.1", 7777)

while true
	try
		msg2 = OscMsg(recv(sock2))
		#show(msg2)
		if length(msg2.data) >= 16
			println(msg2.data[16])
			println(msg2.data[20])
		end
	catch e
		println("Error: ", e)
	end
end
