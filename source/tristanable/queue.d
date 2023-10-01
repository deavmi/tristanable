/**
 * A queue of queue items all of the same tag
 */
module tristanable.queue;

import core.sync.mutex : Mutex;
import core.sync.condition : Condition;
import core.sync.exception : SyncError;
import std.container.slist : SList;
import tristanable.encoding;
import core.time : Duration, dur;
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
     * Mutex for the condition variable
     */
    private Mutex mutex;

    /** 
     * The condition variable used to sleep/wake
     * on queue of events
     */
    private Condition signal;

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
     * If a message is enqueued prior
     * to us sleeping then we won't
     * wake up and return for it.
     *
     * Therefore a periodic wakeup
     * is required.
     */
    private Duration wakeInterval;

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

        /* Initialize the condition variable */
        this.mutex = new Mutex();
        this.signal = new Condition(this.mutex);

        /* Set the queue id */
        this.queueID = queueID;

        /* Set the slumber interval */
        this.wakeInterval = dur!("msecs")(50); // TODO: Decide on value
    }

    /** 
     * Returns the current wake interval
     * for the queue checker
     *
     * Returns: the `Duration`
     */
    public Duration getWakeInterval()
    {
        return this.wakeInterval;
    }

    /** 
     * Sets the wake up interval
     *
     * Params:
     *   interval = the new interval
     */
    public void setWakeInterval(Duration interval)
    {
        this.wakeInterval = interval;
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
            signal.notifyAll();
        }
        catch(SyncError snozErr)
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
            scope(exit)
            {
                // Unlock the mutex
                this.mutex.unlock();
            }

            // Lock the mutex
            this.mutex.lock();

            try
            {
                this.signal.wait(this.wakeInterval);
            }
            catch(SyncError e)
            {
                // Throw an exception on a fatal exception
                throw new TristanableException(ErrorType.DEQUEUE_FAILED);
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