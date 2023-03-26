/**
 * Tristanable network message queuing framework
 */
module tristanable;

/**
 * Interface which manages a provided socket
 * and enqueuing and dequeuing of queues
 */
public import tristanable.manager;

// TODO: In future make `QueueItem` just `TaggedMessage`
/**
 * A queue of queue items all of the same tag
 */
public import tristanable.queue : Queue;

/**
 * A decoded item that is placed on the queue
 * for consumption
 */
public import tristanable.queueitem : QueueItem;

/**
 * Error handling type definitions
 */
public import tristanable.exceptions : TristanableException, Error;

/**
 * Encoding/decoding of the tristanable format
 */
public import tristanable.encoding : TaggedMessage;