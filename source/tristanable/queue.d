module tristanable.queue;

// TODO: Examine the below import which seemingly fixes stuff for libsnooze
import libsnooze.clib;
import libsnooze;

import tristanable.queueitem : QueueItem;
import core.sync.mutex : Mutex;
import std.container.slist : SList;
import tristanable.encoding;

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

    public void enqueue(TaggedMessage message)
    {
        // TODO: Implement me
    }

    public TaggedMessage dequeue()
    {
        TaggedMessage message;

        try
        {
            // TODO: Make us wait on the event (optional with a time-out)
            event.wait();
        }
        catch(SnoozeError snozErr)
        {
            // TODO: Add error handling for libsnooze exceptions here
        }

        // TODO: Lock queue
        queueLock.lock();

        // TODO: Get item off queue

        // TODO: Unlock queue
        queueLock.unlock();

        return message;
    }

    public ulong getID()
    {
        return queueID;
    }
}