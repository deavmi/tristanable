module tristanable.encoding;

/** 
 * Represents a tagged message that has been decoded
 * from its raw byte encoding, this is a tuple of
 * a numeric tag and a byte array of payload data
 *
 * Also provides a static method to decode from such
 * raw encoding and an instance method to do the reverse
 */
public final class TaggedMessage
{
    private ulong tag;
    private byte[] data;

    this(ulong tag, byte[] data)
    {
        this.tag = tag;
        this.data = data;
    }

    public static TaggedMessage decode(byte[] encodedMessage)
    {
        TaggedMessage decodedMessage;

        // TODO: Implement me

        return decodedMessage;
    }

    public byte[] encode()
    {
        byte[] encodedMessage;


        return encodedMessage;
    }

    public byte[] getPayload()
    {
        return data;
    }

    public ulong getTag()
    {
        return tag;
    }

    public void setPayload(byte[] newPayload)
    {
        this.data = newPayload;
    }

    public void setTag(ulong newTag)
    {
        this.tag = newTag;
    }
}

unittest
{
    // TODO: Test encoding
    // TODO: Test decoding
}