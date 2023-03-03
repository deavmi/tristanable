module tristanable.queue;

import libsnooze;
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


    private this()
    {
        /* Initialize the queue lock */
        this.queueLock = new Mutex();

        /* Initialize the event */
        this.event = new Event();
    }

    public void dequeue()
    {
        // TODO: Make us wait on the event (optional with a time-out)

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

public class QueueItem
{
    
}