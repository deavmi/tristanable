module tristanable.manager;

import tristanable.watcher : Watcher;
import std.socket : Socket;

/* TODO: Watcher class to watch for stuff, and add to manager's queues */
/* TODO: maneger class to use commands on, enqueue and wait for dequeue */
public final class Manager
{
    /* TODO: Insert queues here */

    /**
    * The associated Watcher object for this manager.
    */
    private Watcher watcher;

    this(Socket endpoint)
    {
        /* TODO: Create the watcher */
        watcher = new Watcher(this, endpoint);
    }
}