module tristanable.encoding;

import std.conv : to;

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
    /** 
     * This message's tag
     */
    private ulong tag;

    /** 
     * The payload
     */
    private byte[] data;

    /** 
     * Constructs a new TaggedMessage with the given tag and payload
     *
     * Params:
     *   tag = the tag to use
     *   data = the payload
     */
    this(ulong tag, byte[] data)
    {
        this.tag = tag;
        this.data = data;
    }

    /** 
     * Parameterless constructor used for decoder
     */
    private this() {}

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
        TaggedMessage decodedMessage = new TaggedMessage();

        /* The decoded tag */
        ulong decodedTag;
        
        /* If on little endian then dump direct */
        version(LittleEndian)
        {
            decodedTag = *cast(ulong*)encodedMessage.ptr;
        }
        /* If on big endian then reverse received 8 bytes */
        else version(BigEndian)
        {
            /* Base of our tag */
            byte* tagHighPtr = cast(byte*)decodedTag.ptr;

            *(tagHighPtr+0) = encodedMessage[7];
            *(tagHighPtr+1) = encodedMessage[6];
            *(tagHighPtr+2) = encodedMessage[5];
            *(tagHighPtr+3) = encodedMessage[4];
            *(tagHighPtr+4) = encodedMessage[3];
            *(tagHighPtr+5) = encodedMessage[2];
            *(tagHighPtr+6) = encodedMessage[1];
            *(tagHighPtr+7) = encodedMessage[0];
        }
        /* Blessed is the fruit of thy womb Jesus, hail Mary, mother of God, pray for our sinners - now and at the hour of our death - Amen */
        else
        {
            pragma(msg, "Not too sure about tha 'ey 😳️");
        }

        /* Set the tag */
        decodedMessage.setTag(decodedTag);

        /* Set the data *(9-th byte onwards) */
        decodedMessage.setPayload(encodedMessage[8..$]);

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

    /** 
     * Get the message's payload
     *
     * Returns: the payload
     */
    public byte[] getPayload()
    {
        return data;
    }

    /** 
     * Get the message's tag
     *
     * Returns: the tag
     */
    public ulong getTag()
    {
        return tag;
    }

    /** 
     * Set the message's payload
     *
     * Params:
     *   newPayload = the payload to use
     */
    public void setPayload(byte[] newPayload)
    {
        this.data = newPayload;
    }

    /** 
     * Set the message's tag
     *
     * Params:
     *   newTag = the tag to use
     */
    public void setTag(ulong newTag)
    {
        this.tag = newTag;
    }

    /** 
     * Returns a string representation of the TaggedMessage
     *
     * Returns: the string represenation
     */
    public override string toString()
    {
        return "TMessage [Tag: "~to!(string)(tag)~", Payload: "~to!(string)(data)~"]";
    }
}

/**
 * Test encoding and decoding
 */
unittest
{
    /* Setup testing data */
    TaggedMessage testData = new TaggedMessage(420, [1,2,3]);

    /* Encode */
    byte[] encoded = testData.encode();

    /* Decode */
    TaggedMessage decoded = TaggedMessage.decode(encoded);

    /* Now ensure that `decoded` == original `testData` */
    assert(decoded.getTag() == testData.getTag);
    assert(decoded.getPayload() == testData.getPayload());
}