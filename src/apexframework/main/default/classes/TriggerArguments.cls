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
 * Treat all memember variables of this class as final.  If you need to change the values
 * you should create a new instance with one of the static create methods.
 * 
 * @version 2022-08-10
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2020-11-12 Created
 * @since 2022-08-09 Support operationType
 * @since 2022-08-10 Refactored to resolve most PMD warnings
 */
@SuppressWarnings('PMD.ExcessivePublicCount')
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
    public static final String OPERATION_TYPE_KEY = 'operationType';
    public static final String TARGET_OBJECT_TYPE_KEY = 'targetObjectType';
    public static final String CALLABLE_MAP = 'callableMap';

    public Enum TriggerType { BEFORE_INSERT, AFTER_INSERT, BEFORE_UPDATE, AFTER_UPDATE, BEFORE_DELETE, AFTER_DELETE, AFTER_UNDELETE }

    /** 
     * The map of arguments representing Trigger that can be passed to a Callable trigger class.
     */
    public final Map<String,Object> callableArguments {
        get;
        private set {
            if(value == null) {
                value = new Map<String,Object>();
            }
            callableArguments = value;
        }
    }

    /** 
     * IS_BEFORE_KEY value from the callable arguments map.
     */
    public Boolean isBefore { get; private set; }

    /** 
     * IS_AFTER_KEY value from the callable arguments map.
     */
    public Boolean isAfter { get; private set; }

    /** 
     * NEW_LIST_KEY value from the callable arguments map.
     */
    public List<SObject> newList { get; private set; }

    /** 
     * NEW_MAP_KEY value from the callable arguments map.
     */
    public Map<Id,SObject> newMap { get; private set; }

    /** 
     * OLD_LIST_KEY value from the callable arguments map.
     */
    public List<SObject> oldList { get; private set; }

    /** 
     * OLD_MAP_KEY value from the callable arguments map.
     */
    public Map<Id,SObject> oldMap { get; private set; }

    /**
     * IS_UPDATE_KEY value from the callable arguments map.
     */
    public Boolean isUpdate { get; private set; }
    
    /** 
     * IS_INSERT_KEY value from the callable arguments map.
     */
    public Boolean isInsert { get; private set; }

    /** 
     * IS_DELETE_KEY value from the callable arguments map.
     */
    public Boolean isDelete { get; private set; }

    /** 
     * IS_UNDELETE_KEY value from the callable arguments map.
     */
    public Boolean isUndelete { get; private set; }

    /** 
     * OPERATION_TYPE_KEY value from the callable arguments map.
     */
    public final System.TriggerOperation operationType {
        get;
        private set {
            if(value == null) {
                if(isBefore == true) {
                    if(isInsert == true) {
                        value = System.TriggerOperation.BEFORE_INSERT;
                    }
                    else if(isUpdate == true) {
                        value = System.TriggerOperation.BEFORE_UPDATE;
                    }
                    else if(isDelete == true) {
                        value = System.TriggerOperation.BEFORE_DELETE;
                    }
                }
                else if(isInsert == true) {
                    value = System.TriggerOperation.AFTER_INSERT;
                }
                else if(isUpdate == true) {
                    value = System.TriggerOperation.AFTER_UPDATE;
                }
                else if(isDelete == true) {
                    value = System.TriggerOperation.AFTER_DELETE;
                }
                else if(isUndelete == true) {
                    value = System.TriggerOperation.AFTER_UNDELETE;
                }
            }
            operationType = value;
        }
    }

    /**
     * TARGET_OBJECT_KEY value from the callabse arguments map.
     */
    public String targetObjectType {
        get;
        private set {
            if(String.isBlank(value)) {
                List<SObject> objList = newList;
                if(objList == null || objList.isEmpty()) {
                    objList = oldList;
                }
                if(objList != null && ! objList.isEmpty()) {
                    value = objList[0].getSObjectType().getDescribe().getName();
                }
            }
            targetObjectType = value;
        }
    }

    /**
     * The trigger type of this call.
     */
    public TriggerType triggerTypeValue {
        get {
            // I do not remember why we mirror this as a triggerTypeValue
            return  (new Map<System.TriggerOperation,TriggerType> {
                System.TriggerOperation.BEFORE_INSERT => TriggerType.BEFORE_INSERT,
                System.TriggerOperation.BEFORE_UPDATE => TriggerType.BEFORE_UPDATE,
                System.TriggerOperation.BEFORE_DELETE => TriggerType.BEFORE_DELETE,
                System.TriggerOperation.AFTER_INSERT => TriggerType.AFTER_INSERT,
                System.TriggerOperation.AFTER_UPDATE => TriggerType.AFTER_UPDATE,
                System.TriggerOperation.AFTER_DELETE => TriggerType.AFTER_DELETE,
                System.TriggerOperation.AFTER_UNDELETE => TriggerType.AFTER_UNDELETE
            }).get(this.operationType);
        }
    }

    /** 
     * The map of all callable triggers called so far as part of the current DML
     * operation.
     */
    public final Map<String,Callable> callableMap;

    /**
     * Constructor.  A null or empty map will construct using Trigger values.
     * Any missing values in a non-empty map will be filled in with values determined
     * in the setter methods.
     * 
     * @param callableArguments map of trigger values, or null
     */
    public TriggerArguments(Map<String,Object> callableArguments) {
        this.callableArguments = callableArguments;
        if(this.callableArguments.isEmpty()) {
            isBefore = Trigger.isBefore;
            isAfter = Trigger.isAfter;
            isInsert = Trigger.isInsert;
            isUpdate = Trigger.isUpdate;
            isDelete = Trigger.isDelete;
            isUndelete = Trigger.isUndelete;
            newList = Trigger.new;
            newMap = Trigger.newMap;
            oldList = Trigger.old;
            oldMap = Trigger.oldMap;
            operationType = Trigger.operationType;
        }
        else {
            // Accept a map with very minimal values and populate anything that is missing.
            System.TriggerOperation operationType = (System.TriggerOperation)this.callableArguments.get(OPERATION_TYPE_KEY);
            initializeFromOperationType(operationType);
            assignMaps();
            assignMissingFlags();
            this.operationType = operationType;
        }

        // obtain the SOBjectType by scanning the lists
        targetObjectType = (String)this.callableArguments.get(TARGET_OBJECT_TYPE_KEY);

        Map<String,Callable> callableMap = (Map<String,Callable>)this.callableArguments.get(CALLABLE_MAP);
        if(callableMap == null) {
            callableMap = new Map<String,Callable>();
        }
        this.callableMap = callableMap;
        syncToMap();
    }

    /**
     * Get the object from the oldMap.  Using this method leads to more streamlined code.
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
     * Get the object from the newMap.  Using this method leads to more streamlined code.
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

    @TestVisible
    private static Map<Id,SObject> getSObjectMap(Map<Id,SObject> retval,Map<Id,SObject> mapToClone,List<SObject> values) {
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

    private void initializeFromOperationType(System.TriggerOperation operationType) {
        isInsert = isUpdate = isDelete = isUndelete = false;
        switch on operationType {
            when BEFORE_INSERT {
                isInsert = true;
                isBefore = true;
            }
            when BEFORE_UPDATE {
                isUpdate = true;
                isBefore = true;
            }
            when BEFORE_DELETE {
                isDelete = true;
                isBefore = true;
            }
            when AFTER_INSERT { 
                isInsert = true;
                isBefore = false;
            }
            when AFTER_UPDATE { 
                isUpdate = true;
                isBefore = false;
            }
            when AFTER_DELETE { 
                isDelete = true;
                isBefore = false;
            }
            when AFTER_UNDELETE {
                isUndelete = true;
                isBefore = false; 
            }
            when else {
                isInsert = (Boolean)this.callableArguments.get(IS_INSERT_KEY);
                isUpdate = (Boolean)this.callableArguments.get(IS_UPDATE_KEY);
                isDelete = (Boolean)this.callableArguments.get(IS_DELETE_KEY);
                isUndelete = (Boolean)this.callableArguments.get(IS_UNDELETE_KEY);
                isBefore = (Boolean)this.callableArguments.get(IS_BEFORE_KEY);
                if(isBefore == null) {
                    // Before and After update look the same in terms of lists.  So 
                    // our convention is to assume it is a before if a newMap entry not
                    // explicitly supplied.
                    Boolean isAfter = (Boolean)callableArguments.get(IS_AFTER_KEY);
                    isBefore = ! (isAfter == true || isUndelete == true);
                    if(isAfter == null && isUndelete != true) {
                        // It would be better to pass the isBefore value rather than relying on this logic...
                        Integer newListSizeScore = getSizeScore(NEW_LIST_KEY);
                        Integer newMapSizeScore = getSizeScore(NEW_MAP_KEY);
                        isBefore = (newMapSizeScore < newListSizeScore);
                    }
                }
            }
        }
        isAfter = ! isBefore;
    }

    private void assignMissingFlags() {
        if(isUpdate == null) {
            isUpdate = ! ( true == isInsert || true == isDelete || true == isUndelete
                || oldMap == null || newMap == null || oldMap.isEmpty() || newMap.isEmpty() );
        }
        // We cannot tell the difference between an after insert
        // or an after undelete, unless either the isInsert or isUndelete flag
        // is set.  Our default is to assume insert as that is more common.
        if(isInsert == null) {
            isInsert = ! ( isUpdate || true == isDelete || true == isUndelete
                || newList == null || newList.isEmpty() || (oldList != null && !oldList.isEmpty()));
        }
        if(isDelete == null) {
            isDelete = ! ( isInsert || isUpdate || true == isUndelete 
                || oldMap == null || oldMap.isEmpty() || (newList != null && ! newList.isEmpty()));
        }
        if( isUndelete == null) {
            isUndelete = ! ( isBefore || isInsert || isUpdate || isDelete 
                || newMap == null || newMap.isEmpty() || (oldList != null || ! oldList.isEmpty()));
        }
    }

    private void assignMaps() {
        // The following is useful for test classes and non-dependent packages.
        // If the caller manually assigned the arguments map, we don't assume it is correct.
        // Instead we'll auto derive any missing values and attempt to normalise to consistent
        // values.
        Map<Id,SObject> newMap = (Map<Id,SObject>)this.callableArguments.get(NEW_MAP_KEY);
        Map<Id,SObject> oldMap = (Map<Id,SObject>)this.callableArguments.get(OLD_MAP_KEY);

        // the order of these calls matter
        // create a newList from the oldMap
        newList = getSObjectList(NEW_LIST_KEY,newMap); // references this.callableArguments
        // create an oldList from the newMap
        oldList = getSObjectList(OLD_LIST_KEY,oldMap);  // references this.callableArguments
        // when needed, use the oldMap and newList to create a newMap
        this.newMap = getSObjectMap(newMap,oldMap,this.newList); 
        // when needed, use the newMap and oldList to create an oldMap
        this.oldMap = getSObjectMap(oldMap,newMap,this.oldList);
    }

    private void syncToMap() {
        callableArguments.put(IS_BEFORE_KEY,isBefore);
        callableArguments.put(IS_AFTER_KEY,isAfter);
        callableArguments.put(IS_INSERT_KEY,isInsert);
        callableArguments.put(IS_UPDATE_KEY,isUpdate);
        callableArguments.put(IS_DELETE_KEY,isDelete);
        callableArguments.put(IS_UNDELETE_KEY,isUndelete);
        callableArguments.put(NEW_LIST_KEY,newList);
        callableArguments.put(NEW_MAP_KEY,newMap);
        callableArguments.put(OLD_LIST_KEY,oldList);
        callableArguments.put(OLD_MAP_KEY,oldMap);
        callableArguments.put(TARGET_OBJECT_TYPE_KEY,targetObjectType);
        callableArguments.put(OPERATION_TYPE_KEY,operationType);
        callableArguments.put(CALLABLE_MAP,callableMap);
    }
}
