/**
 * A queue of queue items all of the same tag
 */
module tristanable.queue;

// TODO: Examine the below import which seemingly fixes stuff for libsnooze
import libsnooze.clib;
import libsnooze;

import core.sync.mutex : Mutex;
import std.container.slist : SList;
import tristanable.encoding;
import core.thread : dur;
import tristanable.exceptions;

version(unittest)
{
   import std.stdio;
   import std.conv : to;
}

/** 
 * Represents a queue whereby messages of a certain tag/id
 * can be enqueued to (by the `Watcher`) and dequeued from
 * (by the user application)
 */
public class Queue
{
    /** 
     * The libsnooze event used to sleep/wake
     * on queue events
     */
    private Event event;

    /** 
     * The queue of messages
     */
    private SList!(TaggedMessage) queue;

    /** 
     * The lock for the message queue
     */
    private Mutex queueLock;
    
    /** 
     * This queue's unique ID
     */
    private ulong queueID;


    /** 
     * Constructs a new Queue and immediately sets up the notification
     * sub-system for the calling thread (the thread constructing this
     * object) which ensures that a call to dequeue will immediately
     * unblock on the first message received under this tag
     *
     * Params:
     *   queueID = the id to use for this queue
     */
    this(ulong queueID)
    {
        /* Initialize the queue lock */
        this.queueLock = new Mutex();

        /* Initialize the event */
        this.event = new Event();

        /* Set the queue id */
        this.queueID = queueID;

        /* Ensure pipe existence (see https://deavmi.assigned.network/git/deavmi/tristanable/issues/5) */
        event.wait(dur!("seconds")(0));
    }

    /** 
     * Enqueues the provided tagged message onto this queue
     * and then wakes up any thread that has called dequeue
     * on this queue as well
     *
     * On error enqueueing a `TristanableException` will be
     * thrown.
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
        catch(FatalException snozErr)
        {
            // Throw an exception on a fatal exception
            throw new TristanableException(ErrorType.ENQUEUE_FAILED);
        }
    }

    // TODO: Make a version of this which can time out

    /** 
     * Blocks till a message can be dequeued from this queue
     *
     * On error dequeueing a `TristanableException` will be
     * thrown.
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
            /**
             * Call `wait()` and catch any interrupts
             * in which case loop back and call `wait()`
             * again
             */
            while(true)
            {
                try
                {
                    // TODO: Make us wait on the event (optional with a time-out)
                    event.wait();
                }
                catch(InterruptedException e)
                {
                    version(unittest)
                    {
                        import std.stdio;
                        writeln("dequeue() had libsnooze wait() get interrupted!");
                    }

                    // Retry the wait()
                    continue;
                }
                catch(FatalException fatalErr)
                {
                    version(unittest)
                    {
                        import std.stdio;
                        writeln("dequeue() had libsnooze wait() get FATALLY fail! Exception will now throw...");
                    }

                    // Throw an exception on a fatal exception
                    throw new TristanableException(ErrorType.DEQUEUE_FAILED);
                }

                // On successful wait() wake-up exit this wait()-retry loop
                break;
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

    /** 
     * Get the id/tag of this queue
     *
     * Returns: the queue's id
     */
    public ulong getID()
    {
        return queueID;
    }
}