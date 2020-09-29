public final class Manager
{
	/* All queues */
	private Queue[] queues;
	private Mutex queuesLock;
	
	/* TODO Add drop queue? */
	
	this()
	{
		
	}


	public void addQueue()
	{
		
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
	
}