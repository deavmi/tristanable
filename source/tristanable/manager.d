module tristanable.manager;

import tristanable.watcher : Watcher;
import tristanable.request : Request;
import tristanable.garbage : GarbageCollector;
import tristanable.encoding : DataMessage;
import std.socket : Socket;
import core.sync.mutex : Mutex;
import bmessage : bSendMessage = sendMessage;

/* TODO: Watcher class to watch for stuff, and add to manager's queues */
/* TODO: maneger class to use commands on, enqueue and wait for dequeue */
public final class Manager
{
    /* TODO: Insert queues here */

    /**
    * The queue of outstanding requests
    */
    private Request[] requestQueue;

    /**
    * The associated Watcher object for this manager.
    */
    private Watcher watcher;

    /**
    * The list mutex
    */
    private Mutex queueMutex;

    /**
    * The remote host
    */
    private Socket socket;

    /**
    * The garbage collector
    */
    private GarbageCollector gc;

    this(Socket endpoint)
    {
        /* Set the socket */
        socket = endpoint;

        /* Create the watcher */
        watcher = new Watcher(this, endpoint);

        /* Create the garbage collector */
        gc = new GarbageCollector(this);

        /* Initialize the `requestQueue` mutex */
        queueMutex = new Mutex();

        /* Start the watcher */
        watcher.start();

        /* Start the garbage collector */
        gc.start();
    }

    public void sendMessage(ulong tag, byte[] data)
    {
        /* Encode the message */
        DataMessage dataMessage = new DataMessage(tag, data);

        /* Construct the message array */
        byte[] messageData = dataMessage.encode();

        /* Send the message */
        bSendMessage(socket, messageData);

        /* Create a new Request */
        Request newRequest = new Request(tag);

        /* Lock the queue for reading */
        lockQueue();

        /* Add the request to the request queue */
        requestQueue ~= newRequest;

        /* Unlock the queue */
        unlockQueue();
    }

    public bool isValidTag(ulong tag)
    {
        for(ulong i = 0; i < requestQueue.length; i++)
        {
            if(requestQueue[i].tag == tag)
            {
                return true;
            }
        }
        return false;
    }

    public ulong getTagPosition(ulong tag)
    {
        for(ulong i = 0; i < requestQueue.length; i++)
        {
            if(requestQueue[i].tag == tag)
            {
                return i;
            }
        }
        return 0;
    }

    public byte[] receiveMessage(ulong tag)
    {
        /* The received data */
        byte[] receivedData;

        /* Loop till fulfilled */
        while(true)
        {
            /* Lock the queue for reading */
            lockQueue();

            /* Check if the request has been fulfilled */
            if(requestQueue[getTagPosition(tag)].isFulfilled())
            {
                receivedData = requestQueue[getTagPosition(tag)].dataReceived;

                /* TODO: Set the request to dead now */
                break;
            }

            /* Unlock the queue */
            unlockQueue();
        }

        return receivedData;
    }

    public Request[] getQueue()
    {
        return requestQueue;
    }

    public Request[]* getQueueVariable()
    {
        return &requestQueue;
    }

    public void lockQueue()
    {
        queueMutex.lock();
    }

    public void unlockQueue()
    {
        queueMutex.unlock();
    }
}