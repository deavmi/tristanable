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

    /**
    * Whether or not the watcher is active
    */
    private bool isActive;

    this(Manager manager)
    {
        /* Set the worker function */
        super(&cleaner);

        /* Set the manager */
        this.manager = manager;

        /* Set the pointer */
        requestQueueVariable = cast(Request[]*)manager.getQueueVariable();

        isActive = true;
    }

    public void stopGC()
    {
        isActive = false;
    }

    /* TODO: Add timeout ability */
    private void cleaner()
    {
        while(isActive)
        {
            /* Lock the queue */
            manager.lockQueue();

            /* Construct a new list */
            Request[] newList;

            /* Only add to this list undead requests */
            foreach(Request request; *requestQueueVariable)
            {
                if(!request.isDead)
                {
                    newList ~= request;
                }
            }

            /* Update the queue to the new queue */
            *requestQueueVariable = newList;

            /* Unlock the queue */
            manager.unlockQueue();

            /* Sleep for 60 seconds after cleaning up */
            sleep(dur!("seconds")(60));
            
        }
    }
}