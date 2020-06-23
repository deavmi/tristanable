tristanable
===========

Tag-based asynchronous messaging framework

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

**TODO**

## Format

```
[4 bytes (size-2, little endian)][8 bytes - tag][(2-size) bytes - data]
```

## Acknowledgements

Thansk to Gabby Smuts for the name suggestion 😉️