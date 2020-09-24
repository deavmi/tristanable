module tristanable.watcher;

import tristanable.manager : Manager;
import tristanable.request : Request;
import tristanable.notifications : NotificationReply;
import std.socket : Socket;
import core.thread : Thread;
import bmessage : receiveMessage;

/* TODO: Watcher class to watch for stuff, and add to manager's queues */
/* TODO: maneger class to use commands on, enqueue and wait for dequeue */
public final class Watcher : Thread
{
    /**
    * The associated Manager
    *
    * Used to access the queues.
    */
    private Manager manager;

    /**
    * The endpoint host we are connected to
    */
    private Socket endpoint;

    /**
    * Whether or not the watcher is active
    */
    private bool isActive;

    this(Manager manager, Socket endpoint)
    {
        super(&watchLoop);
        this.manager = manager;
        this.endpoint = endpoint;
        isActive = true;
    }

    public void stopWatcher()
    {
        isActive = false;
    }

    private void watchLoop()
    {
        while(isActive)
        {
            /* The received message (tag+data) */
            byte[] receivedPayload;

            /* The message's tag */
            ulong receivedTag;

            /* The message's data */
            byte[] receivedMessage;


            /* Receive a message */
            bool recvStatus = receiveMessage(endpoint, receivedPayload);

            /* TODO: Status check */

            /* Fetch the `tag` */
            receivedTag = *(cast(ulong*)receivedPayload.ptr);

            /* Fetch the `data` */
            receivedMessage = receivedPayload[8..receivedPayload.length];

            /* Lock the queue for reading */
            manager.lockQueue();

            /* Get the queue */
            Request[] currentQueue = manager.getQueue();

            /* Check to see if this is a tag we are awaiting */
            bool foundTag = manager.isValidTag(receivedTag);
            ulong requestPosition = manager.getTagPosition(receivedTag);

            
			/**
			* Check if the tag was found
			*
			* This only accounts for tags requested
			*/
            if(foundTag)
            {
                /* Fulfill the request */
                currentQueue[requestPosition].fulfill(receivedMessage);
            }
            /**
            * Check if the tag was reservd
            */
            else if(manager.isReservedTag(receivedTag))
            {
            	/* Lock the notification queue */
            	manager.lockNotificationQueue();

				/* Create the NotificationReply */
				NotificationReply notifyReply = new NotificationReply(receivedTag, receivedMessage);

            	/* Unlock the notification queue */
            	manager.unlockNotificationQueue();
            }
            else
            {
				/* TODO: */
            }

            /* Unlock the queue */
            manager.unlockQueue();
        }
    }
}