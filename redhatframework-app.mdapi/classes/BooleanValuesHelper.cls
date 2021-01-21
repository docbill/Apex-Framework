/**
 * This is a set of utilities for treating boolean metadata a a map.
 * 
 * @version 2020-12-02
 * 
 * @author Bill Riemers <briemers@redhat.com>
 * @since 2020-12-02 - Created
 */
public without sharing class BooleanValuesHelper {
    static Map<String,BooleanValuesHelper> booleanValuesHelperMap = new Map<String,BooleanValuesHelper>();

    public static Map<String,Boolean> missingMap = null;

    /** 
     * This mapping will be automatically populated
     * by use of the getValue method.
     */
    public static final Map<String,Boolean> booleanSettingMap = new Map<String,Boolean>();

    /** This is a mapping of overrides. */
    public static final Map<String,Boolean> overrideSettingMap = new Map<String,Boolean>();

    private final String source;
    private final String sourceWithSuffix;
    private Integer useTestingDefaultsSaveVersion = 0;
    private static Integer useTestingDefaultsVersion = 0;
    
    /**
     * Constructor
     * 
     * @param source
     */
    private BooleanValuesHelper(String source) {
        this.source = source;
        this.sourceWithSuffix = suffixWith(source,'.','');
    }

    /**
     * Factory method to get a boolean values helper.
     * 
     * @param source
     * @return the boolean values helper
     */
    public static BooleanValuesHelper getBooleanValuesHelper(String source) {
        BooleanValuesHelper bvHelper = booleanValuesHelperMap.get(source);
        if(bvHelper == null) {
            bvHelper = new BooleanValuesHelper(source);
            booleanValuesHelperMap.put(source,bvHelper);
            if(useTestingDefaults) {
                bvHelper.booleanMap = new Map<String,Boolean>();
            }
        }
        return bvHelper;
    }

    /**
     * This is the map of data obtained from the BooleanMetadata__mdt table with BooleanHierarchy overrides.
     */
    public Map<String,Boolean> booleanMap {
        get {
            if(booleanMap == null || useTestingDefaultsSaveVersion != useTestingDefaultsVersion) {
                booleanMap = getBooleanMap(source);
                useTestingDefaultsSaveVersion = useTestingDefaultsVersion;
            }
            return booleanMap;
        }
        set;
    }

    /**
     * Check if a trigger is active by referencing the
     * booleanSettingMap.  If an entry does not exist in
     * the map, one will be add by referencing BooleanSetting__c.
     *
     * @param key of the boolean setting
     * @param defaultValue the value to return if null
     * @return the value in the map or the defaultValue
     */
    public Boolean getValue(final String key,Boolean defaultValue) {
        String name = sourceWithSuffix+key;
        Boolean retval = booleanSettingMap.get(name);
        Boolean hasBooleanMetadata = booleanMap.containsKey(key);
        if(retval == null && String.isNotBlank(name) && ! booleanSettingMap.containsKey(name)) {
            retval = booleanMap.get(key);
            if(retval == null) {
                BooleanSetting__c bs = BooleanSetting__c.getInstance(name);
                if(bs != null  && bs.Value__c != null) {
                    retval = bs.Value__c;
                }
            }
            booleanSettingMap.put(name,retval);
        }
        if(retval == null) {
            retval = defaultValue;
            if(missingMap != null && ! hasBooleanMetadata) {
                missingMap.put(name,retval);
            }
        }
        List<String> prefixes = new List<String>(overrideSettingMap.keySet());
        prefixes.sort();
        for(String prefix : prefixes) {
            if(name.startsWith(prefix)) {
                retval = overrideSettingMap.get(prefix);
            }
        }
        return retval;
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
    public static Boolean getBooleanValue(final String name,Boolean defaultValue) {
        final Integer i=name.indexOf('.');
        String source = '';
        if(i>= 0) {
            source = name.left(i);
        }
        final BooleanValuesHelper bvHelper = getBooleanValuesHelper(source);
        String key = name;
        if(i >= 0) {
            key = name.substring(i+1);
        }
        return bvHelper.getValue(key,defaultValue);
    }

    /**
     * Used to set override for all matching settings is the map to the specified value.
     *
     * @param prefix the names to match. e.g. Account_Before.
     * @param value the value to set (a null value resets the override)
     */
    public static void setValuesWhichStartWith(String prefix,Boolean value) {
        if(String.isBlank(prefix)) {
            overrideSettingMap.clear();
        }
        else {
            for(String key : overrideSettingMap.keySet().clone()) {
                if(key.startsWith(prefix)) {
                    overrideSettingMap.remove(key);
                }
            }
        }
        if(prefix != null && value != null) {
            overrideSettingMap.put(prefix,value);
        }
    }
    

    /**
     * Setting to deactivate the use of boolean metadata in a test class.
     */
    public static Boolean useTestingDefaults {
        get {
            if(useTestingDefaults == null) {
                useTestingDefaults = Test.isRunningTest();
            }
            return useTestingDefaults;
        }
        set {
            useTestingDefaultsVersion++;
            booleanSettingMap.clear();
            useTestingDefaults = value;
        }
    }

    // Allow resource injection in the test class.
    public static BooleanHierarchy__c booleanHierarchyInstance {
        get {
            if(booleanHierarchyInstance == null) {
                booleanHierarchyInstance = BooleanHierarchy__c.getInstance(); 
            }
            return booleanHierarchyInstance;
        }
        set;
    }

    /**
     * Query the map from the BooleanMetadata__mdt table.  Each value maybe overwritten by
     * a BooleanHierarchy__c field with the field name matching the developer name.
     * 
     * @param source
     * @return map
     */
    public static Map<String,Boolean> getBooleanMap(final String source) {
        Map<String,Boolean> retval = new Map<String,Boolean>();
        final String sourceWithSuffix = suffixWith(source,'.','');
        List<BooleanMetadata__mdt> bmList = null;
        Boolean isBlankSourceWithSuffix = String.isBlank(sourceWithSuffix);
        if(! isBlankSourceWithSuffix) {
            final String masterLabelLike = sourceWithSuffix+'%';
            System.debug('masterLabelLike='+masterLabelLike);
            bmList = [
                select DeveloperName, MasterLabel, Value__c
                from BooleanMetadata__mdt
                where MasterLabel like :masterLabelLike ];
        }
        else {
            bmList = [
                select DeveloperName, MasterLabel, Value__c
                from BooleanMetadata__mdt
                where not MasterLabel like '%.%' ];

        }
        for(BooleanMetadata__mdt bm : bmList ) {
            if(isBlankSourceWithSuffix || bm.MasterLabel.startsWith(sourceWithSuffix)) {
                Boolean value = null;
                try {
                    final Decimal d = (Decimal)booleanHierarchyInstance.get(bm.DeveloperName+'__c');
                    if(d != null && d >= 0) {
                        value = (d > 0);
                    }
                }
                catch(Exception ignored) {}
                if(value == null && bm.Value__c != 'Default' && ! useTestingDefaults) {
                    value = (bm.Value__c == 'True');
                }
                if(value != null) {
                    final String key = getKey(sourceWithSuffix,bm.MasterLabel);
                    retval.put(key,value);
                }
            }
        }
        return retval;
    }

    static String suffixWith(String source,String suffix,String blankValue) {
        if(String.isBlank(source)) {
            source = blankValue;
        }
        else if( ! source.endsWithIgnoreCase(suffix)) {
            source += suffix;
        }
        return source;
    }

    @TestVisible
    static String getKey(String sourceWithSuffix,String key) {
        if(String.isNotblank(key) && String.isNotBlank(sourceWithSuffix) && key.startsWith(sourceWithSuffix)) {
            key = key.substringAfter(sourceWithSuffix);
        }
        return key;
    }

    /**
     * This can be called to automatically create an values listed in the missingMap.
     */
    public static Map<String,Metadata.CustomMetadata> createMissingBooleanMetadata() {
        Map<String,Metadata.CustomMetadata> customMetadataMap = new Map<String,Metadata.CustomMetadata>();
        if(missingMap != null && ! missingMap.isEmpty()) {
            final Map<Boolean,String> valueMap = ( new Map<Boolean,String>{
                null => 'Default',
                false => 'False',
                true => 'True'
            } );
    
            for(String name : missingMap.keySet()) {
                Metadata.CustomMetadata missingRecord = new Metadata.CustomMetadata();
                missingRecord.fullName = 'BooleanMetadata.'+getApiName(name);
                System.debug('missingRecord.fullName='+missingRecord.fullName);
                missingRecord.label = name;
                System.debug('missingRecord.label='+missingRecord.label);
                Metadata.CustomMetadataValue relValue = new Metadata.CustomMetadataValue();
                relValue.field = 'Value__c';
                relValue.value = valueMap.get(missingMap.get(name));
                missingRecord.values.add(relValue);
                customMetadataMap.put(missingRecord.fullName,missingRecord);
            }

            List<Metadata.Metadata> duplicates = 
                Metadata.Operations.retrieve(Metadata.MetadataType.CustomMetadata, 
                new List<String>(customMetadataMap.keySet()) );
            for(Metadata.Metadata record : duplicates) {
                System.debug('Duplicate record: '+record.fullName);
                customMetadataMap.remove(record.fullName);
            }
            if(! customMetadataMap.isEmpty()) {
                Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
                for(Metadata.CustomMetadata record : customMetadataMap.values()) {
                    mdContainer.addMetadata(record);
                }
                DeployCallback myCallback = new DeployCallback();
                myCallback.missingMap = missingMap;

                // we stop tracking further missing values
                missingMap = null;
                try {
                    Metadata.Operations.enqueueDeployment(mdContainer, myCallback);
                }
                catch(Exception ex) {
                    if(System.isFuture() || System.isBatch() || System.isQueueable() || System.isScheduled()) {
                        // we expect this in a test class
                        System.debug('Metadata.Operations.enqueueDeployment: failed');
                        System.debug(ex);
                    }
                    else {
                        createMissingBooleanMetadataFuture(myCallback.missingMap);
                    }
                }
            }
        }
        return customMetadataMap;
    }

    @future
    static void createMissingBooleanMetadataFuture(Map<String,Boolean> missingMap) {
        BooleanValuesHelper.missingMap = missingMap;
        System.debug('missingMap='+missingMap);
        createMissingBooleanMetadata();
    }

    static String getApiName(String name) {
        return name.replaceAll('[^a-zA-Z0-9]',' ').trim().normalizeSpace().replaceAll(' ','_');
    }

    public class DeployCallback implements Metadata.DeployCallback {
        Map<String,Boolean> missingMap;

        public void handleResult(
            Metadata.DeployResult result,
            Metadata.DeployCallbackContext context
        ) {
            System.debug('context='+context);
            
            if (result.status == Metadata.DeployStatus.Succeeded) {
                System.debug('Deployment was successful');
            }
            else {
                System.debug('missingMap='+missingMap);
                System.debug('errorStatusCode='+result.errorStatusCode);
                System.debug('errorMessage='+result.errorMessage);
                System.debug('Deployment was not successful');
            }
        }
    }

}