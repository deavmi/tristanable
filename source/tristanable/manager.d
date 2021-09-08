module tristanable.manager;

import std.socket : Socket;
import core.sync.mutex : Mutex;
import bmessage : bSendMessage = sendMessage;
import tristanable.queue : Queue;
import tristanable.watcher;
import std.container.dlist;

public final class Manager
{
	/* All queues */
	private DList!(Queue) queues;
	private Mutex queuesLock;
	
	/* TODO Add drop queue? */
	
	/**
    * The remote host
    */
    private Socket socket;


	private Watcher watcher;


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
		watcher = new Watcher(this, socket);

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

	/* TODO: Probably remove this or keep it */
	public bool isValidTag(ulong tag)
	{
		return !(getQueue(tag) is null);
	}

	/**
	* Returns a new queue with a new ID,
	* if all IDs are used then it returns
	* null
	*
	* Use this if you don't care about reserving
	* queues IDs and just want a throwaway queue
	*
	* FIXME: All tags in use, this won't handle it
	*/
	public Queue generateQueue()
	{
		/* Newly generated queue */
		Queue newQueue;

		queuesLock.lock();

		ulong curGuess = 0;
		bool bad = true;
		reguess: while(bad)
		{
			foreach(Queue queue; queues)
			{
				if(queue.getTag() == curGuess)
				{
					curGuess++;
					continue reguess;
				}
			}

			bad = false;
		}
		
		/* Create the new queue with the free id found */
		newQueue = new Queue(curGuess);

		/* Add the queue (recursive mutex) */
		addQueue(newQueue);

		queuesLock.unlock();


		return newQueue;
	}

	public void addQueue(Queue queue)
	{
		queuesLock.lock();

		/* Make sure such a tag does not exist already */
		if(!isValidTag(queue.getTag()))
		{
			queues ~= queue;
		}
		else
		{
			/* TODO: Throw an error here */
		}

		queuesLock.unlock();
	}

	/**
	* TODO: Comment
	* TODO: Testing
	*/
	public void shutdown()
	{
		/* TODO: Implement me */

		/* Make the loop stop whenever it does */
		watcher.shutdown();

		/* Wait for the thread to end */
		watcher.join();
	}
}