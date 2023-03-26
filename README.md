![](branding/logo_small.png)

tristanable
===========

**Tristanable** is a library for D-based libraries and applications that need a way to receive variable-length messages of different types (via a `Socket`) and place these messages into their own respectively tagged queues indicated by their _"type"_ or `id`.

## What problems does it solve?

### Human example

Say now you made a request to a server with a tag `1` and expect a reply with that same tag `1`. Now, for a moment, think about what would happen in a tagless system. You would be expecting a reply, say now the weather report for your area, but what if the server has another thread that writes an instant messenger notification to the server's socket before the weather message is sent? Now you will interpret those bytes as if they were a weather message.

Tristanable provides a way for you to receive the "IM notification first" but block and dequeue (when it arrives in the queue) for the "weather report". Irrespective of wether (no pun intended) the weather report arrives before the "IM notification" or after.

### Code example

If we wanted to implement the following we would do the following. One note is that instead of waiting on messages of a specific _"type"_ (or rather **tag**), tristanable provides not just a one-message length buffer per tag but in fact a full queue per tag, meaning any received message with tag `1` will be enqueued and not dropped after the first message of type `1` is buffered.

```d
import tristanable.manager;
import tristanable.queue;
import tristanable.queueitem;

/* Create a manager to manage the socket for us */
Manager manager = new Manager(socket);

/* Create a Queue for all "weather messages" */
Queue weatherQueue = new Queue(1);

/* Create a Queue for all "IM notifications" */
Queue instantNotification = new Queue(2);

/* Tell the manager to look out for tagged messages `1` and `2` */
manager.addQueue(weatherQueue);
manager.addQueue(instantNotification);

/* Now we can block on this queue and return with its head */
QueueItem message = weatherQueue.dequeue();
```

Surely, there must be some sort of encoding mechanism too? The messages after all need to be encoded. **No problem!**, we have that sorted:

```d
import tristanable.encoding;

/* Let's send it with tag 1 and data "Hello" */
ulong tag = 1;
byte[] data = cast(byte[])"Hello";

/* When sending a message */
DataMessage tristanEncoded = new DataMessage(tag, data);

/* Then send it */
socket.send(encodeForSend(tristanEncoded));
```

And let tristanable handle it! We even handle the message lengths and everything using another great project [bformat](http://deavmi.assigned.network/projects/bformat).

## Format

```
[4 bytes (size-2, little endian)][8 bytes - tag][(2-size) bytes - data]
```

## Using tristanable in your D project
You can easily add the library (source-based) to your project by running the following command in your
project's root:

```bash
dub add tristanable
```