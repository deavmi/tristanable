/**
* Queue
*
* Represents a queue with a tag.
*
* Any messages that are received with
* the matching tag (to this queue) are
* then enqueued to this queue
*/

module tristanable.queue;

import tristanable.queueitem : QueueItem;
import std.socket : Socket;
import core.sync.mutex : Mutex;
import bmessage : bSendMessage = sendMessage;
import core.thread : Thread;
import std.container.dlist;
import std.range : walkLength;

public enum QueuePolicy : ubyte
{
	LENGTH_CAP = 1
}

public final class Queue
{
	/* This queue's tag */
	private ulong tag;

	/* The queue */
	private DList!(QueueItem) queue;

	/* The queue mutex */
	private Mutex queueLock;

	/**
	* Construct a new queue with the given
	* tag
	*/
	this(ulong tag, QueuePolicy flags = cast(QueuePolicy)0)
	{
		this.tag = tag;

		/* Initialize the mutex */
		queueLock = new Mutex();
	}

	public void setLengthCap(ulong lengthCap)
	{
		this.lengthCap = lengthCap;
	}

	public ulong getLengthCap(ulong lengthCap)
	{
		return lengthCap;
	}

	/**
	* Queue policy settings
	*/
	private ulong lengthCap = 1;
	private QueuePolicy flags;
	

	public void enqueue(QueueItem item)
	{
		/* Lock the queue */
		queueLock.lock();

		/**
		* Check to see if the queue has a length cap
		*
		* If so then determine whether to drop or
		* keep dependent on current capacity
		*/
		if(flags & QueuePolicy.LENGTH_CAP)
		{
			if(walkLength(queue[]) == lengthCap)
			{
				goto unlock;
			}
		}

		/* Add it to the queue */
		queue ~= item;

		unlock:

		/* Unlock the queue */
		queueLock.unlock();
	}

	/**
	* Returns true if this queue has items ready
	* to be dequeued, false otherwise
	*/
	public bool poll()
	{
		/* Status */
		bool status;

		/* Lock the queue */
		queueLock.lock();

		status = !queue.empty();

		/* Unlock the queue */
		queueLock.unlock();

		return status;
	}

	/**
	* Attempts to coninuously dequeue the
	* head of the queue
	*
	* TODO: Add a timeout capability
	* TODO: Add tryLock, yield on failure (with loop for recheck ofc)
	* TODO: Possible multiple dequeue feature? Like .receive
	*/
	public QueueItem dequeue()
	{
		/* The head of the queue */
		QueueItem queueHead;

		while(!queueHead)
		{
			/* Lock the queue */
			queueLock.lock();

			/* Check if we can dequeue anything */
			if(!queue.empty())
			{
				/* If we can then dequeue */
				queueHead = queue.front();
				queue.removeFront();

				/* Chop off the head */
				// offWithTheHead();
			}

			/* Unlock the queue */
			queueLock.unlock();


			/**
			* Move away from this thread, let
			* the watcher (presumably) try
			* access our queue (successfully)
			* by getting a lock on it
			*
			* Prevents us possibly racing back
			* and locking queue again hence
			* starving the system
			*/
			Thread.getThis().yield();	
		}
		
		return queueHead;
	}

	/**
	* Returns the tag for this queue
	*/
	public ulong getTag()
	{
		return tag;
	}
}