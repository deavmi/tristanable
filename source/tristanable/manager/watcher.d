module tristanable.manager.watcher;

import core.thread : Thread;
import tristanable.manager.manager : Manager;
import std.socket;
import bformat;
import tristanable.encoding;

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
            receiveMessage(socket, wireTristan);

            /* Decode the received bytes into a tagged message */
            TaggedMessage decodedMessage = TaggedMessage.decode(wireTristan);

            // TODO: Implement me
        }
    }
}