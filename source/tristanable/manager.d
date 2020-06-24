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

    public void stopManager()
    {
        /* Will caue watcher to not block */
        socket.close();

        /* Stop watcher */
        watcher.stopWatcher();

        /* Stop gc */
        gc.stopGC();

        /* Wait for watcher thread to stop */
        watcher.join();

        /* Wait for garbage collector thread to stop */
        gc.join();
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
            /* Get the request */
            Request request = requestQueue[i];

            /**
            * Only if the tag is found then return true
            * and if it is the fresh tagged request (not
            * ones that are dead using the) same tag.
            */
            if(request.isDead == false && request.tag == tag)
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
            /* Get the request */
            Request request = requestQueue[i];

            /**
            * Only if the tag is found then return its
            * posistion and if it is the fresh tagged
            * request (not ones that are dead using the)
            * same tag.
            */
            if(request.isDead == false && request.tag == tag)
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

        bool active = true;

        /* Loop till fulfilled */
        while(active)
        {
            /* Lock the queue for reading */
            lockQueue();

            /* Throw an exception if it doesn't exist */
            if(!isValidTag(tag))
            {
                /* Unlock the queue */
                unlockQueue();

                /* Throw exception here */
                throw new TristanFokop("Invalid tag");
            }

            /* Get the request */
            Request request = requestQueue[getTagPosition(tag)];

            /* Check if the request has been fulfilled */
            if(request.isFulfilled())
            {
                receivedData = request.pullData();


                active = false;
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

public final class TristanFokop : Exception
{
    this(string message)
    {
        super(message);
    }
}