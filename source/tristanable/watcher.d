module tristanable.watcher;

import std.socket : Socket;
import core.sync.mutex : Mutex;
import bmessage : receiveMessage;
import tristanable.queue : Queue;
import tristanable.queueitem : QueueItem;
import tristanable.manager : Manager;
import core.thread : Thread;
import tristanable.encoding;

public final class Watcher : Thread
{
	/* The manager */
	private Manager manager;

	/* The socket to read from */
	private Socket socket;

	this(Manager manager, Socket endpoint)
	{
		super(&run);
		this.manager = manager;
		socket = endpoint;
	}

	private void run()
	{
		/* Continuously dequeue tristanable packets from socket */
		while(true)
		{
			/* Receive payload (tag+data) */
			byte[] receivedPayload;
			
			/* Block for socket response */
			bool recvStatus = receiveMessage(socket, receivedPayload);

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
	}
}