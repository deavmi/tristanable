/**
 * Error handling type definitions
 */
module tristanable.exceptions;

import std.conv : to;

/** 
 * The type of sub-error of the `TristanableException`
 */
public enum ErrorType
{
    /**
     * Unset
     */
    UNSET,

    /**
     * If the manager has already
     * been shutdown
     */
    MANAGER_SHUTDOWN,

    /**
     * If the watcher has failed
     * to stay alive
     */
    WATCHER_FAILED,

    /**
     * If the requested queue could not be found
     */
    QUEUE_NOT_FOUND,

    /**
     * If the queue wanting to be registered has already
     * been registered under the same tag
     */
    QUEUE_ALREADY_EXISTS,

    /** 
     * If no default queue is configured
     */
    NO_DEFAULT_QUEUE,

    /** 
     * The blocking call to `dequeue()`, somehow, failed
     */
    DEQUEUE_FAILED,

    /** 
     * The call to `enqueue()`, somehow, failed
     */
    ENQUEUE_FAILED
}

/** 
 * Any sort of error that occurs during runtime of the tristanable
 * engine
 */
public class TristanableException : Exception
{
    /** 
     * The sub-error type
     */
    private ErrorType err;
    
    /** 
     * Constructs a new `TristanableException` with the provided
     * sub-error type
     *
     * Params:
     *   err = the `ErrorType`
     */
    this(ErrorType err)
    {
        super(this.classinfo.name~": "~to!(string)(err));
        this.err = err;
    }

    /** 
     * Retrieve the sub-error type
     *
     * Returns: the sub-error type as a `ErrorType`
     */
    public ErrorType getError()
    {
        return err;
    }
}