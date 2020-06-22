module tristanable.manager;

import tristanable.watcher : Watcher;
import tristanable.request : Request;
import std.socket : Socket;

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

    this(Socket endpoint)
    {
        /* TODO: Create the watcher */
        watcher = new Watcher(this, endpoint);

        /* TODO: Other initializations (queues etc.) */

        /* Start the watcher */
        watcher.start();
    }

    public void sendMessage(ulong tag, byte[] data)
    {
        /* TODO: Implement me */
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