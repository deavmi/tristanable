module tristanable.exceptions;

import tristanable.manager;
import tristanable.queue : Queue;

public class TristanableException : Exception
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

/**
* Thrown in relation to problems whereby the Manager is
* at fault, i.e. whereby it may have had a socket die
*/
public final class ManagerError : TristanableException
{
    this(Manager man, string msg)
    {
        super(man, msg);
    }
}