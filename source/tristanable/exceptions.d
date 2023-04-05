module tristanable.exceptions;

public enum ErrorType
{
    QUEUE_NOT_FOUND,
    QUEUE_ALREADY_EXISTS,
    NO_DEFAULT_QUEUE
}

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