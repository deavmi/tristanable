module tristanable.encoding;

public final class DataMessage
{

    private ulong tag;
    private byte[] data;

    public static DataMessage decode(byte[] bytes)
    {
        /* Fetch the `tag` */
        ulong receivedTag = *(cast(ulong*)bytes.ptr);

        /* Fetch the `data` */
        byte[] receivedData = bytes[8..bytes.length];

        return new DataMessage(receivedTag, receivedData);
    }

    this(ulong tag, byte[] data)
    {
        this.tag = tag;
        this.data = data;
    }

    public byte[] encode()
    {
        /* Construct the message array */
        byte[] messageData;

        /* Add the `tag` bytes */
        messageData ~= *(cast(byte*)&tag);
        messageData ~= *(cast(byte*)&tag+1);
        messageData ~= *(cast(byte*)&tag+2);
        messageData ~= *(cast(byte*)&tag+3);
        messageData ~= *(cast(byte*)&tag+4);
        messageData ~= *(cast(byte*)&tag+5);
        messageData ~= *(cast(byte*)&tag+6);
        messageData ~= *(cast(byte*)&tag+7);
        
        /* Add the `data` bytes (the actual message) */
        messageData ~= data;

        return messageData;
    }

    public byte[] getData()
    {
        return data;
    }

    public ulong getTag()
    {
        return tag;
    }
}