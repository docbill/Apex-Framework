// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * This is a class to invoke triggers in the specified order.  This is intended to be called from a trigger.  A simple implementation
 * would be:
 * 
 * <pre>
 * trigger MyTrigger on MyObject (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
 *     new TriggerManagement().call('MyTrigger',null);
 * }
 * </pre>
 * 
 * Note: The AbstractTrigger method will make this type of call automatically when invoked from a trigger, so there is no need to add this 
 * trigger to standard objects using an AbstractTrigger method calling all the trigger event types you need.
 * 
 * An SObjectCallableTrigger can be referenced as an example of how to write your callable trigger.
 * 
 * If instead you are invoke this from an unlocked package that does not have a depency to include the TriggerManagement class, you can
 * use reflection to implement your trigger and trigger class.   An example of this will be added to the DailyScheduler package.
 * 
 * @version 2021-03-30
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2020-11-12 - Created
 * @since 2020-12-03 - Use BooleanValuesHelper instead of AbstractTrigger for boolean values
 * @since 2021-01-29 - Ignore malformed call exceptions if not in a test class
 * @since 2021-02-11 - Check for custom classes includes __?, not just __c
 * @since 2021-02-11 - Add the callableMap is now added into the callableArguments
 * @since 2021-02-11 - Added lastCaughtException
 * @since 2021-02-14 DE25830 - Read the Boolean Metadata from the correct helper
 * @since 2021-03-03 US286760 - Add support for multiple listeners on a platform event
 * @since 2021-03-30 - Increase test coverage
 */
public without sharing class TriggerManagement implements Callable {
    /** This is a way to reach in and grab the exception from the last DML operation. */
    public static Exception lastRethrownException = null;

    /**
     * Standard constructor.
     */
    public TriggerManagement() {}

    /**
     * Method to invoke all trigger methods on an object.
     */
    public Object call(String action, Map<String, Object> args) {
        lastRethrownException = null;
        switch on action {
            when null,'','AbstractTrigger' {
                action = getUniqueTriggerString(action);
            }
        }
        if(String.isBlank(action)) {
            throw new ExtensionMalformedCallException('Method not implemented');
        }
        if(! BooleanValuesHelper.getBooleanValue('DeactivateAll',false)) {
            //System.debug('Trigger Management entered '+action);
            TriggerArguments localTrigger = new TriggerArguments(args);
            String queryString = createQueryString(action,localTrigger);
            if(queryString != null) {
                String key = localTrigger.targetObjectType+':'+queryString;
                String lastAction = lastActionMap.get(key);
                //System.debug('TriggerManagement qAction='+lastAction+', action='+action);
                if(lastAction == null || action.equals(lastAction) ) {
                    lastActionMap.put(key,action);
                    List<Trigger_Management_Entry__mdt> entries = queryEntriesByEntity(queryString,localTrigger.targetObjectType);
                    callTriggerMethods(entries,localTrigger);
                }
            }
        }
        return null;
    }

    // We need to account for the fact that abstract trigger classes are often subclassed.
    // So we use the stack trace to determine a unique action name, based on where
    // we were called from.
    @TestVisible
    static String getUniqueTriggerString(String retval) {
        try {
            Integer.valueOf('false');
        }
        catch(Exception ex) {
            String stackTraceString = ex.getStackTraceString()+'\n';
            String triggerName = stackTraceString.substringBetween('\nTrigger.', '\n');
            if(String.isNotBlank(triggerName)) {
                String s = '\nTrigger.'+triggerName;
                retval = stackTraceString.substringBetween('\n',s).substringAfter('\n')+s; 
            }
        }
        return retval;
    }

    // For each entry, create the callable class, and invoke it with the specified MasterLabel as the action.
    static void callTriggerMethods(List<Trigger_Management_Entry__mdt> entries,TriggerArguments localTrigger) {
        //System.debug('TriggerManagement entries='+entries);
        if(entries != null) {
            Map<String,Object> callableArguments = localTrigger.callableArguments;
            Map<String,Callable> callableMap = localTrigger.callableMap;
            for(Trigger_Management_Entry__mdt entry : entries ) {
                //System.debug('TriggerManagement entry.MasterLabel='+entry.MasterLabel);
                if(BooleanValuesHelper.getBooleanValue(entry.MasterLabel,true)) {
                    callTrigger(callableMap,entry,callableArguments);
                }
            }
        }
    }

    @TestVisible
    static Boolean getValueFromMetadata(String name,Boolean defaultValue) {
        // clear any previous settings to make sure we read metadata
        BooleanValuesHelper.booleanSettingMap.remove(name);
        BooleanValuesHelper.overrideSettingMap.remove(name);
        return BooleanValuesHelper.getBooleanValue(name,defaultValue,false);
    }

    @TestVisible
    static void callTrigger(
        Map<String,Callable> callableMap,
        Trigger_Management_Entry__mdt entry,
        Map<String,Object> callableArguments
    ) {
        lastRethrownException=null;
        try {
            //System.debug('TriggerManagement entry.Class_Name__c='+entry.Class_Name__c);
            Callable c = callableMap.get(entry.Class_Name__c);
            if(c == null) {
                c = (Callable)Type.forName(entry.Class_Name__c).newInstance();
                callableMap.put(entry.Class_Name__c,c);
            }
            callTrigger(c,entry.MasterLabel,callableArguments);
        }
        catch(Exception ex) {
            lastRethrownException=ex;
            throw ex;
        }
    }

    @TestVisible
    static void callTrigger(
        Callable c, 
        String action, 
        Map<String,Object> callableArguments
    ) {
        try {
            //System.debug('TriggerManagement new '+entry.Class_Name__c+'().call('+entry.MasterLabel+',args);');
            c.call(action,callableArguments);
        }
        catch(Exception ex) {
            if(! String.valueOf(ex).substringBefore(':').endsWithIgnoreCase('ExtensionMalformedCallException')) {
                throw ex;
            }
            Boolean needsRethrow = Test.isRunningTest() && getValueFromMetadata(action,false);
            // make sure we don't call this action again
            BooleanValuesHelper.booleanSettingMap.put(action,false);
            BooleanValuesHelper.overrideSettingMap.put(action,false);
            // do not store this value for automatic addition into the metadata
            if(BooleanValuesHelper.missingMap != null) {
                BooleanValuesHelper.missingMap.remove(action);
            }
            System.debug(System.LoggingLevel.ERROR,'Invalid call: '+ex);
            if(needsRethrow) {
                throw ex;
            }
        }
    }

    // Once we invoke triggers, we keep track of that action and only repeat the same set of trigger methods
    // for the same action.  This way we can have many triggers on the same object, and still only fire each trigger
    // once.
    static Map<String,String> lastActionMap = new Map<String,String>();

    // Once we query the metadata, we put it into a list based on query string and target object name.
    static Map<String,Map<String,List<Trigger_Management_Entry__mdt>>> entriesMapMap = new Map<String,Map<String,List<Trigger_Management_Entry__mdt>>>();

    // query all the entries and return the ones relevant to the target object.
    static List<Trigger_Management_Entry__mdt> queryEntriesByEntity(String queryString,String targetObjectType) {
        //System.debug('TriggerManagement targetObjectType='+targetObjectType);
        Map<String,List<Trigger_Management_Entry__mdt>> entriesMap = entriesMapMap.get(queryString);
        if(entriesMap == null) {
            entriesMap = new Map<String,List<Trigger_Management_Entry__mdt>>();
            entriesMapMap.put(queryString,entriesMap);
            for(Trigger_Management_Entry__mdt entry : (List<Trigger_Management_Entry__mdt>)Database.query(queryString)) {
                Set<String> targetObjectTypes = (new Set<String>{ entry.Non_Entity_Object__c } );
                if(entry.Entity_Object__r != null) {
                    targetObjectTypes.add(entry.Entity_Object__r.QualifiedApiName);
                }
                targetObjectTypes.remove(null);
                for(String value : targetObjectTypes) {
                    value = value.toLowerCase();
                    List<Trigger_Management_Entry__mdt>  entries = entriesMap.get(value);
                    if(entries == null) {
                        entries = new List<Trigger_Management_Entry__mdt>();
                        entriesMap.put(value,entries);
                    }
                    entries.add(entry);
                }
            }
        }
        return entriesMap.get(targetObjectType.toLowerCase());
    }

    @TestVisible
    static Map<TriggerArguments.TriggerType,Schema.SObjectField> triggerFieldMap = (new Map<TriggerArguments.TriggerType,Schema.SObjectField>{
        TriggerArguments.TriggerType.BEFORE_INSERT => Trigger_Management_Entry__mdt.Before_Insert__c,
        TriggerArguments.TriggerType.AFTER_INSERT => Trigger_Management_Entry__mdt.After_Insert__c,
        TriggerArguments.TriggerType.BEFORE_UPDATE => Trigger_Management_Entry__mdt.Before_Update__c,
        TriggerArguments.TriggerType.AFTER_UPDATE => Trigger_Management_Entry__mdt.After_Update__c,
        TriggerArguments.TriggerType.BEFORE_DELETE => Trigger_Management_Entry__mdt.Before_Delete__c,
        TriggerArguments.TriggerType.AFTER_DELETE => Trigger_Management_Entry__mdt.After_Delete__c,
        TriggerArguments.TriggerType.AFTER_UNDELETE => Trigger_Management_Entry__mdt.After_Undelete__c
    } );


    // dynamically generate the query string based on the trigger arguments
    @TestVisible
    static String createQueryString(String action,TriggerArguments localTrigger) {
        String queryString = null;
        //System.debug('localTrigger.targetObjectType='+localTrigger.targetObjectType);
        if(String.isNotBlank(localTrigger.targetObjectType)) {
            final Schema.SObjectField triggerField = triggerFieldMap.get(localTrigger.triggerTypeValue);
            //System.debug('TriggerManagement triggerField='+triggerField);
            if(triggerField != null) {
                final String nonEntityValue = getNonEntityValue( localTrigger.targetObjectType );
                final String entityObjectFieldName = Trigger_Management_Entry__mdt.Entity_Object__c.getDescribe().getName();
                final String entityBasedCondition = getEntityBasedCondition(
                    nonEntityValue,
                    localTrigger.targetObjectType,
                    entityObjectFieldName,
                    action );
                queryString = 'select MasterLabel,'
                    + Trigger_Management_Entry__mdt.Class_Name__c.getDescribe().getName()+','
                    + entityObjectFieldName.replace('__c','__r.QualifiedApiName')+','
                    + Trigger_Management_Entry__mdt.Non_Entity_Object__c.getDescribe().getName()+','
                    + Trigger_Management_Entry__mdt.Sequence_Number__c.getDescribe().getName()+','
                    + 'DeveloperName'
                    + ' from '+Trigger_Management_Entry__mdt.SObjectType.getDescribe().getName()
                    + ' where '+triggerfield.getDescribe().getName()+'=true'
                    + entityBasedCondition
                    + ' and '+Trigger_Management_Entry__mdt.Non_Entity_Object__c.getDescribe().getName() + '='+quoteValue(nonEntityValue)
                    + ' order by '+Trigger_Management_Entry__mdt.Sequence_Number__c.getDescribe().getName();
            }
        }
        //System.debug('TriggerManagement queryString='+queryString);
        return queryString;
    }

    @TestVisible
    static String getEntityBasedCondition(
        String nonEntityValue,
        String targetObjectType,
        String entityObjectFieldName,
        String action )
    {
        String entityBasedCondition = '';
        if(nonEntityValue == null) {
            String suffix = targetObjectType.right(3);
            // An entity condition would always fail for custom objects.
            // So instead we'll have to accept all entities for custom objects and filter later.
            if(! suffix.startsWith('__')) {
                entityBasedCondition = ' and '
                    + entityObjectFieldName
                    + '='+quoteValue(targetObjectType.toUpperCase());
            }
            // if this is a platform event we'll filter on the master label
            // because we allow more than one trigger per object, because
            // each represents a separate listener
            else if(suffix == '__e') {
                entityBasedCondition = ' and MasterLabel like '
                    + quoteValue(action.toUpperCase()+'.%');
            }
        }
        return entityBasedCondition;
    }

    static String quoteValue(String value) {
        if(value != null) {
            value = '\''+String.escapeSingleQuotes(value)+'\'';
        }
        return value;
    }

    static Set<String> nonEntities {
        get {
            if(nonEntities == null) {
                nonEntities = new Set<String>();
                final Schema.DescribeFieldResult dfr = Trigger_Management_Entry__mdt.Non_Entity_Object__c.getDescribe();
                final String fieldName = dfr.getName();
                for(Schema.PicklistEntry entry : dfr.getPicklistValues()) {
                    if(entry.isActive()) {
                        nonEntities.add(entry.getValue().toUpperCase());
                    }
                }
            }
            return nonEntities;
        }
        set;
    }

    @TestVisible
    static String getNonEntityValue(String objectType) {
        String retval = objectType.toUpperCase();
        if(! nonEntities.contains(retval)) {
            retval = null;
        }
        return retval;
    }

    public class ExtensionMalformedCallException extends Exception {}
}
