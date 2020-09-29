module tristanable.queueitem;

public final class QueueItem
{
	/* This item's data */
	private byte[] data;
	
	/* TODO: */
	this(byte[] data)
	{
		this.data = data;
	}

	public byte[] getData()
	{
		return data;
	}
}