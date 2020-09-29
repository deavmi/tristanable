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

public final class Queue
{
	/* This queue's tag */
	private ulong tag;

	/* The queue */
	private QueueItem[] queue;

	/* The queue mutex */
	private Mutex queueLock;

	/**
	* Construct a new queue with the given
	* tag
	*/
	this(ulong tag)
	{
		this.tag = tag;

		/* Initialize the mutex */
		queueLock = new Mutex();
	}

	public void enqueue(QueueItem item)
	{
		/* Lock the queue */
		queueLock.lock();

		/* Add it to the queue */
		queue ~= item;

		/* Unlock the queue */
		queueLock.unlock();
	}

	/**
	* Attempts to coninuously dequeue the
	* head of the queue
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
			if(queue.length)
			{
				/* If we can then dequeue */
				queueHead = queue[0];

				/* Chop off the head */
				offWithTheHead();
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
	* Shifts the list and regenerates it to remove
	* the current head
	*
	* Not thread safe but only called by thread
	* safe (mutex locking) method
	*/
	private void offWithTheHead()
	{
		/* The new queue */
		QueueItem[] newQueue;

		/* Add everything but the first */
		for(ulong i = 1; i < queue.length; i++)
		{
			newQueue ~= queue[i];
		}

		/* Make the the new queue */
		queue = newQueue;
	}

	/**
	* Returns the tag for this queue
	*/
	public ulong getTag()
	{
		return tag;
	}
}