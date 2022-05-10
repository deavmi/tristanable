module tristanable.watcher;

import tristanable.manager : Manager;
import tristanable.request : Request;
import std.socket : Socket, SocketSet;
import core.thread : Thread, dur, Duration;
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

    /**
    * Timeout for select()
    */
    private Duration timeOut;

    this(Manager manager, Socket endpoint, Duration timeOut = dur!("msecs")(100))
    {
        super(&watchLoop);
        this.manager = manager;
        this.endpoint = endpoint;
        this.timeOut = timeOut;
        
        initSelect();
        
        isActive = true;
    }

    public void stopWatcher()
    {
        isActive = false;
    }

    private SocketSet socketSetR, socketSetW, socketSetE;

    /**
    * Initializes the SocketSet which is needed for the use
    * of the select() method0
    */
    private void initSelect()
    {
        /* We acre about `endpoint` status changes */
        socketSetR = new SocketSet();
       

        socketSetW = new SocketSet();
        socketSetE = new SocketSet();
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

            /* We want to check if `endpoint` can be read from */
            socketSetR.add(endpoint);

            /* Check if the endpoint has any data available */
            int status = Socket.select(socketSetR, socketSetW, socketSetE, timeOut);

            /* If we timed out on the select() */
            if(status == 0)
            {
                /* Check if we need to exit */
                continue;
            }
            /* Interrupt */
            else if (status == -1)
            {
                /* TODO: Not sure what we should do here */

            }
            /* Either data is available or a network occurred */
            else
            {
                /* If we have data */
                if(socketSetR.isSet(endpoint))
                {
                    /* Do nothing (fall through) */

                }
                /* We have an error */
                else
                {
                    /* TODO: Handle this */
                }
            }

            /* Receive a message */
            bool recvStatus = receiveMessage(endpoint, receivedPayload);

            /* If there was some reading error */
            if(!recvStatus)
            {
                /* TODO: Either we work with signals (preferred) or select and blocking */
                /**
                * I am thinking we can peek, and see if we have a potential message header (bmessage)
                * Under that condition do some sort of blocking wait (in bmessage)
                */
            }

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

            

            if(foundTag)
            {
                

                /* Fulfill the request */
                currentQueue[requestPosition].fulfill(receivedMessage);

                
            }
            else
            {

            }

            /* Unlock the queue */
            manager.unlockQueue();
        }
    }
}