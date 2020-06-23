tristanable
===========

Tag-based asynchronous messaging framework

## Usage

The entry point is via the `Manager` type, so first create an instance as follows (passing the endpoint `Socket` in as `socket` in this example)

```d
Manager manager = new Manager(socket);
```

Now the event loop would have started.

**TODO**

## Format

```
[4 bytes (size-2, little endian)][8 bytes - tag][(2-size) bytes - data]
```

## Acknowledgements

Thansk to Gabby Smuts for the name suggestion 😉️