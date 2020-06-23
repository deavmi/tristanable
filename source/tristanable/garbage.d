module tristanable.garbage;

import tristanable.manager : Manager;
import tristanable.request : Request;
import std.socket : Socket;
import core.thread : Thread, Duration, dur;
import bmessage : receiveMessage;

public final class GarbageCollector : Thread
{

    /**
    * The associated manager
    */
    private Manager manager;

    /**
    * The queue variable pointer
    */
    private Request[]* requestQueueVariable;

    this(Manager manager)
    {
        /* Set the worker function */
        super(&cleaner);

        /* Set the manager */
        this.manager = manager;

        /* Set the pointer */
        requestQueueVariable = cast(Request[]*)manager.getQueueVariable();
    }

    private void cleaner()
    {
        while(true)
        {
            /* Lock the queue */
            manager.lockQueue();

            /* TODO: Add clean up here */

            /* Unlock the queue */
            manager.unlockQueue();

            /* Sleep for 60 seconds after cleaning up */
            sleep(dur!("seconds")(60));
            
        }
    }
}