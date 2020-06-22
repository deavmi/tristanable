module tristanable.watcher;

import tristanable.manager : Manager;
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

    this(Manager manager, Socket endpoint)
    {
        super(&watchLoop);
        this.manager = manager;
        this.endpoint = endpoint;
    }

    private void watchLoop()
    {
        while(true)
        {
            /* TODO: Loop here */
        }
    }
}