/**
 * This is an abstract class to help reduce the redunancies 
 * in the various trigger classes.
 *
 * @version 2021-04-27
 * 
 * @author Bill Riemers <briemers@redhat.com>
 * @since 2013-04-08 - Added processTriggerComplete method to auto insert custom settings
 * @since 2017-12-21 - Corrected problem in user query
 * @since 2018-11-29 - Add support for BooleanMetadata__mtd and BooleanHierarchy__c values
 * @since 2020-09-04 US270544 - Use a dynamic query for getUserMap, so this class is not org dependant
 * @since 2020-09-09 US270544 - Use a String_Values__mdt for custom user fields
 * @since 2020-11-12 - Call TriggerManagement
 * @since 2020-11-17 - Call SObjectCallableTrigger.assignLegacy
 * @since 2020-12-01 - Move boolean values into the Metadata_Values_Helper class
 * @since 2021-04-27 US292962 - No longer create missing metadata
 * 
 * @author Yancy Cruz <ycruz@redhat.com>
 * @since 2018-01-24 - US152262. Added fields for user map query.
 */
public abstract 
without sharing 
class AbstractTrigger {
    /** used to make sure we only do one insert for missing constants. */
    @TestVisible
    private static Integer insertMissing = 0;

    public static final String MAP_NAME = AbstractTrigger.class.getName(); // US270544
    public static final String USER_FIELD_PREFIX = 'UserField_'; // US270544

    /** 
     * This mapping will be automatically populated
     * by use of the isActive method.
     */
    public static Map<String,Boolean> booleanSettingMap {
        get { return BooleanValuesHelper.booleanSettingMap; }
    }

    /** This is a map of missing settings referenced by the isActive method. */
    @TestVisible
    private static Map<String,Boolean> missingMap = new Map<String,Boolean>();

    /** This is a mapping of overrides. */
    @TestVisible
    private static Map<String,Boolean> overrideSettingMap {
        get { return BooleanValuesHelper.overrideSettingMap; }
    }

    @TestVisible
    private static Callable triggerManagementCallable = new TriggerManagement();

    private static Map<Id,User> staticUserMap = new Map<Id,User>();

    @TestVisible
    private static final List<String> USER_FIELDS = (new List<String>{
        'Profile.Name',
        'UserRole.Name',
        'UserRoleId', //US130149
        'UserType', // reference to findout if this is a partner user
        'LastName', //US152262
        'FirstName', //US152262
        'Phone', //US152262
        'Email', //US152262
        'Alias',
        'AccountId' //US137106                
    });

    @TestVisible
    private static final Set<String> CUSTOM_FIELDS = (new Set<String>{
        'IsPortalEnabled' // this is listed under custom fields, because it is not available in all orgs.
    });

    static {
        BooleanValuesHelper.missingMap = missingMap;
    }

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
        // introduce compatability between our classes using AbstractTrigger and our new TriggerManagement
        try {
            if((xnewList == null || Trigger.new === xnewList)
                && (xnewMap == null || Trigger.newMap === xnewMap)
                && (xoldMap == null || Trigger.oldMap === xoldMap)
            ) {
                triggerManagementCallable.call('AbstractTrigger',null);
            }
        }
        catch(Exception ex) {
            System.debug('exeception thrown by trigger management: '+ex);
            System.debug(ex.getStackTraceString());
        }
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
            SObjectCallableTrigger.assignLegacy(newSObjectList);
        }
    }

    @TestVisible
    private static Boolean useTestingDefaults {
        get { return BooleanValuesHelper.useTestingDefaults; }
        set { BooleanValuesHelper.useTestingDefaults = value; }
    }

    // Allow resource injection in the test class.
    @TestVisible
    private static BooleanHierarchy__c booleanHierarchyInstance {
        get { return BooleanValuesHelper.booleanHierarchyInstance; }
    }


    /**
     * Check if a trigger is active by referencing the BooleanMetadata__mdt and BooleanHierarchy__c.
     *
     * @param name the name of the boolean setting
     * @param defaultValue the value to return if null
     * @return the value in the map or the defaultValue
     */
    public static Boolean isActive(final String name,Boolean defaultValue) {
        return BooleanValuesHelper.getBooleanValue(name,defaultValue);
    }

    /**
     * Used to set all matching settings is the map to the specified value.
     *
     * @param prefix the names to match. e.g. Account_Before.
     * @param value the value to set
     */
    public static void setBooleanSettings(String prefix,Boolean value) {
        BooleanValuesHelper.setValuesWhichStartWith(prefix,value);
        // to maintain backwards compatability
        for(String name : BooleanSetting__c.getAll().keySet()) {
            if(name.startsWith(prefix)) {
                booleanSettingMap.put(name,value);
            }
        }
    }

    /**
     * Create a mapping of users.
     */
    public static Map<Id,User> getUserMap(List<SObject> newList) {
        final Set<Id> userIds = new Set<Id>{UserInfo.getUserId()};
        try {
            for(SObject o : newList) {
                userIds.add((Id)o.get('OwnerId'));
            }
        }
        catch(Exception e) {}
        userIds.removeAll(staticUserMap.keySet());
        if(! userIds.isEmpty()) {
            // US270544
            List<String> fields = USER_FIELDS.clone();
            User u = new User();
            final Set<String> customFields = CUSTOM_FIELDS.clone();
            Metadata_Values_Helper metadataValuesHelper = Metadata_Values_Helper.getMetadataValuesHelper(MAP_NAME);
            for(String key : metadataValuesHelper.stringMap.keySet()) {
                if(key.startsWithIgnoreCase(USER_FIELD_PREFIX)) {
                    customFields.add(metadataValuesHelper.stringMap.get(key));
                }
            }
            // we add custom fields this way so we can used an unlocked package without the fields
            for(String customField : customFields ) {
                try {
                    u.get(customField);
                    fields.add(customField);
                }
                catch(Exception ignored) {}
            }
            staticUserMap.putAll((List<User>)Database.query('select '+String.join(fields,',')+' from User where Id in :userIds'));
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
//        if((! missingMap.isEmpty()) && insertMissing++ <= 0) {
//            BooleanValuesHelper.createMissingBooleanMetadata();
//        }
    }
}