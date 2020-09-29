//module

public final class Watcher : Thread
{
	this()
	{
		
	}

	private void run()
	{
		/* Continuously dequeue tristanable packets from socket */
		while(true)
		{
			/* Receive payload (tag+data) */
			byte[] receivedPayload;
			
			/* Block for socket response */
			bool recvStatus = receiveMessage(endpoint, receivedPayload);

			/* If the receive was successful */
			if(recvStatus)
			{
				/* Decode the ttag-encoded message */
				DataMessage message = DataMessage.decode(receivedPayload);

				

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