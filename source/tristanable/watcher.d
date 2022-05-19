module tristanable.watcher;

import std.socket : Socket, SocketSet;
import core.sync.mutex : Mutex;
import bmessage : receiveMessage;
import tristanable.queue : Queue;
import tristanable.queueitem : QueueItem;
import tristanable.manager : Manager;
import core.thread : Thread, Duration, dur;
import tristanable.encoding;
import tristanable.exceptions;

public final class Watcher : Thread
{
	/* The manager */
	private Manager manager;

	/* The socket to read from */
	private Socket endpoint;

	private bool running;


	private bool newSys;
	private SocketSet socketSetR, socketSetW, socketSetE;


    /**
    * Timeout for select()
    */
    private Duration timeOut;

	this(Manager manager, Socket endpoint, Duration timeOut = dur!("msecs")(100), bool newSys = false)
	{
		super(&run);
		this.manager = manager;
		this.endpoint = endpoint;

		/* If we are to use the new system then initialize the socket sets */
		if(this.newSys = newSys)
		{
			this.timeOut = timeOut;
			initSelect();
		}
	}

 	/**
    * Initializes the SocketSet which is needed for the use
    * of the select() method0
    */
    private void initSelect()
    {
        socketSetR = new SocketSet();
        socketSetW = new SocketSet();
        socketSetE = new SocketSet();
    }

	public void shutdown()
	{
		running=false;

		/* Close the socket, causing an error, breaking the event loop */
		endpoint.close();
		
	}

	private void run()
	{
		running = true;

		/* Continuously dequeue tristanable packets from socket */
		while(true)
		{
			/* Receive payload (tag+data) */
			byte[] receivedPayload;
			

			if(newSys)
			{
				/**
				* We want to check the readable status of the `endpoint` socket, we use
				* the `select()` function for this. However, after selecting it will need
				* to be re-added if you want to check again. Example, if you add it to
				* the `socketSetR` (the readable-socketset) then if we time out or it
				* is not readable from it will be removed from said set.
				*
				* Therefore we will need to add it back again for our next check (via
				* calling `select()`)
				*/
				socketSetR.add(endpoint);
				int status = Socket.select(socketSetR, null, null, timeOut);

				import std.stdio : writeln;

				/* If we timed out on the select() */
				if(status == 0)
				{
					/* Check if we need to exit */
					writeln("We got 0");

					continue;
				}
				/* Interrupt */
				else if (status == -1)
				{
					/* TODO: Not sure what we should do here */
					writeln("We got -1");

					import core.stdc.errno;
					writeln(errno);

					continue;
				}
				/* Either data is available or a network occurred */
				else
				{
					writeln("Info: ", endpoint.isAlive);
					writeln("info: ", endpoint.handle);

					writeln("We got ", status);
					

					/* If the socket is still connected */
					if(endpoint.isAlive())
					{
						/* If we have data */
						if(socketSetR.isSet(endpoint))
						{
							/* Do nothing (fall through) */
							writeln("We got ready socket");

							/* I don't want to do mulitple additions, so let's clear the socket read set */
							socketSetR.reset();
						}

						/* There is no else as the only socket set checked for IS read */
					}
					/* If the socket is not connected (network error) */
					else
					{
						/* TODO: Maybe handle? */
						writeln("We have socket error");
						
						// throw new TristanableException(manager, "Network error with endpoint socket");
						break;
					}
					
				}
			}

			/* Block for socket response */
			bool recvStatus = receiveMessage(endpoint, receivedPayload);

			/* If the receive was successful */
			if(recvStatus)
			{
				/* Decode the ttag-encoded message */
				DataMessage message = DataMessage.decode(receivedPayload);

				/* TODO: Remove isTag, improve later, oneshot */

				/* The matching queue (if any) */
				Queue queue = manager.getQueue(message.getTag());

				/* If the tag belongs to a queue */
				if(queue)
				{
					/* Add an item to this queue */
					queue.enqueue(new QueueItem(message.getData()));
				}
				/* If the tag is unknwon */
				else
				{
					/* TODO: Add to dropped queue? */

					/* Do nothing */
				}
			}
			/* If the receive failed */
			else
			{
				/* TODO: depending on `running`, different error */

				/* TODO: Stop everything */
				break;
			}
		
			/**
			* Like in `dequeue` we don't want the possibility
			* of racing back to the top of the loop and locking
			* the mutex again right before a thread switch,
			* so we make sure that a switch occurs to a different
			* thread
			*/
			Thread.getThis().yield();
		}

		/* Check if we had an error */
		if(running)
		{
			/* Unblock all current Queue operations and prevent future ones */
			manager.invalidate();

			/* TODO: Remove this */
			// throw new TristanableException(manager, "bformat socket error");
		}
		else
		{
			/* Actual shut down, do nothing */

			/* Unblock all current Queue operations and prevent future ones */
			manager.invalidate();
		}
	}
}