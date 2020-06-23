import std.stdio;
import tristanable.manager : Manager;
import std.socket;

void main()
{
	writeln("Edit source/app.d to start your project.");
	Socket socket = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
	socket.connect(parseAddress("127.0.0.1",7777));
	Manager manager = new Manager(socket);

	manager.sendMessage(69, [77]);
	manager.sendMessage(70, [78]);


	byte[] receivedKaka = manager.receiveMessage(69);
	writeln(receivedKaka);

	receivedKaka = manager.receiveMessage(70);
	writeln(receivedKaka);

	receivedKaka = manager.receiveMessage(70);
	writeln(receivedKaka);

	

	
}
