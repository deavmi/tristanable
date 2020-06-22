module tristanable.manager;

import tristanable.watcher : Watcher;
import tristanable.request : Request;
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

    this(Socket endpoint)
    {
        /* Set the socket */
        socket = endpoint;
        
        /* TODO: Create the watcher */
        watcher = new Watcher(this, endpoint);

        /* TODO: Other initializations (queues etc.) */

        /* Initialize the `requestQueue` mutex */
        queueMutex = new Mutex();

        /* Start the watcher */
        watcher.start();
    }

    public void sendMessage(ulong tag, byte[] data)
    {
        /* TODO: Implement me */

        /* Construct the message array */
        byte[] messageData;

        /* Send the message */
        bSendMessage(endpoint, messageData);


        /* Create a new Request */
        Request newRequest = new Request(tag);

        /* Add the request to the request queue */
        enqueue(newRequest);
    }

    public byte[] receiveMessage(ulong tag)
    {
        /* TODO: Implement me */
    }

    public Request[] getQueue()
    {

    }

    public void enqueue(Request request)
    {

    }
}