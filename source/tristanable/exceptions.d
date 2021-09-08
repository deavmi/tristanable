module tristanable.exceptions;

import tristanable.manager;
import tristanable.queue : Queue;

public final class TristanableException : Exception
{
    this(Manager manager, string message)
    {
        super(generateMessage(message));
    }

    private string generateMessage(string errMesg)
    {
        string msg;

        // msg = "TRistanable failure: "~errMesg~"\n\n";
        // msg ~= "Queue stats:\n\n"

        // Queue[] queues = manager.getQueues();
        // foreach(Queue queue; queues)
        // {
        //     msg ~= "Queue["~to!(string)(queue.getTag())~"]: "~
        // }
        //  msg ~= manager.getQueues()

        return msg;
    }
}