import std.stdio;
import std.socket;

void main()
{
	writeln("Edit source/app.d to start your project.");
	Socket socket = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
	socket.bind(parseAddress("127.0.0.1",7777));
	socket.listen(1);
	while(true)
	{
		socket.accept();
	}
}
