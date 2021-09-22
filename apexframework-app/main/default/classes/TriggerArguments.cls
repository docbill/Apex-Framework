// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * This is a class to convert callable arguments into trigger values.
 * 
 * All values are assigned in the constructor as final.
 * 
 * The following are minimum arguments key sets for the arguments of the triggers:
 * 
 * <pre>
 * before insert : { NEW_LIST_KEY }
 * before update : { OLD_MAP_KEY, NEW_LIST_KEY }
 * before delete : { OLD_MAP_KEY, IS_BEFORE_KEY }
 * after insert : { NEW_MAP_KEY }
 * after update : { OLD_MAP_KEY, NEW_MAP_KEY }
 * after delete : { OLD_MAP_KEY, IS_BEFORE_KEY }
 * after undelete : { NEW_MAP_KEY, IS_UNDELETE_KEY }
 * </pre>
 * 
 * Given the minimal sets, the rest of the values will be populated for each of
 * the trigger types.  In general never supply NEW_MAP_KEY for a before trigger
 * without specifing the IS_BEFORE_KEY or IS_AFTER_KEY.   Never provide NEW_LIST_KEY
 * in an after trigger, without also supplying IS_BEFORE_KEY or IS_AFTER_KEY.
 * 
 * @version 2020-11-12
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2020-11-12 Created
 */
public without sharing class TriggerArguments {
    public static final String IS_BEFORE_KEY = 'isBefore';
    public static final String IS_AFTER_KEY = 'isAfter';
    public static final String IS_INSERT_KEY = 'isInsert';
    public static final String IS_UPDATE_KEY = 'isUpdate';
    public static final String IS_DELETE_KEY = 'isDelete';
    public static final String IS_UNDELETE_KEY = 'isUndelete';
    public static final String NEW_LIST_KEY = 'new';
    public static final String NEW_MAP_KEY = 'newMap';
    public static final String OLD_LIST_KEY = 'old';
    public static final String OLD_MAP_KEY = 'oldMap';
    public static final String TARGET_OBJECT_TYPE_KEY = 'targetObjectType';
    public static final String CALLABLE_MAP = 'callableMap';

    public Enum TriggerType { BEFORE_INSERT, AFTER_INSERT, BEFORE_UPDATE, AFTER_UPDATE, BEFORE_DELETE, AFTER_DELETE, AFTER_UNDELETE }

    /** 
     * The map of arguments representing Trigger that can be passed to a Callable trigger class.
     */
    public final Map<String,Object> callableArguments {
        get;
        set {
            if(value == null) {
                value = new Map<String,Object>();
            }
            callableArguments = value;
        }
    }

    /** 
     * IS_BEFORE_KEY value from the callable arguments map.
     */
    public final Boolean isBefore {
        get;
        set {
            if(value == null) {
                // Before and After update look the same in terms of lists.  So 
                // our convention is to assume it is a before if a newMap entry not
                // explicitly supplied.
                Boolean isAfter = (Boolean)callableArguments.get(IS_AFTER_KEY);
                Boolean isUndelete = (Boolean)callableArguments.get(IS_UNDELETE_KEY);
                value = ! (isAfter == true || isUndelete == true);
                if(isAfter == null && isUndelete != true) {
                    // It would be better to pass the isBefore value rather than relying on this logic...
                    Integer newListSizeScore = getSizeScore(NEW_LIST_KEY);
                    Integer newMapSizeScore = getSizeScore(NEW_MAP_KEY);
                    value = (newMapSizeScore < newListSizeScore);
                }
            }
            callableArguments.put(IS_BEFORE_KEY,value);
            isBefore = value;
        }
    }

    /** 
     * IS_AFTER_KEY value from the callable arguments map.
     */
    public final Boolean isAfter {
        get;
        set {
            if(value == null) {
                value = ! isBefore;
            }
            callableArguments.put(IS_AFTER_KEY,value);
            isAfter = value;
        }
    }

    /** 
     * NEW_LIST_KEY value from the callable arguments map.
     */
    public final List<SObject> newList {
        get;
        set {
            callableArguments.put(NEW_LIST_KEY,value);
            newList = value;
        }
    }

    /** 
     * NEW_MAP_KEY value from the callable arguments map.
     */
    public final Map<Id,SObject> newMap  {
        get;
        set {
            callableArguments.put(NEW_MAP_KEY,value);
            newMap = value;
        }
    }

    /** 
     * OLD_LIST_KEY value from the callable arguments map.
     */
    public final List<SObject> oldList {
        get;
        set {
            callableArguments.put(OLD_LIST_KEY,value);
            oldList = value;
        }
    }

    /** 
     * OLD_MAP_KEY value from the callable arguments map.
     */
    public final Map<Id,SObject> oldMap {
        get;
        set {
            callableArguments.put(OLD_MAP_KEY,value);
            oldMap = value;
        }
    }

    /** 
     * IS_UPDATE_KEY value from the callable arguments map.
     */
    public final Boolean isUpdate {
        get;
        set {
            if(value == null) {
                value = (true != (Boolean)callableArguments.get(IS_DELETE_KEY))
                    && (true != (Boolean)callableArguments.get(IS_UNDELETE_KEY))
                    && (true != (Boolean)callableArguments.get(IS_INSERT_KEY)) 
                    && (oldMap != null && ! oldMap.isEmpty())
                    && (newMap != null && ! newMap.isEmpty());
            }
            callableArguments.put(IS_UPDATE_KEY,value);
            isUpdate = value;
        }
    }

    /** 
     * IS_INSERT_KEY value from the callable arguments map.
     */
    public final Boolean isInsert {
        get;
        set {
            if(value == null) {
                // We cannot tell the difference between an after insert
                // or an after undelete, unless either the isInsert or isUndelete flag
                // is set.  Our default is to assume insert, as that is more common.
                value = (! isUpdate)
                    && (true != (Boolean)callableArguments.get(IS_UNDELETE_KEY))
                    && (true != (Boolean)callableArguments.get(IS_DELETE_KEY)) 
                    && (oldList == null || oldList.isEmpty())
                    && (newList != null && ! newList.isEmpty())
                    && (isBefore == (newMap == null || newMap.isEmpty()));
            }
            callableArguments.put(IS_INSERT_KEY,value);
            isInsert = value;
        }
    }

    /** 
     * IS_DELETE_KEY value from the callable arguments map.
     */
    public final Boolean isDelete {
        get;
        set {
            if(value == null) {
                value = (! isUpdate) 
                    && (! isInsert)
                    && (true != (Boolean)callableArguments.get(IS_UNDELETE_KEY))
                    && (newList == null || newList.isEmpty())
                    && (oldMap != null && ! oldMap.isEmpty());
            }
            callableArguments.put(IS_DELETE_KEY,value);
            isDelete = value;
        }
    }

    /** 
     * IS_UNDELETE_KEY value from the callable arguments map.
     */
    public final Boolean isUndelete {
        get;
        set {
            if(value == null) {
                value = isAfter
                    && (! isUpdate)
                    && (! isInsert)
                    && (! isDelete)
                    && (oldList == null || oldList.isEmpty())
                    && (newMap != null && ! newMap.isEmpty());
            }
            callableArguments.put(IS_UNDELETE_KEY,value);
            isUndelete = value;
        }
    }

    /**
     * TARGET_OBJECT_KEY value from the callabse arguments map.
     */
    public final String targetObjectType {
        get;
        set {
            if(value == null) {
                List<SObject> objList = newList;
                if(objList == null || objList.isEmpty()) {
                    objList = oldList;
                }
                if(objList != null && ! objList.isEmpty()) {
                    value = objList[0].getSObjectType().getDescribe().getName();
                }
            }
            callableArguments.put(TARGET_OBJECT_TYPE_KEY,value);
            targetObjectType = value;
        }
    }

    /**
     * The trigger type of this call.
     */
    public final TriggerType triggerTypeValue;

    /** 
     * The map of all callable triggers called so far as part of the current DML
     * operation.
     */
    public final Map<String,Callable> callableMap {
        get;
        set {
            if(value == null) {
                value = new Map<String,Callable>();
            }
            callableArguments.put(CALLABLE_MAP,value);
            callableMap = value;
        } 
    }

    /**
     * Constructor.  A null or empty value will construct using Trigger values.
     * 
     * @param callableArguments map of trigger values, or null
     */
    public TriggerArguments(Map<String,Object> callableArguments) {
        this.callableArguments = callableArguments;
        final Boolean useMap = ! this.callableArguments.isEmpty();
        this.isBefore = (Boolean)lookupValue(useMap,IS_BEFORE_KEY,Trigger.isBefore);
        this.isAfter = (Boolean)lookupValue(useMap,IS_AFTER_KEY,Trigger.isAfter);
        if(useMap) {
            // The following is useful for test classes and non-dependent packages.
            // If the caller manually assigned the arguments map, we don't assume it is correct.
            // Instead we'll auto derive any missing values and attempt to normalise to consistent
            // values.
            Map<Id,SObject> newMap = (Map<Id,SObject>)this.callableArguments.get(NEW_MAP_KEY);
            Map<Id,SObject> oldMap = (Map<Id,SObject>)this.callableArguments.get(OLD_MAP_KEY);

            // the order of these calls matter
            // create a newList from the oldMap
            this.newList = getSObjectList(NEW_LIST_KEY,newMap); // references this.callableArguments
            // create an oldList from the newMap
            this.oldList = getSObjectList(OLD_LIST_KEY,oldMap);  // references this.callableArguments
            // when needed, use the oldMap and newList to create a newMap
            this.newMap = getSObjectMap(newMap,oldMap,this.newList); 
            // when needed, use the newMap and oldList to create an oldMap
            this.oldMap = getSObjectMap(oldMap,newMap,this.oldList);
        }
        else {
            // 99% of the time this is the code we use from a trigger
            this.newList = Trigger.new;
            this.newMap = Trigger.newMap;
            this.oldList = Trigger.old;
            this.oldMap = Trigger.oldMap;
        }
        this.isUpdate = (Boolean)lookupValue(useMap,IS_UPDATE_KEY,Trigger.isUpdate);
        this.isInsert = (Boolean)lookupValue(useMap,IS_INSERT_KEY,Trigger.isInsert);
        this.isDelete = (Boolean)lookupValue(useMap,IS_DELETE_KEY,Trigger.isDelete);
        this.isUndelete = (Boolean)lookupValue(useMap,IS_UNDELETE_KEY,Trigger.isUndelete);
        // obtain the SOBjectType by scanning the lists
        this.targetObjectType = (String)this.callableArguments.get(TARGET_OBJECT_TYPE_KEY);
        // the triggerTypeType value will allow us to use switch statements
        this.triggerTypeValue = getTriggerType();
        this.callableMap = (Map<String,Callable>)this.callableArguments.get(CALLABLE_MAP);
    }

    /**
     * Get the object from the oldMap
     * 
     * @param recordId
     * @return record from oldMap
     */
    public SObject getOldValue(Id recordId) {
        if(oldMap != null) {
            return oldMap.get(recordId);
        }
        return null;
    }

    /**
     * Get the object from the newMap
     * 
     * @param recordId
     * @return record from newMap
     */
    public SObject getNewValue(Id recordId) {
        if(newMap != null) {
            return newMap.get(recordId);
        }
        return null;
    }

    /**
     * Create trigger arguments for a before insert trigger event.
     * 
     * @param newList
     * @return triggerArguments
     */
    public static TriggerArguments createBeforeInsert(List<SObject> newList) {
        final Map<String,Object> callableArguments = ( new Map<String,Object>{
            NEW_LIST_KEY => newList
        } );
        return new TriggerArguments(callableArguments);
    }

    /**
     * Create trigger arguments for aafter insert trigger event.
     * 
     * @param newMap
     * @return triggerArguments
     */
    public static TriggerArguments createAfterInsert(Map<Id,SObject> newMap) {
        final Map<String,Object> callableArguments = ( new Map<String,Object>{
            NEW_MAP_KEY => newMap
        } );
        return new TriggerArguments(callableArguments);
    }

    /**
     * Create trigger arguments for before update trigger event.
     * 
     * @param oldMap
     * @param newMap
     * @return triggerArguments
     */
    public static TriggerArguments createBeforeUpdate(Map<Id,SObject> oldMap,List<SObject> newList) {
        final Map<String,Object> callableArguments = ( new Map<String,Object>{
            OLD_MAP_KEY => oldMap,
            NEW_LIST_KEY => newList
        } );
        return new TriggerArguments(callableArguments);
    }

    /**
     * Create trigger arguments for after update trigger event.
     * 
     * @param oldMap
     * @param newMap
     * @return triggerArguments
     */
    public static TriggerArguments createAfterUpdate(Map<Id,SObject> oldMap,Map<Id,SObject> newMap) {
        final Map<String,Object> callableArguments = ( new Map<String,Object>{
            OLD_MAP_KEY => oldMap,
            NEW_MAP_KEY => newMap
        } );
        return new TriggerArguments(callableArguments);
    }

    /**
     * Create trigger arguments for before delete event.
     * 
     * @param oldMap
     * @return triggerArguments
     */
    public static TriggerArguments createBeforeDelete(Map<Id,SObject> oldMap) {
        final Map<String,Object> callableArguments = ( new Map<String,Object>{
            OLD_MAP_KEY => oldMap,
            IS_BEFORE_KEY => true
        } );
        return new TriggerArguments(callableArguments);
    }

    /**
     * Create trigger arguments for after delete event.
     * 
     * @param oldMap
     * @return triggerArguments
     */
    public static TriggerArguments createAfterDelete(Map<Id,SObject> oldMap) {
        final Map<String,Object> callableArguments = ( new Map<String,Object>{
            OLD_MAP_KEY => oldMap,
            IS_AFTER_KEY => true
        } );
        return new TriggerArguments(callableArguments);
    }

    /**
     * Create trigger arguments for after undelete event.
     * 
     * @param newMap
     * @return triggerArguments
     */
    public static TriggerArguments createAfterUndelete(Map<Id,SObject> newMap) {
        final Map<String,Object> callableArguments = ( new Map<String,Object>{
            NEW_MAP_KEY => newMap,
            IS_UNDELETE_KEY => true
        } );
        return new TriggerArguments(callableArguments);
    }

    Object lookupValue(Boolean useKey,String key,Object retval) {
        if(useKey) {
            retval = callableArguments.get(KEY);
        }
        return retval;
    }

    @TestVisible
    static Map<Id,SObject> getSObjectMap(Map<Id,SObject> retval,Map<Id,SObject> mapToClone,List<SObject> values) {
        if(retval == null && mapToClone != null && values != null) {
            try {
                retval = mapToClone.clone();
                retval.clear();
                retval.putAll(values);
            }
            catch(Exception ex) {
                retval = null;
            }
        }
        return retval;
    }

    private List<SObject> getSObjectList(String listKey,Map<Id,SObject> refMap) {
        List<SObject> newList = (List<SObject>)callableArguments.get(listKey);
        if(newList == null && refMap != null) {
            newList = refMap.values().clone();
        }
        return newList;
    }

    private Integer getSizeScore(String key) {
        Integer retval = -2;
        if(callableArguments.containsKey(key)) {
            retval = -1;
            Object value = callableArguments.get(key);
            if(value instanceof Map<Id,SObject>) {
                retval = ((Map<Id,SObject>)value).size();
            }
            else if(value instanceof List<SObject>) {
                retval = ((List<SObject>)value).size();
            }
        }
        return retval;
    }

    private TriggerType getTriggerType() {
        TriggerType beforeType = null;
        TriggerType afterType = null;
        if( isInsert == true ) {
            beforeType = TriggerType.BEFORE_INSERT;
            afterType = TriggerType.AFTER_INSERT;
        }
        else if( isUpdate == true ) {
            beforeType = TriggerType.BEFORE_UPDATE;
            afterType = TriggerType.AFTER_UPDATE;
        }
        else if( isDelete == true ) {
            beforeType = TriggerType.BEFORE_DELETE;
            afterType = TriggerType.AFTER_DELETE;
        }
        else if( isUndelete == true ) {
            afterType = TriggerType.AFTER_UNDELETE;
        }
        TriggerType retval = null;
        if( isBefore == true ) {
            retval = beforeType;
        }
        else if( isAfter == true ) {
            retval = afterType;
        }
        return retval;
    }
}
