/** 
 * Management of a tristanable instance
 */
module tristanable.manager.manager;

import std.socket;
import tristanable.queue : Queue;
import core.sync.mutex : Mutex;
import tristanable.manager.watcher : Watcher;
import tristanable.encoding : TaggedMessage;
import tristanable.exceptions;
import std.container.slist : SList;

/** 
 * Manages a provided socket by spawning
 * a watcher thread to read from it and file
 * mail into the corresponding queues.
 *
 * Queues are managed via this an instance
 * of a manager.
 */
public class Manager
{
    /** 
     * The underlying socket to read from
     */
    private Socket socket;

    /** 
     * Currently registered queues
     *
     * NOTE: Make a ulong map to this later
     */
    private SList!(Queue) queues;
    private Mutex queuesLock;

    /** 
     * Default queue
     */
    private Queue defaultQueue;

    /** 
     * Watcher which manages the socket and
     * enqueues new messages into the respective
     * quueue for us
     */
    private Watcher watcher;

    /** 
     * Constructs a new manager which will read from
     * this socket and file mail for us
     *
     * Params:
     *   socket = the underlying socket to use
     */
    this(Socket socket)
    {
        this.socket = socket;
        this.queuesLock = new Mutex();
        this.watcher = new Watcher(this, socket);
    }

    // TODO: comment
    // Starts the watcher
    public void start()
    {
        watcher.start();
    }

    /**
     * Retrieves the queue mathcing the provided id
     *
     * Params:
     *   id = the id to lookup by
     * Returns: the Queue
     * Throws: TristanableException if the queue is not found
     */
    public Queue getQueue(ulong id)
    {
        /* The found queue */
        Queue queue = getQueue_nothrow(id);

        /* If no queue is found then throw an error */
        if(queue is null)
        {
            throw new TristanableException(ErrorType.QUEUE_NOT_FOUND);
        }

        return queue;
    }

    /** 
     * Retrieves the queue mathcing the provided id
     *
     * This is the nothrow version
     *
     * Params:
     *   id = the id to lookup by
     * Returns: the Queue if found, null otherwise
     */
    public Queue getQueue_nothrow(ulong id)
    {
        /* The found queue */
        Queue queue;

        /* Lock the queue of queues */
        queuesLock.lock();

        /* On return or error */
        scope(exit)
        {
            /* Unlock the queue of queues */
            queuesLock.unlock();
        }

        /* Search for the queue */
        foreach(Queue curQueue; queues)
        {
            if(curQueue.getID() == id)
            {
                queue = curQueue;
                break;
            }
        }

        return queue;
    }

    

    /** 
     * Registers the given queue with the manager
     *
     * Params:
     *   queue = the queue to register
     * Throws:
     *   TristanableException if a queue with the provided id already exists
     */
    public void registerQueue(Queue queue)
    {
        /* Lock the queue of queues */
        queuesLock.lock();

        /* On return or error */
        scope(exit)
        {
            /* Unlock the queue of queues */
            queuesLock.unlock();
        }

        /* Search for the queue, throw an exception if it exists */
        foreach(Queue curQueue; queues)
        {
            if(curQueue.getID() == queue.getID())
            {
                throw new TristanableException(ErrorType.QUEUE_ALREADY_EXISTS);
            }
        }

        /* Insert the queue as it does not exist */
        queues.insertAfter(queues[], queue);
    }

    /** 
     * Sets the default queue
     *
     * The default queue, when set/enabled, is the queue that will
     * be used to enqueue messages that have a tag which doesn't
     * match any of the normally registered queues.
     *
     * Please note that the ID of the queue passed in here does not
     * mean anything in this context; only the queuing facilities
     * of the Queue object are used
     *
     * Params:
     *   queue = the default queue to use
     */
    public void setDefaultQueue(Queue queue)
    {
        this.defaultQueue = queue;
    }

    /** 
     * Returns the default queue
     *
     * Returns: the default queue
     * Throws:
     *   TristanableException if there is no default queue
     */
    public Queue getDefaultQueue()
    {
        /* The potential default queue */
        Queue potentialDefaultQueue = getDefaultQueue_nothrow();

        if(potentialDefaultQueue is null)
        {
            throw new TristanableException(ErrorType.NO_DEFAULT_QUEUE);
        }

        return potentialDefaultQueue;
    }


    /** 
     * Returns the default queue
     *
     * This is the nothrow version
     *
     * Returns: the default queue if found, null otherwise
     */
    public Queue getDefaultQueue_nothrow()
    {
        return defaultQueue;
    }
  



    public void sendMessage(TaggedMessage tag)
    {
        // TODO: Send the given message

        // TODO: Encode into bytes; call it `x`

        // TODO: Wrap `x` in bformat; call it `y`

        // TODO: Do socket.send(`y`)
    }
}


unittest
{
    // TODO: Spawn server here

    // TODO: wait for server to activate
    // TODO: register tristanable quues
    // TODO: make server then send something to us and chekc if queues active
}

/**
 * Test retrieving a queue which does not
 * exist
 */
unittest
{
    /* Create a manager */
    Manager manager = new Manager(null);

    /* Shouldn't be found */
    try
    {
        manager.getQueue(69);
        assert(false);
    }
    catch(TristanableException e)
    {
        assert(e.getError() == ErrorType.QUEUE_NOT_FOUND);
    }

    /* Shouldn't be found */
    assert(manager.getQueue_nothrow(69) is null);
}

/**
 * Test registering a queue and then fetching it
 */
unittest
{
    /* Create a manager */
    Manager manager = new Manager(null);

    /* Create a new queue with tag 69 */
    Queue queue = new Queue(69);

    try
    {
        /* Register the queue */
        manager.registerQueue(queue);

        /* Fetch the queue */
        Queue fetchedQueue = manager.getQueue(69);

        /* Ensure the queue we fetched is the one we stored (the references would be equal) */
        assert(fetchedQueue == queue);
    }
    catch(TristanableException e)
    {
        assert(false);
    }

    /* Should be found */
    assert(manager.getQueue_nothrow(69) !is null);
}

/**
 * tests registering a queue and then registering
 * another queue with the same id
 */
unittest
{
    /* Create a manager */
    Manager manager = new Manager(null);

    /* Create a new queue with tag 69 */
    Queue queue = new Queue(69);

    /* Register the queue */
    manager.registerQueue(queue);

    try
    {
        /* Register the queue (try again) */
        manager.registerQueue(queue);

        assert(false);
    }
    catch(TristanableException e)
    {
        assert(e.getError() == ErrorType.QUEUE_ALREADY_EXISTS);
    }
}