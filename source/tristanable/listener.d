module tristanable.listener;

// TODO: Implement me

import tristanable.queue;
import tristanable.encoding;

public interface TListener
{
    // TODO: See if this is all we need / what we want
    public void onQueueReceive(Queue queue, TaggedMessage message);
}