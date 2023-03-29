module tristanable.exceptions;

public enum ErrorType
{
    QueueExists,
    QUEUE_NOT_FOUND,
    QUEUE_ALREADY_EXISTS
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