module tristanable.request;

/**
* Request
*
* This type represents a placeholder for an
* expected response caused by the sending of
* an original message with a matching tag.
*/
public final class Request
{
    /**
    * The data received
    */
    private byte[] dataReceived;

    /**
    * Whether or not this request has been
    * fulfilled or not.
    */
    private bool fulfilled;

    /**
    * The tag for this request
    */
    public ulong tag;

    this(ulong tag)
    {
        this.tag = tag;
    }


    public bool isFulfilled()
    {
        /* TODO: Implement me */
        return true;
    }
}