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
import tristanable.queue;

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
     * The underlying socket to read from
     */
    private Socket socket;

    /** 
     * Creates a new `Watcher` that is associated
     * with the provided `Manager` such that it can
     * add to its registered queues. The provided `Socket`
     * is such that it can be read from and managed.
     *
     * Params:
     *   manager = the `Manager` to associate with
     *   socket = the underlying `Socket` to read data from
     */
    package this(Manager manager, Socket socket)
    {
        this.manager = manager;
        this.socket = socket;

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
            bool recvStatus = receiveMessage(socket, wireTristan); // TODO: Add a check for the status of read
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

    package void shutdown()
    {
        /* Unblock all calls to `recv()` and disallow future ones */
        // TODO: Would we want to do the same for sends? */
        socket.shutdown(SocketShutdown.RECEIVE);
       
        /* Close the connection */
        socket.close();
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

            Thread.sleep(dur!("seconds")(7));
            writeln("Server start");

            /** 
             * Create a tagged message to send
             *
             * tag 42 payload Cucumber 😳️
             */
            TaggedMessage message = new TaggedMessage(42, cast(byte[])"Cucumber 😳️");
            byte[] tEncoded = message.encode();
            writeln("server send status: ", sendMessage(clientSocket, tEncoded));

            writeln("server send [done]");

            /** 
             * Create a tagged message to send
             *
             * tag 69 payload Hello
             */
            message = new TaggedMessage(69, cast(byte[])"Hello");
            tEncoded = message.encode();
            writeln("server send status: ", sendMessage(clientSocket, tEncoded));

            writeln("server send [done]");

            /** 
             * Create a tagged message to send
             *
             * tag 69 payload Bye
             */
            message = new TaggedMessage(69, cast(byte[])"Bye");
            tEncoded = message.encode();
            writeln("server send status: ", sendMessage(clientSocket, tEncoded));

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
    
    

    /* Stop the manager */
    manager.stop();
}