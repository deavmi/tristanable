module tristanable.watcher;

import core.thread : Thread;
import tristanable.manager : Manager;
import std.socket;

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



    
    private void watch()
    {
        while(true)
        {
            // TODO: Implement me
        }
    }
}