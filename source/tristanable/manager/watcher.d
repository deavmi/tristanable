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

    // TODO: make package-level in a way such
    // ... that only Manager can access this constructor
    // TODO: Add constructor doc
    package this(Manager manager, Socket socket)
    {
        this.manager = manager;
        this.socket = socket;

        super(&watch);
    }

    /** 
     * Watches the socket for incoming messages
     * and decodes them on the fly, placing
     * the final message in the respective queue
     */    
    private void watch()
    {
        while(true)
        {
            /* Do a bformat read-and-decode */
            byte[] wireTristan;
            receiveMessage(socket, wireTristan); // TODO: Add a check for the status of read

            /* Decode the received bytes into a tagged message */
            TaggedMessage decodedMessage = TaggedMessage.decode(wireTristan);
            import std.stdio;
            writeln("Watcher received: ", decodedMessage);

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

            

            // TODO: Implement me
        }
    }
}


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

            Thread.sleep(dur!("seconds")(2));
            writeln("Server start");

            /** 
             * Create a tagged message to send
             *
             * tag 69 payload Hello
             */
            TaggedMessage message = new TaggedMessage(69, cast(byte[])"Hello");
            byte[] tEncoded = message.encode();
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

    class WaitingThread : Thread
    {
        private Queue testQueue;

        this(Queue testQueue)
        {
            super(&worker);
            this.testQueue = testQueue;
        }

        private void worker()
        {
            writeln("WaitingThread: Dequeue() blocking...");
            TaggedMessage dequeuedMessage = testQueue.dequeue();
            writeln("WaitingThread: Got '"~dequeuedMessage.toString()~"'");
        }
    }

    WaitingThread waiting = new WaitingThread(sixtyNine);
    waiting.start();
    manager.registerQueue(sixtyNine);


    client.connect(server.localAddress);
    manager.start();

    
    

    // while(true){}
}