module tristanable.manager;

import std.socket : Socket;
import core.sync.mutex : Mutex;
import bmessage : bSendMessage = sendMessage;
import tristanable.queue : Queue;

public final class Manager
{
	/* All queues */
	private Queue[] queues;
	private Mutex queuesLock;
	
	/* TODO Add drop queue? */
	
	/**
    * The remote host
    */
    private Socket socket;



	/**
	* Constructs a new Manager with the given
	* endpoint Socket
	*
	*/
	this(Socket socket)
	{
		/* Set the socket */
		this.socket = socket;

		/* Initialize the queues mutex */
		queuesLock = new Mutex();

		/* Initialize the watcher */
	}

	public Queue getQueue(ulong tag)
	{
		Queue matchingQueue;

		queuesLock.lock();

		foreach(Queue queue; queues)
		{
			if(queue.getTag() == tag)
			{
				matchingQueue = queue;
				break;
			}
		}

		queuesLock.unlock();

		return matchingQueue;
	}

	public void addQueue(Queue queue)
	{
		queuesLock.lock();

		/* Make sure such a tag does not exist already */
		if(!isValidTag_callerThreadSafe(queue.getTag()))
		{
			queues ~= queue;
		}
		else
		{
			/* TODO: Throw an error here */
		}

		queuesLock.unlock();
	}

	private bool isValidTag_callerThreadSafe(ulong tag)
	{
		bool tagExists;

		
		foreach(Queue queue; queues)
		{
			if(queue.getTag() == tag)
			{
				tagExists = true;
				break;
			}
		}

		return tagExists;
	}

	public bool isValidTag(ulong tag)
	{
		/* Whether or not such a tagged queue exists */
		bool tagExists;

		
		queuesLock.lock();

		tagExists = isValidTag_callerThreadSafe(tag);

		queuesLock.unlock();

		return tagExists;
	}
	

	public void shutdown()
	{
		/* TODO: Implement me */
	}
}