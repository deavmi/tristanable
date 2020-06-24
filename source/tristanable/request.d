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
    * Whether the request has been depleted
    */
    public bool isDead;

    /**
    * The tag for this request
    */
    public ulong tag;

    /**
    * Make a new Request with the provided tag
    * `tag`.
    */
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

    public byte[] pullData()
    {
        isDead = true;
        return dataReceived;
    }

    override public string toString()
    {
        /* the toString string */
        string toStringString;

        /* Add the Request tag info */
        toStringString ~= "Request (Tag: " ~ to!(string)(tag);

        /* Add the Request arrival  status */
        toStringString ~= ", Arrived: " ~ to!(string)(fulfilled);

        /* Add the IsDead tag info */
        toStringString ~= ", Used: " ~ to!(string)(isDead) ~  ")";

        return toStringString;
    }
}