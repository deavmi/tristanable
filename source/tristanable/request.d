module tristanable.request;

import std.conv : to;

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
    public byte[] dataReceived;

    /**
    * Whether or not this request has been
    * fulfilled or not.
    */
    private bool fulfilled;

    /**
    * Whether 
    */
    public bool isDead;

    /**
    * The tag for this request
    */
    public ulong tag;

    this(ulong tag)
    {
        this.tag = tag;
    }

    public void fulfill(byte[] data)
    {
        dataReceived = data;
        fulfilled = true;
    }

    public bool isFulfilled()
    {
        return fulfilled;
    }

    override public string toString()
    {
        return "Request (Tag: " ~ to!(string)(tag) ~ ", Arrived: " ~ to!(string)(fulfilled) ~ ", Used: " ~ to!(string)(isDead);
    }
}