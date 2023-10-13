/**
 * Queue type and related facilities
 */
module tristanable.queue;


/**
 * The Queue type for enqueueing and dequeueing messages
 */
public import tristanable.queue.queue : Queue;

/**
 * Interface type for definining listeners which can be hooked
 * to queue actions
 */
public import tristanable.queue.listener : TListener;