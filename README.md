![](https://code.dlang.org/packages/tristanable/logo?s=5ef1c9f1250f57dd4c37efbf)

tristanable
===========

**Tristanable** is a library for D-based libraries and applications that need a way to receive variable-length messages of different types (via a `Socket`) and place these messages into their own resepctively tagged queues indicated by their _"type"_ or `id`.

## What problems does it solve?

### Human example

Say now you made a request to a server with a tag `1` and expect a reply with that same tag `1`. Now, for a moment, think about what would happen in a tagless system. You would be expecting a reply, say now the weather report for your area, but what if the server has another thread that writes an instant messenger notification to the server's socket before the weather message is sent? Now you will inetrpret those bytes as if they were a weather message.

Tristanable provides a way for you to receive the "IM notification first" but block and dequeue (when it arrives in the queue) for the "weather report". Irresepctoive of wether (no pun intended) the weather report arrives before the "IM notification" or after.

### Code example

If we wanted to implement the following we would do the following. One note is that instead of waiting on messages of a specific _"type"_ (or rather **tag**), tristanable provides not just a one-message lengthb uffer per tag but infact a full queue per tag, meaning any received message with tag `1` will be enqueued and not dropped after the first message of type `1` is buffered.

```d
/* Create a manager to manage the socket for us */
Manager manager = new Manager(socket);

/* Create a Queue for all "weather messages" */
Queue weatherQueue = new Queue(1);

/* Create a Queue for all "IM notifications" */
Queue instantNotification = new Queue(2);

/* Tell the manager to look out for tagged messages `1` and `2` */
manager.addQueue(weatherQueue);
manager.addQueue(instantNotification);
```


However, you want to read these off of a socket and act accordi

## Usage

The entry point is via the `Manager` type, so first create an instance as follows (passing the endpoint `Socket` in as `socket` in this example):

```d
Manager manager = new Manager(socket);
```

Now the event loop would have started, now we are ready to send out some tagged messages and blocking receive for them!

Let's send out two messages with tags `1` and `2`:

```d
manager.sendMessage(1, [1,2,3,4,5]);
manager.sendMessage(2, [6,7,8,9,0]);
```

Now we can start two seperate threads and wait on them both:

```d
byte[] receivedData = manager.receiveMessage(1);
```

```d
byte[] receivedData = manager.receiveMessage(2);
```

**TODO**

## Format

```
[4 bytes (size-2, little endian)][8 bytes - tag][(2-size) bytes - data]
```

## Acknowledgements

Thansk to Gabby Smuts for the name suggestion 😉️