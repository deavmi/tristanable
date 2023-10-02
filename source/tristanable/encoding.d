/**
 * Encoding/decoding of the tristanable format
 */
module tristanable.encoding;

import std.conv : to;
import niknaks.bits : bytesToIntegral, Order, order, toBytes;

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
        
        /* Take ulong-many bytes and only flip them to LE if not on LE host */
        decodedTag = order(bytesToIntegral!(ushort)(cast(ubyte[])encodedMessage), Order.LE);
        

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

        /* If on little endian then no re-order, if host is BE flip (the tag) */
        encodedMessage ~= toBytes(order(tag, Order.LE));


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