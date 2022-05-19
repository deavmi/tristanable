module tristanable.manager;

import std.socket : Socket;
import core.sync.mutex : Mutex;
import bmessage : bSendMessage = sendMessage;
import tristanable.queue : Queue;
import core.thread : Thread, Duration, dur;
import tristanable.watcher;
import std.container.dlist;
import tristanable.exceptions;

/**
* Manager
*
* This is the core class that is to be instantiated
* that represents an instance of the tristanable
* framework. It is passed a Socket from which it
* reads from (using a bformat block reader).
*
* It contains a Watcher which does the reading and
* appending to respective queues (the user need not
* worry about this factum).
*
* The functions provided allow users to wait in a
* tight loop to dequeue ("receive" in a blcoking mannger)
* from a specified queue.
*/
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
	private bool isAlive;


	/**
	* Constructs a new Manager with the given
	* endpoint Socket
	*
	*/
	this(Socket socket, Duration timeOut = dur!("msecs")(100), bool newSys = false)
	{
		/* TODO: Make sure the socket is in STREAM mode */
		
		/* Set the socket */
		this.socket = socket;

		/* Initialize the queues mutex */
		queuesLock = new Mutex();

		/* Initialize the watcher */
		watcher = new Watcher(this, socket, timeOut, newSys);
	}

	/**
	* Starts the session (watcher)
	*/
	public void start()
	{
		/* Set this session as alive */
		this.isAlive = true;

		/* Start the watcher */
		watcher.start();
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
			if(isValidTag(curGuess))
			{
				curGuess++;
				continue reguess;
			}

			bad = false;
		}
		
		/* Create the new queue with the free id found */
		newQueue = new Queue(this, curGuess);

		/* Add the queue (recursive mutex) */
		addQueue(newQueue);

		queuesLock.unlock();


		return newQueue;
	}

	public Queue[] getQueues()
	{
		Queue[] queues;
		queuesLock.lock();

		foreach(Queue queue; this.queues)
		{
			queues ~= queue;
		}

		queuesLock.unlock();

		return queues;
	}

	/**
	* Removes the given Queue, `queue`, from the manager
	*
	* Throws a TristanableException if the id of the
	* queue wanting to be removed is not in use by any
	* queue already added
	*/
	public void removeQueue(Queue queue)
	{
		queuesLock.lock();

		/* Make sure such a tag exists */
		if(isValidTag(queue.getTag()))
		{
			queues.linearRemoveElement(queue);
		}
		else
		{
			/* Unlock queue before throwing an exception */
			queuesLock.unlock();
			throw new TristanableException(this, "Cannot remove a queue with an id not in use");
		}

		queuesLock.unlock();
	}

	/**
	* Adds the given Queue, `queue`, to the manager
	*
	* Throws a TristanableException if the id of the
	* queue wanting to be added is already in use by
	* another already added queue
	*/
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
			/* Unlock queue before throwing an exception */
			queuesLock.unlock();
			throw new TristanableException(this, "Cannot add queue with id already in use");
		}

		queuesLock.unlock();
	}

	public Socket getSocket()
	{
		return socket;
	}

	/** 
	 * Called by the Watcher thread when there is a socket
	 * error such that the `isValid` status field that
	 * the Queue operations check can be checked to see
	 * if the Queue calls should unblock due to a dead
	 * socket

	 * FIXME: End user should not be able to call this
	 */
	void invalidate()
	{
		isAlive = false;
	}

	bool isInvalid()
	{
		return !isAlive;
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