/**
 * This is mainly intended as a sample callable trigger class.
 * 
 * If we have core trigger functionality we want to span across many SObject types,
 * this the the class to implement it in. 
 *
 * @version 2020-11-17
 * 
 * @author Bill Riemers <briemers@redhat.com>
 * @since 2020-11-17 - Created
 */
public  
without sharing 
class SObjectCallableTrigger
implements Callable
{
    TriggerArguments triggerArguments;

    /**
     * Standard constructor.
     */
    public SObjectCallableTrigger() {}

    /**
     * Copy the ownerId to a custom look-up field.
     *
     * This is a trigger method we use on many object types.
     * So we might as define it here.  This method will only work
     * in before triggers.
     * 
     * It does not make sense to call this method if the SObject does
     * not have both an OwnerId field and a Owner__c field.
     * 
     * @param newList of objects to update
     */
    public static void assignLegacy(List<SObject> newList) {
        for(SObject o : newList) {
            Id ownerId = null;
            String s = String.valueOf(o.get('OwnerId'));
            if(s != null && s.startsWith('005')) {
                ownerId = (Id)s;
            }
            if(ownerId != (Id)o.get('Owner__c') ) {
                o.put('Owner__c',ownerId);
            }
        }
    }

    /**
     * Copy the ownerId to a custom look-up field.
     *
     * This is a trigger method we use on many object types.
     * So we might as define it here.  This method will only work
     * in before triggers.
     * 
     * It does not make sense to call this method if the SObject does
     * not have both an OwnerId field and a Owner__c field.
     */
    public void assignLegacy() {
        if(triggerArguments.isBefore && (triggerArguments.isInsert || triggerArguments.isUpdate)) {
            try {
                assignLegacy(triggerArguments.newList);
            }
            // if the field does not exist, an exception will be thrown
            catch(SObjectException ex) {
                triggerArguments.callableArguments.put('exception',ex);
            } 
        }
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
        if(action.endsWithIgnoreCase('_Before.assignLegacyCallable')) {
            assignLegacy();
        }
        else {
            throw new ExtensionMalformedCallException('Method not implemented');
        }
        return null;
    }

    public class ExtensionMalformedCallException extends Exception {}
}