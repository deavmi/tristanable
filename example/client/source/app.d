import std.stdio;
import tristanable.manager : Manager;
import std.socket;
import core.thread;

void main()
{
	writeln("Edit source/app.d to start your project.");
	Socket socket = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
	socket.connect(parseAddress("127.0.0.1",7777));
	Manager manager = new Manager(socket);

	class bruh : Thread
	{
		this()
		{
			super(&run);
		}

		private void run()
		{
			while(true)
			{
				manager.lockQueue();
				writeln(manager.getQueue());
				manager.unlockQueue();
				import core.thread;

				Thread.sleep(dur!("seconds")(1));
			}
		}
	}

	new bruh().start();

	manager.sendMessage(69, [77]);
	manager.sendMessage(70, [78]);


	byte[] receivedKaka = manager.receiveMessage(69);
	writeln(receivedKaka);

	receivedKaka = manager.receiveMessage(70);
	writeln(receivedKaka);

	manager.sendMessage(70, [78]);

	receivedKaka = manager.receiveMessage(70);
	writeln(receivedKaka);


	

	
	
	

	
}
