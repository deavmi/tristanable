/**
 * Facilitates the reading of messages from the socket,
 * decoding thereof and final enqueuing thereof into their
 * respective queus
 */
module tristanable.manager.watcher;

import core.thread : Thread;
import tristanable.manager.manager : Manager;
import std.socket;
import bformat;
import tristanable.encoding;
import tristanable.exceptions;
import tristanable.queue.queue;
import bformat.client;

/** 
 * Watches the socket on a thread of its own,
 * performs the decoding of the incoming messages
 * and places them into the correct queues via
 * the associated Manager instance
 */
public class Watcher : Thread
{
    /** 
     * The associated manager to use
     * such that we can place new mail
     * into their respective inboxes (queues)
     */
    private Manager manager;

    /** 
     * The BClient to read from
     */
    private BClient bClient;

    /** 
     * Creates a new `Watcher` that is associated
     * with the provided `Manager` such that it can
     * add to its registered queues. The provided `Socket`
     * is such that it can be read from and managed.
     *
     * Params:
     *   manager = the `Manager` to associate with
     *   bclient = the underlying `BClient` to read data from
     */
    package this(Manager manager, BClient bClient)
    {
        this.manager = manager;
        this.bClient = bClient;

        super(&watch);
    }

    /** 
     * Starts the underlying thread
     */
    package void startWatcher()
    {
        /* Start the watch method on a new thread */
        start();
    }

    /** 
     * Watches the socket for incoming messages
     * and decodes them on the fly, placing
     * the final message in the respective queue
     */    
    private void watch()
    {
        import std.stdio;
        
        while(true)
        {
            /* Do a bformat read-and-decode */
            byte[] wireTristan;
            version(unittest) { writeln("Before bformat recv()"); }
            bool recvStatus = bClient.receiveMessage(wireTristan); // TODO: Add a check for the status of read
            version(unittest) { writeln("After bformat recv()"); }
            version(unittest) { writeln("bformat recv() status: ", recvStatus); }

            if(recvStatus)
            {
                /* Decode the received bytes into a tagged message */
                TaggedMessage decodedMessage = TaggedMessage.decode(wireTristan);
                version(unittest) { writeln("Watcher received: ", decodedMessage); }

                /* Search for the queue with the id provided */
                ulong messageTag = decodedMessage.getTag();
                Queue potentialQueue = manager.getQueue_nothrow(messageTag);

                /* If a queue can be found */
                if(potentialQueue !is null)
                {
                    /* Enqueue the message */
                    potentialQueue.enqueue(decodedMessage);
                }
                /* If the queue if not found */
                else
                {
                    /**
                     * Look for a default queue, and if one is found
                     * then enqueue the message there. Otherwise, drop
                     * it by simply doing nothing.
                     */
                    try
                    {
                        potentialQueue = manager.getDefaultQueue();

                        /* Enqueue the message */
                        potentialQueue.enqueue(decodedMessage);
                    }
                    catch(TristanableException e) {}
                }

                version(unittest) { writeln("drip"); }
            }
            /**
             * If there was an error receiving on the socket.
             *
             * This can be either because we have shut the socket down
             * or the remote end has closed the connection.
             *
             * In any case, exit the loop therefore ending this thread.
             */
            else
            {
                break;
            }
        }

        version(unittest) { writeln("Exited watcher loop"); }

        // NOTE: This will also be run on normal user-initiated `stop()`
        // ... but will just try shutdown an alreayd shutdown manager
        // ... again and try shut our already-closed river stream
        // Shutdown and unblock all `dequeue()` calls

        // TODO: A problem is user-initiated could cause this to trugger first and then throw
        // ... actually with a WATCHER_FAILED - we should maybe use one error
        // ... or find a smart way to have the right flow go off - split up calls
        // ... more?
        this.manager.stop_FailedWatcher();
    }

    /** 
     * Shuts down the watcher, unblocks the blocking read in the loop
     * resulting in the watcher thread ending
     */
    package void shutdown()
    {
        /* Closes the bformat reader */
        bClient.close();
    }
}

version(unittest)
{
    import std.socket;
    import std.stdio;
    import core.thread;
}

/** 
 * Set up a server which will send some tagged messages to us (the client),
 * where we have setup a `Manager` to watch the queues with tags `42` and `69`,
 * we then dequeue some messages from both queus. Finally, we shut down the manager.
 */
unittest
{
    Address serverAddress = parseAddress("::1", 0);
    Socket server = new Socket(AddressFamily.INET6, SocketType.STREAM, ProtocolType.TCP);
    server.bind(serverAddress);
    server.listen(0);

    class ServerThread : Thread
    {
        this()
        {
            super(&worker);
        }

        private void worker()
        {
            Socket clientSocket = server.accept();
            BClient bClient = new BClient(clientSocket);

            Thread.sleep(dur!("seconds")(7));
            writeln("Server start");

            /** 
             * Create a tagged message to send
             *
             * tag 42 payload Cucumber 😳️
             */
            TaggedMessage message = new TaggedMessage(42, cast(byte[])"Cucumber 😳️");
            byte[] tEncoded = message.encode();
            writeln("server send status: ", bClient.sendMessage(tEncoded));

            writeln("server send [done]");

            /** 
             * Create a tagged message to send
             *
             * tag 69 payload Hello
             */
            message = new TaggedMessage(69, cast(byte[])"Hello");
            tEncoded = message.encode();
            writeln("server send status: ", bClient.sendMessage(tEncoded));

            writeln("server send [done]");

            /** 
             * Create a tagged message to send
             *
             * tag 69 payload Bye
             */
            message = new TaggedMessage(69, cast(byte[])"Bye");
            tEncoded = message.encode();
            writeln("server send status: ", bClient.sendMessage(tEncoded));

            writeln("server send [done]");

            /** 
             * Create a tagged message to send
             *
             * tag 100 payload Bye
             */
            message = new TaggedMessage(100, cast(byte[])"DEFQUEUE_1");
            tEncoded = message.encode();
            writeln("server send status: ", bClient.sendMessage(tEncoded));

            writeln("server send [done]");

            /** 
             * Create a tagged message to send
             *
             * tag 200 payload Bye
             */
            message = new TaggedMessage(200, cast(byte[])"DEFQUEUE_2");
            tEncoded = message.encode();
            writeln("server send status: ", bClient.sendMessage(tEncoded));

            writeln("server send [done]");
        }
    }

    ServerThread serverThread = new ServerThread();
    serverThread.start();

    Socket client = new Socket(AddressFamily.INET6, SocketType.STREAM, ProtocolType.TCP);
    
    writeln(server.localAddress);


    Manager manager = new Manager(client);

    Queue sixtyNine = new Queue(69);
    Queue fortyTwo = new Queue(42);

    manager.registerQueue(sixtyNine);
    manager.registerQueue(fortyTwo);

    // Register a default queue (tag ignored)
    Queue defaultQueue = new Queue(2332);
    manager.setDefaultQueue(defaultQueue);


    /* Connect our socket to the server */
    client.connect(server.localAddress);

    /* Start the manager and let it manage the socket */
    manager.start();

    /* Block on the unittest thread for a received message */
    writeln("unittest thread: Dequeue() blocking...");
    TaggedMessage dequeuedMessage = sixtyNine.dequeue();
    writeln("unittest thread: Got '"~dequeuedMessage.toString()~"' decode payload to string '"~cast(string)dequeuedMessage.getPayload()~"'");
    assert(dequeuedMessage.getTag() == 69);
    assert(dequeuedMessage.getPayload() == cast(byte[])"Hello");

    /* Block on the unittest thread for a received message */
    writeln("unittest thread: Dequeue() blocking...");
    dequeuedMessage = sixtyNine.dequeue();
    writeln("unittest thread: Got '"~dequeuedMessage.toString()~"' decode payload to string '"~cast(string)dequeuedMessage.getPayload()~"'");
    assert(dequeuedMessage.getTag() == 69);
    assert(dequeuedMessage.getPayload() == cast(byte[])"Bye");

    /* Block on the unittest thread for a received message */
    writeln("unittest thread: Dequeue() blocking...");
    dequeuedMessage = fortyTwo.dequeue();
    writeln("unittest thread: Got '"~dequeuedMessage.toString()~"' decode payload to string '"~cast(string)dequeuedMessage.getPayload()~"'");
    assert(dequeuedMessage.getTag() == 42);
    assert(dequeuedMessage.getPayload() == cast(byte[])"Cucumber 😳️");
    
    
    /* Dequeue two messages from the default queue */
    writeln("unittest thread: Dequeue() blocking...");
    dequeuedMessage = defaultQueue.dequeue();
    writeln("unittest thread: Got '"~dequeuedMessage.toString()~"' decode payload to string '"~cast(string)dequeuedMessage.getPayload()~"'");
    assert(dequeuedMessage.getTag() == 100);
    assert(dequeuedMessage.getPayload() == cast(byte[])"DEFQUEUE_1");

    writeln("unittest thread: Dequeue() blocking...");
    dequeuedMessage = defaultQueue.dequeue();
    writeln("unittest thread: Got '"~dequeuedMessage.toString()~"' decode payload to string '"~cast(string)dequeuedMessage.getPayload()~"'");
    assert(dequeuedMessage.getTag() == 200);
    assert(dequeuedMessage.getPayload() == cast(byte[])"DEFQUEUE_2");


    /* Stop the manager */
    manager.stop();
}

/**
 * Setup a `Manager` and then block on a `dequeue()`
 * but from another thread shutdown the `Manager`.
 *
 * This is to test the exception triggering mechanism
 * for such a case
 */
unittest
{
    writeln("<<<<< Test 3 start >>>>>");

    Address serverAddress = parseAddress("::1", 0);
    Socket server = new Socket(AddressFamily.INET6, SocketType.STREAM, ProtocolType.TCP);
    server.bind(serverAddress);
    server.listen(0);

    class ServerThread : Thread
    {
        this()
        {
            super(&worker);
        }

        private void worker()
        {
            Socket clientSocket = server.accept();
            BClient bClient = new BClient(clientSocket);

            Thread.sleep(dur!("seconds")(7));
            writeln("Server start");

            /** 
             * Create a tagged message to send
             *
             * tag 42 payload Cucumber 😳️
             */
            TaggedMessage message = new TaggedMessage(42, cast(byte[])"Cucumber 😳️");
            byte[] tEncoded = message.encode();
            writeln("server send status: ", bClient.sendMessage(tEncoded));

            writeln("server send [done]");

            sleep(dur!("seconds")(15));

            writeln("Server ending");
        }
    }

    ServerThread serverThread = new ServerThread();
    serverThread.start();

    Socket client = new Socket(AddressFamily.INET6, SocketType.STREAM, ProtocolType.TCP);
    
    writeln(server.localAddress);


    Manager manager = new Manager(client);

    Queue sixtyNine = new Queue(69);

    manager.registerQueue(sixtyNine);
    

    /* Connect our socket to the server */
    client.connect(server.localAddress);

    /* Start the manager and let it manage the socket */
    manager.start();
    

    // The failing exception
    TristanableException failingException;

    class DequeueThread : Thread
    {
        private Queue testQueue;

        this(Queue testQueue)
        {
            super(&worker);
            this.testQueue = testQueue;
        }

        public void worker()
        {
            try
            {
                writeln("dequeuThread: Before dequeue()");
                this.testQueue.dequeue();
                writeln("dequeueThread: After dequeue() [should not get here]");
            }
            catch(TristanableException e)
            {
                writeln("Got tristanable exception during dequeue(): "~e.toString());

                // TODO: Fliup boolean is all cgood and assret it later
                failingException = e;
            }
        }
    }

    DequeueThread dequeueThread = new DequeueThread(sixtyNine);
    dequeueThread.start();

    // Stop the manager
    manager.stop();
    writeln("drop");

    // Wait for the dequeueing thread to stop
    dequeueThread.join();

    // Check condition
    assert(failingException !is null);
    assert(failingException.getError() == ErrorType.MANAGER_SHUTDOWN);
}

/**
 * Setup a server which dies (kills its connection to us)
 * midway whilst we are doing a `dequeue()`
 *
 * This is to test the exception triggering mechanism
 * for such a case
 */
unittest
{
    writeln("<<<<< Test 4 start >>>>>");

    Address serverAddress = parseAddress("::1", 0);
    Socket server = new Socket(AddressFamily.INET6, SocketType.STREAM, ProtocolType.TCP);
    server.bind(serverAddress);
    server.listen(0);

    class ServerThread : Thread
    {
        this()
        {
            super(&worker);
        }

        private void worker()
        {
            Socket clientSocket = server.accept();
            BClient bClient = new BClient(clientSocket);

            Thread.sleep(dur!("seconds")(7));
            writeln("Server start");

            sleep(dur!("seconds")(15));

            writeln("Server ending");

            // Close the connection
            bClient.close();
        }
    }

    ServerThread serverThread = new ServerThread();
    serverThread.start();

    Socket client = new Socket(AddressFamily.INET6, SocketType.STREAM, ProtocolType.TCP);
    
    writeln(server.localAddress);


    Manager manager = new Manager(client);

    Queue sixtyNine = new Queue(69);

    manager.registerQueue(sixtyNine);
    

    /* Connect our socket to the server */
    client.connect(server.localAddress);

    /* Start the manager and let it manage the socket */
    manager.start();
    

    // The failing exception
    TristanableException failingException;

    class DequeueThread : Thread
    {
        private Queue testQueue;

        this(Queue testQueue)
        {
            super(&worker);
            this.testQueue = testQueue;
        }

        public void worker()
        {
            try
            {
                writeln("dequeuThread: Before dequeue()");
                this.testQueue.dequeue();
                writeln("dequeueThread: After dequeue() [should not get here]");
            }
            catch(TristanableException e)
            {
                writeln("Got tristanable exception during dequeue(): "~e.toString());

                // TODO: Fliup boolean is all cgood and assret it later
                failingException = e;
            }
        }
    }

    DequeueThread dequeueThread = new DequeueThread(sixtyNine);
    dequeueThread.start();

    // Wait for the dequeueing thread to stop
    dequeueThread.join();

    // Check condition
    assert(failingException !is null);
    assert(failingException.getError() == ErrorType.WATCHER_FAILED);
}