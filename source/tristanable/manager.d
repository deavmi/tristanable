/** 
 * Management of a tristanable instance
 */
module tristanable.manager;

import std.socket;
import tristanable.queue : Queue;
import core.sync.mutex : Mutex;
import tristanable.watcher : Watcher;

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
    private Queue[] queues;
    private Mutex queuesLock;

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
    }


    public void registerQueue(Queue queue)
    {
        // TODO: Lock queue

        // TODO: Insert queue only if non-existent, else throw an exception

        // TODO: Unlock queue
    }
}