import std.stdio;
import std.socket;
import tristanable.encoding : DataMessage;
import bmessage;
import core.thread;

void main()
{
	writeln("Edit source/app.d to start your project.");
	Socket socket = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
	socket.bind(parseAddress("127.0.0.1",7777));
	socket.listen(1);
	
	Socket conn = socket.accept();
	byte[] receivedData;

	while(true)
	{
		receiveMessage(conn, receivedData);

		DataMessage message = DataMessage.decode(receivedData);

		writeln("Tag: ", message.tag);
		writeln("Data: ", message.data);

		DataMessage d = new DataMessage(70, [2]);
		sendMessage(conn, d.encode());

		d = new DataMessage(69, [1]);
		Thread.sleep(dur!("seconds")(5));
		sendMessage(conn, d.encode());
	}
	
	

	
}
