/** 
 * Configuration for the manager
 */
module tristanable.manager.config;

/** 
 * Manager parameters
 */
public struct Config
{
    /** 
     * If set to true then when one uses
     * `sendMessage(TaggedMessage)` the
     * manager will check if a queue with
     * said tag has not been registered
     * and if so, then register it for
     * us before encoding-and-sending
     */
    public bool registerOnSend = false;
}

/** 
 * Generates the default configuration to use for
 * the manager
 *
 * Returns: the Config
 */
public Config defaultConfig()
{
    return Config();
}