/**
 * This is a special trigger used to prevent code from being being called twice,
 * unless an error was set.  This respective code is expected to use thread locking as follows:
 * 
 * <pre>
 *  String lockKey = ThreadLockCallableTrigger.getThreadLockKEY(<MY UNIQUE KEY>,triggerArguments);
 *  if(ThreadLock.lock(lockKey)) {
 *  	try {
 * 			// do some work
 * 		}
 * 		finally {
 * 			ThreadLock.unlock(lockKey);
 *  	}
 *  }
 * </pre>
 * 
 * The name of this trigger should be the the value of <MY UNIQUE KEY> appended with '.lock'.
 * A null may be passed as triggerArguments, if there is no triggerArguments available.
 *
 * @version 2021-07-16
 * 
 * @author Bill Riemers <briemers@redhat.com>
 * @since 2021-07-16 - Created
 */
public  
without sharing 
class ThreadLockCallableTrigger
implements Callable
{
    TriggerArguments triggerArguments;

    /**
     * Standard constructor.
     */
    public ThreadLockCallableTrigger() {}

    private static Set<String> firstCalledSet = new Set<String>();

    /**
     * Called to get a unique string to lock this a trigger.
     * 
     * @param action name of the trigger such as 'Opp_Before.updateProducts'
     * @param triggerArguments passing a null is equivalent to passing new TriggerArguments(null)
     */
    public static String getThreadLockKey(String action,TriggerArguments triggerArguments) {
        if(triggerArguments == null) {
            triggerArguments = new TriggerArguments(null);
        }
        return action
            +','+triggerArguments.isBefore
            +','+triggerArguments.isUpdate
            +','+triggerArguments.isDelete
            +','+triggerArguments.isUndelete;
    }

    /**
     * This method will check if a there are no records in error, and if so lock the thread for
     * the respective action.
     * 
     * @param action name of trigger to lock
     */
    @TestVisible
    private void threadLock(String action) {
        if(firstCalledSet.contains(action)) {
            List<SObject> recordList = triggerArguments.oldList;
            if(triggerArguments.newList != null && ! triggerArguments.newList.isEmpty()) {
                recordList = triggerArguments.newList;
            }
            if(recordList != null) {
                for(SObject record : recordList) {
                    if(record.hasErrors()) { return; }
                }
                String key = getThreadLockKey(action,triggerArguments);
                ThreadLock.lock(key);
            }
        }
        firstCalledSet.add(action);
    }

    /**
     * This is the callable method to invoke the triggers in this class.
     * 
     * @param action the trigger method to invoke
     * @param args a map of Trigger values
     */
    public Object call(String action, Map<String,Object> args) {
        action = ''+action; // just to avoid null exceptions
        triggerArguments = new TriggerArguments(args);
        final String lockedAction = getLockedAction(action);
        if(lockedAction != null) {
            threadLock(lockedAction);
        }
        else {
            throw new ExtensionMalformedCallException('Method not implemented');
        }
        return null;
    }

    static String getLockedAction(String action) {
        for(String suffix : new List<String>{'.lock','!'}) {
            if(action.endsWithIgnoreCase(suffix)) {
                return action.left(action.length()-suffix.length());
            }
        }
        return null;
    }

    public class ExtensionMalformedCallException extends Exception {}
}