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

/** 
 * Set up a server which will send some tagged messages to us (the client),
 * where we have setup a `Manager` to watch the queues with tags `42` and `69`,
 * we then dequeue some messages from both queus. Finally, we shut down the manager.
 */
unittest
{
    import std.socket;
    import std.stdio;
    import core.thread;

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