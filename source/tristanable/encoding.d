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

    /** 
     * Decodes the wire-formatted tristanable bytes into an instance
     * of TaggedMessage whereby the tag and data can be seperately
     * accessed and manipulated
     *
     * Params:
     *   encodedMessage = the wire-format encoded bytes
     * Returns: an instance of TaggedMessage
     */
    public static TaggedMessage decode(byte[] encodedMessage)
    {
        /* The decoded message */
        TaggedMessage decodedMessage;

        /* Decoded tag */



        // TODO: Implement me

        return decodedMessage;
    }

    /** 
     * Encodes the tagged message into the tristanable
     * wire format ready for transmission
     *
     * Returns: the encoded bytes
     */
    public byte[] encode()
    {
        /* The encoded bytes */
        byte[] encodedMessage;

        /* If on little endian, then dump 64 bit as is - little endian */
        version(LittleEndian)
        {
            /* Base (little first) of tag */
            byte* basePtr = cast(byte*)&tag;

            encodedMessage ~= *(basePtr+0);
            encodedMessage ~= *(basePtr+1);
            encodedMessage ~= *(basePtr+2);
            encodedMessage ~= *(basePtr+3);
            encodedMessage ~= *(basePtr+4);
            encodedMessage ~= *(basePtr+5);
            encodedMessage ~= *(basePtr+6);
            encodedMessage ~= *(basePtr+7);
        }
        /* If on big endian, then traverse 64-bit number in reverse - and tack on */
        else version(BigEndian)
        {
            /* Base (biggest first) of tag */
            byte* highPtr = cast(byte*)&tag;

            encodedMessage ~= *(highPtr+7);
            encodedMessage ~= *(highPtr+6);
            encodedMessage ~= *(highPtr+5);
            encodedMessage ~= *(highPtr+4);
            encodedMessage ~= *(highPtr+3);
            encodedMessage ~= *(highPtr+2);
            encodedMessage ~= *(highPtr+1);
            encodedMessage ~= *(highPtr+0);
        }
        /* Hail marry, mother of God, pray for our sinners, now and at the our of our death Amen */
        else
        {
            pragma(msg, "Not feeling scrumptious homeslice 😎️");
        }

        /* Tack on the data */
        encodedMessage ~= data;

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