/**
* NotificationReply
*
* When a tag is reserved and a message is received
* with such a tag then one of these is generated
* and added to the queue of notification replies.
*
* Multiple of these will be made and enqueued even
* if they have the same tag (duplicates allowed).
*
* This facilitates a notification system if one
* wants to use tristanable for that purpose (this
* is because notifications _just happen_ and have
* no prior request)
*/

module tristanable.notifications;

public class NotificationReply
{
	private ulong tag;
	private byte[] data;

	this(ulong tag, byte[] data)
	{
		this.tag = tag;
		this.data = data;
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