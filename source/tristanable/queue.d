module tristanable.queue;

// TODO: Examine the below import which seemingly fixes stuff for libsnooze
import libsnooze.clib;
import libsnooze;

import tristanable.queueitem : QueueItem;
import core.sync.mutex : Mutex;

public class Queue
{
    /** 
     * Everytime a thread calls `.dequeue()` on this queue
     * 
     */
    private Event event;

    private QueueItem queue;
    private Mutex queueLock;
    
    /** 
     * This queue's unique ID
     */
    private ulong queueID;


    private this()
    {
        /* Initialize the queue lock */
        this.queueLock = new Mutex();

        /* Initialize the event */
        this.event = new Event();
    }

    public void dequeue()
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

        // TODO: Lock queue
        queueLock.lock();

        // TODO: Get item off queue

        // TODO: Unlock queue
        queueLock.unlock();
    }

    public static Queue newQueue(ulong queueID)
    {
        Queue queue;

        // TODO: Implement me

        return queue;
    }
}