/**
 * This is an abstract class to help reduce the redunancies 
 * in the various trigger classes.
 *
 * @version 2018-11-29
 * @author Bill Riemers <briemers@redhat.com>
 * @since 2013-04-08 - Added processTriggerComplete method to auto insert custom settings
 * @since 2017-12-21 - Corrected problem in user query
 * @since 2018-11-29 - Add support for BooleanMetadata__mtd and BooleanHierarchy__c values
 * 
 * @author Yancy Cruz <ycruz@redhat.com>
 * @since 2018-01-24 - US152262. Added fields for user map query.
 */
public abstract without sharing class AbstractTrigger {
    /** used to make sure we only do one insert for missing constants. */
    public static Integer insertMissing = 0;

    /** 
     * This mapping will be automatically populated
     * by use of the isActive method.
     */
    public static final Map<String,Boolean> booleanSettingMap = new Map<String,Boolean>();

    /** This is a map of missing settings referenced by the isActive method. */
    public static final Map<String,BooleanSetting__c> missingSettingMap = new Map<String,BooleanSetting__c>();

    /** This is a mapping of overrides. */
    public static final Map<String,Boolean> overrideSettingMap = new Map<String,Boolean>();

    /** Normally populated as Trigger.oldMap */
    public final Map<Id,SObject> oldSObjectMap;
    /** Normally populated as Trigger.new */
    public final List<SObject> newSObjectList;
    /** Normally populated as Trigger.new */
    public final Map<Id,SObject> newSObjectMap;
    /** Logically equivalent to Trigger.IsDelete */
    public final Boolean isDelete;
    /** Logically equivalent to Trigger.IsInsert */
    public final Boolean isInsert;
    /** Logically equivalent to Trigger.IsUpdate */
    public final Boolean isUpdate;
    /** Used to keep track of errors while debugging */
    public Boolean hasErrors = false;

    /**
     * This constructor is normally called via the child super methods.
     */
    protected AbstractTrigger(Map<Id,SObject> xoldMap,List<SObject> xnewList,Map<Id,SObject> xnewMap) {
        isDelete = (xnewMap == null)&&(xnewList == null);
        if(xnewMap == null) {
            xnewMap = new Map<Id,SObject>();
        }
        isInsert = (xoldMap == null);
        if(xnewList == null) {
            xnewList = xnewMap.values();
        }
        isUpdate = ! ( isDelete || isInsert );
        oldSObjectMap = xoldMap;
        newSObjectList = xnewList;
        newSObjectMap = xnewMap;
    }

    /**
     * Copy the ownerId to a custom look-up field.
     *
     * This is a trigger method we use on many object types.
     * So we might as define it here.  This method will only work
     * in before triggers.
     */
    public virtual void assignLegacy() {
        if(isInsert || isUpdate) {
            for(SObject o : newSObjectList) {
                Id ownerId = null;
                String s = ''+o.get('OwnerId');
                if(s.startsWith('005')) {
                    ownerId = (Id)s;
                }
                if(ownerId != (Id)o.get('Owner__c') ) {
                    o.put('Owner__c',ownerId);
                }
            }
        }
    }

    @TestVisible
    private static Boolean useTestingDefaults {
        get {
            if(useTestingDefaults == null) {
                useTestingDefaults = Test.isRunningTest();
            }
            return useTestingDefaults;
        }
        set;
    }

    // Allow resource injection in the test class.
    @TestVisible
    private static BooleanHierarchy__c booleanHierarchyInstance {
        get {
            if(booleanHierarchyInstance == null) {
                booleanHierarchyInstance = BooleanHierarchy__c.getInstance(); 
            }
            return booleanHierarchyInstance;
        }
        set;
    }

    /**
     * Check if a trigger is active by referencing the
     * booleanSettingMap.  If an entry does not exist in
     * the map, one will be add by referencing BooleanSetting__c.
     *
     * @param name the name of the boolean setting
     * @param defaultValue the value to return if null
     * @return the value in the map or the defaultValue
     */
    public static Boolean isActive(final String name,Boolean defaultValue) {
        Boolean retval = booleanSettingMap.get(name);
        Boolean hasBooleanMetadata = false;
        if(retval == null && ! booleanSettingMap.containsKey(name)) {
            Boolean value = null;
            if(! useTestingDefaults) {
	    		for(BooleanMetadata__mdt bm : [
	                select DeveloperName,Value__c 
	                from BooleanMetadata__mdt 
	                where MasterLabel = :name 
	            	limit 1] )
	            {
	                hasBooleanMetadata = true;
	                // We allow a custom field to be defined for any boolean setting...
	                try {
	                    Decimal d = (Decimal)booleanHierarchyInstance.get(bm.DeveloperName+'__c');
	                    if(d != null && d >= 0) {
	                        value = (d > 0);
	                    }
	                }
	                catch(Exception ignored) {}
	                if(value == null && bm.Value__c != 'Default') {
		                value = (bm.Value__c == 'True');
	                }
	            }
            }
            if(value == null) {
	            BooleanSetting__c bs = BooleanSetting__c.getInstance(name);
    	        if(bs != null) {
        	        value = bs.Value__c;
            	}
            }
            if(value != null) {
	            retval = value;
            }
            booleanSettingMap.put(name,retval);
        }
        if(retval == null) {
            retval = defaultValue;
            if(! hasBooleanMetadata) {
	            missingSettingMap.put(name,new BooleanSetting__c(Name=name,Value__c=defaultValue));
            }
        }
        for(String prefix : overrideSettingMap.keySet()) {
            if(name.startsWith(prefix)) {
                retval = overrideSettingMap.get(prefix);
            }
        }
        return retval;
    }

    /**
     * Used to set all matching settings is the map to the specified value.
     *
     * @param prefix the names to match. e.g. Account_Before.
     * @param value the value to set
     */
    public static void setBooleanSettings(String prefix,Boolean value) {
        overrideSettingMap.put(prefix,value);
        for(String name : BooleanSetting__c.getAll().keySet()) {
            if(name.startsWith(prefix)) {
                booleanSettingMap.put(name,value);
            }
        }
    }

    static Map<Id,User> staticUserMap = new Map<Id,User>();

    /**
     * Create a mapping of users.
     */
    public static Map<Id,User> getUserMap(List<SObject> newList) {
        Set<Id> userIds = new Set<Id>{UserInfo.getUserId()};
        try {
            for(SObject o : newList) {
                userIds.add((Id)o.get('OwnerId'));
            }
        }
        catch(Exception e) {}
        userIds.removeAll(staticUserMap.keySet());
        if(! userIds.isEmpty()) {
            staticUserMap.putAll([
                select
                    Job_Function__c,
                    Profile.Name,
                    Is_Marketing_User__c,
                    IsPortalEnabled, // reference to findout if this is a portal user
                    Region__c,
                    UserRole.Name,
                    UserRoleId, //US130149
                    UserType, // reference to findout if this is a partner user
                    //START Added for US152262 ycruz
                    LastName,
                    FirstName,
                    Phone,
                    Email,                  
                    //END Added for US152262 ycruz
                    alias,
                    Lead_Dev_Team__c, //US129895
                    AccountId //US137106
                    from User
                    where Id in :userIds ]);
        }
        return staticUserMap;
    }

    /**
     * A mapping of users.
     */
    public Map<Id,User> userMap {
        get {
            if(userMap == null) {
                userMap = getUserMap(newSObjectList);
            }
            return userMap;
        }
        set;
    }

    /**
     * The current user.
     */
    public User currentUser {
        get {
            // no need to do another query, we can simply reuse the userMap query above...
            if(currentUser == null) {
                currentUser = userMap.get(UserInfo.getUserId());
            }
            return currentUser;
        }
        set;
    }

    /**
     * Called after processing all the triggers.  This will automatically add
     * missing custom settings.
     */
    public static void processTriggerComplete() {
        if((! missingSettingMap.isEmpty()) && insertMissing++ <= 0) {
            List<BooleanSetting__c> booleanSettings = new List<BooleanSetting__c>(missingSettingMap.values());
            for(Database.SaveResult sr : Database.insert(booleanSettings,false)) {
                BooleanSetting__c bs = booleanSettings.remove(0);
                if(sr.isSuccess()) {
                    booleanSettingMap.put(bs.Name,bs.Value__c);
                }
            }
            missingSettingMap.clear();
        }
    }
}