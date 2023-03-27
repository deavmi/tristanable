module tristanable.exceptions;

public enum Error
{
    QueueExists
}

public class TristanableException : Exception
{
    this(Error err)
    {
        // TODO: Do this
        super("TODO: Do this");
    }
}