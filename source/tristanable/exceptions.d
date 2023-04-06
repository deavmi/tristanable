/**
 * Error handling type definitions
 */
module tristanable.exceptions;

/** 
 * The type of sub-error of the `TristanableException`
 */
public enum ErrorType
{
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
    NO_DEFAULT_QUEUE
}

/** 
 * Any sort of error that occurs during runtime of the tristanable
 * engine
 */
public class TristanableException : Exception
{
    private ErrorType err;
    
    this(ErrorType err)
    {
        // TODO: Do this
        super("TODO: Do this");

        this.err = err;
    }

    public ErrorType getError()
    {
        return err;
    }
}