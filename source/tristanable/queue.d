module tristanable.queue;

// TODO: Examine the below import which seemingly fixes stuff for libsnooze
import libsnooze.clib;
import libsnooze;

import core.sync.mutex : Mutex;
import std.container.slist : SList;
import tristanable.encoding;

version(unittest)
{
   import std.stdio;
   import std.conv : to;
}

public class Queue
{
    /** 
     * Everytime a thread calls `.dequeue()` on this queue
     * 
     */
    private Event event;

    private SList!(TaggedMessage) queue;
    private Mutex queueLock;
    
    /** 
     * This queue's unique ID
     */
    private ulong queueID;


    this(ulong queueID)
    {
        /* Initialize the queue lock */
        this.queueLock = new Mutex();

        /* Initialize the event */
        this.event = new Event();

        /* Set the queue id */
        this.queueID = queueID;
    }

    /** 
     * Enqueues the provided tagged message onto this queue
     * and then wakes up any thread that has called dequeue
     * on this queue as well
     *
     * Params:
     *   message = the TaggedMessage to enqueue
     */
    public void enqueue(TaggedMessage message)
    {
        version(unittest)
        {
            writeln("queue["~to!(string)(queueID)~"]: Enqueuing '"~to!(string)(message)~"'...");
        }

        scope(exit)
        {
            version(unittest)
            {
                writeln("queue["~to!(string)(queueID)~"]: Enqueued '"~to!(string)(message)~"'!");
            }

            /* Unlock the item queue */
            queueLock.unlock();
        }

        /* Lock the item queue */
        queueLock.lock();

        /* Add the item to the queue */
        queue.insertAfter(queue[], message);

        /* Wake up anyone wanting to dequeue from us */
        try
        {
            // TODO: Make us wait on the event (optional with a time-out)
            event.notifyAll();
        }
        catch(SnoozeError snozErr)
        {
            // TODO: Add error handling for libsnooze exceptions here
        }
    }

    // TODO: Make a version of this which can time out

    /** 
     * Blocks till a message can be dequeued from this queue
     *
     * Returns: the dequeued TaggedMessage
     */
    public TaggedMessage dequeue()
    {
        version(unittest)
        {
            writeln("queue["~to!(string)(queueID)~"]: Dequeueing...");
        }

        /* The dequeued message */
        TaggedMessage dequeuedMessage;

        scope(exit)
        {
            version(unittest)
            {
                writeln("queue["~to!(string)(queueID)~"]: Dequeued '"~to!(string)(dequeuedMessage)~"'!");
            }
        }

        /* Block till we dequeue a message successfully */
        while(dequeuedMessage is null)
        {
            try
            {
                // TODO: Make us wait on the event (optional with a time-out)
                event.wait();
            }
            catch(SnoozeError snozErr)
            {
                // TODO: Add error handling for libsnooze exceptions here
            }

            /* Lock the item queue */
            queueLock.lock();

            /* Consume the front of the queue (if non-empty) */
            if(!queue.empty())
            {
                /* Pop the front item off */
                dequeuedMessage = queue.front();

                /* Remove the front item from the queue */
                queue.linearRemoveElement(dequeuedMessage);
            }

            /* Unlock the item queue */
            queueLock.unlock();
        }

        return dequeuedMessage;
    }

    public ulong getID()
    {
        return queueID;
    }
}