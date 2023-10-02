![](branding/logo_small.png)

tristanable
===========

[![D](https://github.com/deavmi/tristanable/actions/workflows/d.yml/badge.svg)](https://github.com/deavmi/tristanable/actions/workflows/d.yml) ![DUB](https://img.shields.io/dub/v/tristanable?color=%23c10000ff%20&style=flat-square) ![DUB](https://img.shields.io/dub/dt/tristanable?style=flat-square) ![DUB](https://img.shields.io/dub/l/tristanable?style=flat-square) [![Coverage Status](https://coveralls.io/repos/github/deavmi/tristanable/badge.svg?branch=master)](https://coveralls.io/github/deavmi/tristanable?branch=master)


**Tristanable** is a library for D-based libraries and applications that need a way to receive variable-length messages of different types (via a `Socket`) and place these messages into their own respectively tagged queues indicated by their _"type"_ or `id`.

## What problems does it solve?

### Human example

Say now you made a request to a server with a tag `1` and expect a reply with that same tag `1`. Now, for a moment, think about what would happen in a tagless system. You would be expecting a reply, say now the weather report for your area, but what if the server has another thread that writes an instant messenger notification to the server's socket before the weather message is sent? Now you will interpret those bytes as if they were a weather message.

Tristanable provides a way for you to receive the "IM notification first" but block and dequeue (when it arrives in the queue) for the "weather report". Irrespective of wether (no pun intended) the weather report arrives before the "IM notification" or after.

### Code example

Below is a fully-fledged example of the types of places (networking) where tristanable can be of help. The code is all explained in the comments:

```d
import std.socket;
import std.stdio;
import core.thread;

Address serverAddress = parseAddress("::1", 0);
Socket server = new Socket(AddressFamily.INET6, SocketType.STREAM, ProtocolType.TCP);
server.bind(serverAddress);
server.listen(0);

class ServerThread : Thread
{
    this()
    {
        super(&worker);
    }

    private void worker()
    {
        Socket clientSocket = server.accept();
        BClient bClient = new BClient(clientSocket);

        Thread.sleep(dur!("seconds")(7));
        writeln("Server start");

        /** 
            * Create a tagged message to send
            *
            * tag 42 payload Cucumber 😳️
            */
        TaggedMessage message = new TaggedMessage(42, cast(byte[])"Cucumber 😳️");
        byte[] tEncoded = message.encode();
        writeln("server send status: ", bClient.sendMessage(tEncoded));

        writeln("server send [done]");

        /** 
            * Create a tagged message to send
            *
            * tag 69 payload Hello
            */
        message = new TaggedMessage(69, cast(byte[])"Hello");
        tEncoded = message.encode();
        writeln("server send status: ", bClient.sendMessage(tEncoded));

        writeln("server send [done]");

        /** 
            * Create a tagged message to send
            *
            * tag 69 payload Bye
            */
        message = new TaggedMessage(69, cast(byte[])"Bye");
        tEncoded = message.encode();
        writeln("server send status: ", bClient.sendMessage(tEncoded));

        writeln("server send [done]");

        /** 
            * Create a tagged message to send
            *
            * tag 100 payload Bye
            */
        message = new TaggedMessage(100, cast(byte[])"DEFQUEUE_1");
        tEncoded = message.encode();
        writeln("server send status: ", bClient.sendMessage(tEncoded));

        writeln("server send [done]");

        /** 
            * Create a tagged message to send
            *
            * tag 200 payload Bye
            */
        message = new TaggedMessage(200, cast(byte[])"DEFQUEUE_2");
        tEncoded = message.encode();
        writeln("server send status: ", bClient.sendMessage(tEncoded));

        writeln("server send [done]");
    }
}

ServerThread serverThread = new ServerThread();
serverThread.start();

Socket client = new Socket(AddressFamily.INET6, SocketType.STREAM, ProtocolType.TCP);

writeln(server.localAddress);


Manager manager = new Manager(client);

Queue sixtyNine = new Queue(69);
Queue fortyTwo = new Queue(42);

manager.registerQueue(sixtyNine);
manager.registerQueue(fortyTwo);

// Register a default queue (tag ignored)
Queue defaultQueue = new Queue(2332);
manager.setDefaultQueue(defaultQueue);


/* Connect our socket to the server */
client.connect(server.localAddress);

/* Start the manager and let it manage the socket */
manager.start();

/* Block on the unittest thread for a received message */
writeln("unittest thread: Dequeue() blocking...");
TaggedMessage dequeuedMessage = sixtyNine.dequeue();
writeln("unittest thread: Got '"~dequeuedMessage.toString()~"' decode payload to string '"~cast(string)dequeuedMessage.getPayload()~"'");
assert(dequeuedMessage.getTag() == 69);
assert(dequeuedMessage.getPayload() == cast(byte[])"Hello");

/* Block on the unittest thread for a received message */
writeln("unittest thread: Dequeue() blocking...");
dequeuedMessage = sixtyNine.dequeue();
writeln("unittest thread: Got '"~dequeuedMessage.toString()~"' decode payload to string '"~cast(string)dequeuedMessage.getPayload()~"'");
assert(dequeuedMessage.getTag() == 69);
assert(dequeuedMessage.getPayload() == cast(byte[])"Bye");

/* Block on the unittest thread for a received message */
writeln("unittest thread: Dequeue() blocking...");
dequeuedMessage = fortyTwo.dequeue();
writeln("unittest thread: Got '"~dequeuedMessage.toString()~"' decode payload to string '"~cast(string)dequeuedMessage.getPayload()~"'");
assert(dequeuedMessage.getTag() == 42);
assert(dequeuedMessage.getPayload() == cast(byte[])"Cucumber 😳️");


/* Dequeue two messages from the default queue */
writeln("unittest thread: Dequeue() blocking...");
dequeuedMessage = defaultQueue.dequeue();
writeln("unittest thread: Got '"~dequeuedMessage.toString()~"' decode payload to string '"~cast(string)dequeuedMessage.getPayload()~"'");
assert(dequeuedMessage.getTag() == 100);
assert(dequeuedMessage.getPayload() == cast(byte[])"DEFQUEUE_1");

writeln("unittest thread: Dequeue() blocking...");
dequeuedMessage = defaultQueue.dequeue();
writeln("unittest thread: Got '"~dequeuedMessage.toString()~"' decode payload to string '"~cast(string)dequeuedMessage.getPayload()~"'");
assert(dequeuedMessage.getTag() == 200);
assert(dequeuedMessage.getPayload() == cast(byte[])"DEFQUEUE_2");


/* Stop the manager */
manager.stop();
```

And let tristanable handle it! We even handle the message lengths and everything using another great project [bformat](https://deavmi.assigned.network/projects/bformat).

## Format

```
[4 bytes (size-2, little endian)][8 bytes - tag][(2-size) bytes - data]
```

## Using tristanable in your D project

You can easily add the library (source-based) to your project by running the following command in your project's root:

```bash
dub add tristanable
```
