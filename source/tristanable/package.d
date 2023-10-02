/**
 * Tristanable network message queuing framework
 */
module tristanable;

/**
 * Interface which manages a provided socket
 * and enqueuing and dequeuing of queues
 */
public import tristanable.manager;

/**
 * A queue of queue items all of the same tag
 * and queue-related facilities
 */
public import tristanable.queue.queue : Queue;

/**
 * Error handling type definitions
 */
public import tristanable.exceptions : TristanableException, ErrorType;

/**
 * Encoding/decoding of the tristanable format
 */
public import tristanable.encoding : TaggedMessage;