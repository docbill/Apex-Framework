// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * @description
 * This is mainly intended as a sample callable trigger class.  In this case it is a
 * trigger we can assign to any SObject to copy the standard field, OwnerId, to a 
 * custom field, Owner__c.  This is useful if you want to follow the lookup onto the 
 * owner record in queries and such.
 * <br /><br />
 * 
 * If we have core trigger functionality we want to span across many SObject types,
 * this the the class to implement it in. 
 *
 * @group ApexFramework
 * 
 * @author Bill Riemers <briemers@redhat.com>
 * @since 2020-11-17 - Created
 * @since 2022-09-09 update for ApexDox commenting
 */
public without sharing class SObjectCallableTrigger implements Callable {

    private TriggerArguments triggerArguments;

    /**
     * @description
     * Standard constructor.
     */
    public SObjectCallableTrigger() {}

    /**
     * @description
     * Copy the ownerId to a custom look-up field.
     * <br /><br />
     *
     * This is a trigger method we use on many object types.
     * So we might as define it here.  This method will only work
     * in before triggers.
     * <br /><br />
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
     * @description
     * Copy the ownerId to a custom look-up field.
     * <br /><br />
     *
     * This is a trigger method we use on many object types.
     * So we might as define it here.  This method will only work
     * in before triggers.
     * <br /><br />
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
     * @description
     * This is the callable method to invoke the triggers in this class.
     * <br /><br />
     * 
     * @param action the trigger method to invoke
     * @param args a map of Trigger values
     * @return null
     */
    public Object call(String action, Map<String,Object> args) {
        triggerArguments = new TriggerArguments(args);
        switch on (''+action).substringAfterLast('.') {
            when 'assignLegacyCallable' {
                assignLegacy();
            }
            when else {
                throw new ExtensionMalformedCallException('Method not implemented');
            }
        }
        return null;
    }

    /**
     * @description
     * This exception is part of the best practices for classes implementing Callable.
     */
    public class ExtensionMalformedCallException extends Exception {}
}