/** 
 * Management of a tristanable instance
 */
module tristanable.manager.manager;

import std.socket;
import tristanable.queue.queue : Queue;
import core.sync.mutex : Mutex;
import tristanable.manager.watcher : Watcher;
import tristanable.encoding : TaggedMessage;
import tristanable.exceptions;
import std.container.slist : SList;
import tristanable.manager.config;
import river.core;
import river.impls.sock : SockStream;
import bformat.client;

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
     * Configuration
     */
    private Config config;

    /** 
     * The bformat client to read and write from
     */
    private BClient bClient;

    /** 
     * Currently registered queues
     */
    private SList!(Queue) queues;

    /** 
     * Lock for currently registered queues
     */
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
     *   stream = the underlying stream to use
     */
    this(Stream stream, Config config = defaultConfig())
    {
        this.bClient = new BClient(stream);
        this.queuesLock = new Mutex();
        this.config = config;
        this.watcher = new Watcher(this, bClient);
    }

    // TODO: Comment this
    // This is for backwards compatibility (whereby a `Socket` was taken in)
    this(Socket socket, Config config = defaultConfig())
    {
        this(new SockStream(socket), config);
    }

    /** 
     * Starts the management of the socket,
     * resulting in queues being updated upon
     * reciving messages tagged for them
     */
    public void start()
    {
        watcher.startWatcher();
    }

    /** 
     * Stops the management of the socket, resulting
     * in ending the updating of queues and closing
     * the underlying connection
     */
    public void stop()
    {
        watcher.shutdown();
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
     * Get a new queue thatis unique in its tag
     * (unused/not regustered yet), register it
     * and then return it
     *
     * Returns: the newly registered Queue
     */
    public Queue getUniqueQueue()
    {
        /* The newly created queue */
        Queue uniqueQueue;

        /* Lock the queue of queues */
        queuesLock.lock();

        /* On return or error */
        scope(exit)
        {
            /* Unlock the queue of queues */
            queuesLock.unlock();
        }

        // TODO: Throw exception if all tags used
        /* The unused tag */
        ulong unusedTag = 0;

        /* Try the current tag and ensure no queue uses it */
        tagLoop: for(ulong curPotentialTag = 0; true; curPotentialTag++)
        {
            foreach(Queue curQueue; queues)
            {
                if(curQueue.getID() == curPotentialTag)
                {
                    continue tagLoop;
                }
            }

            /* Then we have found a unique tag */
            unusedTag = curPotentialTag;
            break;
        }

        /* Create the queue */
        uniqueQueue = new Queue(unusedTag);

        /* Register it */
        registerQueue(uniqueQueue);

        return uniqueQueue;
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
        /* Try to register the queue */
        bool status = registerQueue_nothrow(queue);

        /* If registration was not successful */
        if(!status)
        {
            throw new TristanableException(ErrorType.QUEUE_ALREADY_EXISTS);
        }
    }

    /** 
     * Registers the given queue with the manager
     *
     * Params:
     *   queue = the queue to register
     * Returns: true if registration was successful, false otherwise
     */
    public bool registerQueue_nothrow(Queue queue)
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
                /* Registration failed */
                return false;
            }
        }

        /* Insert the queue as it does not exist */
        queues.insertAfter(queues[], queue);

        /* Registration was a success */
        return true;
    }

    /** 
     * De-registers the given queue from the manager
     *
     * Params:
     *   queue = the queue to de-register
     * Throws:
     *   TristanableException if a queue with the provided id cannot be found
     */
    public void releaseQueue(Queue queue)
    {
        /* Try to de-register the queue */
        bool status = releaseQueue_nothrow(queue);

        /* If de-registration was not successful */
        if(!status)
        {
            throw new TristanableException(ErrorType.QUEUE_NOT_FOUND);
        }
    }

    /** 
     * De-registers the given queue from the manager
     *
     * Params:
     *   queue = the queue to de-register
     * Returns: true if de-registration was successful, false otherwise
     */
    public bool releaseQueue_nothrow(Queue queue)
    {
        /* Lock the queue of queues */
        queuesLock.lock();

        /* On return or error */
        scope(exit)
        {
            /* Unlock the queue of queues */
            queuesLock.unlock();
        }

        /* Search for the queue, return false if it does NOT exist */
        foreach(Queue curQueue; queues)
        {
            if(curQueue.getID() == queue.getID())
            {
                /* Remove the queue */
                queues.linearRemoveElement(queue);

                /* De-registration succeeded */
                return true;
            }
        }

        /* De-registration failed */
        return false;
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

    /** 
     * Sends the provided message over the socket
     *
     * Params:
     *   message = the TaggedMessage to send
     */
    public void sendMessage(TaggedMessage message)
    {
        /**
         * If a queue with the tag of the message does
         * not exist, then register it if the config
         * option was enabled
         */
        if(config.registerOnSend)
        {
            /* Create a Queue with the tag */
            Queue createdQueue = new Queue(message.getTag());

            /* Attempt to register the queue */
            registerQueue_nothrow(createdQueue);
        }

        /* Encode the message */
        byte[] encodedMessage = message.encode();

        /* Send it using bformat (encode-and-send) */
        bClient.sendMessage(encodedMessage);
    }
}



// TODO: Fix this, write it in a nicer way
// ... or make a private constructor here that
// ... does not take it in
version(unittest)
{
    Socket nullSock = null;
}

/**
 * Test retrieving a queue which does not
 * exist
 */
unittest
{
    /* Create a manager */
    Manager manager = new Manager(nullSock);

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
    Manager manager = new Manager(nullSock);

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
 * Tests registering a queue and then registering
 * another queue with the same id
 */
unittest
{
    /* Create a manager */
    Manager manager = new Manager(nullSock);

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

/**
 * Tests registering a queue, de-registering it and
 * then registering it again
 */
unittest
{
    /* Create a manager */
    Manager manager = new Manager(nullSock);

    /* Create a new queue with tag 69 */
    Queue queue = new Queue(69);

    /* Register the queue */
    manager.registerQueue(queue);

    /* Ensure it is registered */
    assert(queue == manager.getQueue(69));

    /* De-register the queue */
    manager.releaseQueue(queue);

    /* Ensure it is de-registered */
    assert(manager.getQueue_nothrow(69) is null);

    /* Register the queue (again) */
    manager.registerQueue(queue);

    /* Ensure it is registered (again) */
    assert(queue == manager.getQueue(69));
}

/**
 * Tests registering a queue using the "next available queue"
 * method
 */
unittest
{
    /* Create a manager */
    Manager manager = new Manager(nullSock);

    /* Get the next 3 available queues */
    Queue queue1 = manager.getUniqueQueue();
    Queue queue2 = manager.getUniqueQueue();
    Queue queue3 = manager.getUniqueQueue();

    /* The queues should have tags [0, 1, 2] respectively */
    assert(queue1.getID() == 0);
    assert(queue2.getID() == 1);
    assert(queue3.getID() == 2);
}

// TODO: Add testing for queue existence (internal method)