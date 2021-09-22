// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * This is a set of utilities for treating boolean metadata a a map.
 * 
 * @version 2021-09-21
 * 
 * @author Bill Riemers <briemers@redhat.com>
 * @since 2020-12-02 - Created
 * @since 2021-01-29 - Allow ignoreMetadata per instance 
 * @since 2021-02-13 DE25830 - Fix to make sure maps are per helper instance
 * @since 2021-04-27 US292962 - No longer create missing metadata
 * @since 2021-09-21 - User legacyMap instead of BooleanSetting__c
 */
public without sharing class BooleanValuesHelper {
    private static Map<Boolean,Map<String,BooleanValuesHelper>> booleanValuesHelperMaps = (new Map<Boolean,Map<String,BooleanValuesHelper>>{
        true => new Map<String,BooleanValuesHelper>(), // always use metadata
        false => new Map<String,BooleanValuesHelper>(), // never use metadata
        null => new Map<String,BooleanValuesHelper>() // conditionally use metadata
    } );

    public static Map<String,Boolean> legacyMap = null;

    public static Map<String,Boolean> missingMap = null;

    private static Map<String,Boolean> booleanSettingMapFromDefaults = new Map<String,Boolean>();
    private static Map<String,Boolean> booleanSettingMapFromMetadata = new Map<String,Boolean>();

    private static Map<String,Boolean> getBooleanSettingMap(Boolean ignoreMetadata) {
        if(ignoreMetadata == false || (ignoreMetadata == null && useTestingDefaults == false)) {
            return booleanSettingMapFromMetadata;
        }
        return booleanSettingMapFromDefaults;
    }


    /** 
     * This mapping will be automatically populated
     * by use of the getValue method.
     */
    public static final Map<String,Boolean> booleanSettingMap {
        get { return getBooleanSettingMap( useTestingDefaults ); }
    }

    /** This is a mapping of overrides. */
    public static final Map<String,Boolean> overrideSettingMap = new Map<String,Boolean>();

    private final String source;
    private final String sourceWithSuffix;
    private final Boolean ignoreMetadata;
    // if ignoreMetadata is null we reset our maps when the useTestingDefaults is changed
    private Integer useTestingDefaultsSaveVersion = 0;
    private static Integer useTestingDefaultsVersion = 0;

    /**
     * Constructor
     * 
     * @param source
     */
    private BooleanValuesHelper(String source,Boolean ignoreMetadata) {
        this.ignoreMetadata = ignoreMetadata;
        this.source = source;
        this.sourceWithSuffix = suffixWith(source,'.','');
    }

    /**
     * Factory method to get a boolean values helper.
     * 
     * @param source
     * @return the boolean values helper
     */
    public static BooleanValuesHelper getBooleanValuesHelper(String source,Boolean ignoreMetadata) {
        final Map<String,BooleanValuesHelper> booleanValuesHelperMap = booleanValuesHelperMaps.get(ignoreMetadata);
        BooleanValuesHelper bvHelper = booleanValuesHelperMap.get(source);
        if(bvHelper == null) {
            bvHelper = new BooleanValuesHelper(source,ignoreMetadata);
            booleanValuesHelperMap.put(source,bvHelper);
        }
        return bvHelper;
    }

    /**
     * Factory method to get a boolean values helper.
     * 
     * @param source
     * @return the boolean values helper
     */
    public static BooleanValuesHelper getBooleanValuesHelper(String source) {
        return getBooleanValuesHelper(source,null);
    }

    private Map<String,Boolean> booleanMapFromDefaults = null;
    private Map<String,Boolean> booleanMapFromMetadata = null;

    /**
     * This is the map of data obtained from the BooleanMetadata__mdt table with BooleanHierarchy overrides.
     */
    public Map<String,Boolean> booleanMap {
        get {
            Boolean needsReset = (ignoreMetadata != (! useTestingDefaults) && useTestingDefaultsSaveVersion != useTestingDefaultsVersion);
            if(ignoreMetadata == false || (ignoreMetadata == null && useTestingDefaults == false)) {
                if(booleanMapFromMetadata == null || needsReset) {
                    booleanMapFromMetadata = getBooleanMap(source,ignoreMetadata);
                    useTestingDefaultsSaveVersion = useTestingDefaultsVersion;
                }
                return booleanMapFromMetadata;
            }
            if(booleanMapFromDefaults == null || needsReset) {
                booleanMapFromDefaults = new Map<String,Boolean>();
                useTestingDefaultsSaveVersion = useTestingDefaultsVersion;
            }
            return booleanMapFromDefaults;
        }
        private set;
    }

    /**
     * Check if a trigger is active by referencing the
     * booleanSettingMap.  If an entry does not exist in
     * the map, one will be add by referencing legacyMap.
     *
     * @param key of the boolean setting
     * @param defaultValue the value to return if null
     * @return the value in the map or the defaultValue
     */
    public Boolean getValue(final String key,Boolean defaultValue) {
        String name = sourceWithSuffix+key;
        final Map<String,Boolean> booleanSettingMap = getBooleanSettingMap( ignoreMetadata );
        Boolean retval = booleanSettingMap.get(name);
        Boolean hasBooleanMetadata = booleanMap.containsKey(key);
        if(retval == null && String.isNotBlank(name) && ! booleanSettingMap.containsKey(name)) {
            retval = booleanMap.get(key);
            if(retval == null && legacyMap != null) {
                retval = legacyMap.get(name);
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
     * the map, one will be add by referencing legacyMap.
     *
     * @param name the name of the boolean setting
     * @param defaultValue the value to return if null
     * @return the value in the map or the defaultValue
     */
    public static Boolean getBooleanValue(final String name,Boolean defaultValue) {
        return getBooleanValue(name,defaultValue,null);
    }

    /**
     * Check if a trigger is active by referencing the
     * booleanSettingMap.  If an entry does not exist in
     * the map, one will be add by referencing legacyMap.
     *
     * @param name the name of the boolean setting
     * @param defaultValue the value to return if null
     * @param ignoreMetadata when true we ignore the value not the existance of metadata
     * @return the value in the map or the defaultValue
     */
    public static Boolean getBooleanValue(final String name,Boolean defaultValue,Boolean ignoreMetadata) {
        final Integer i=name.indexOf('.');
        String source = '';
        if(i>= 0) {
            source = name.left(i);
        }
        final BooleanValuesHelper bvHelper = getBooleanValuesHelper(source,ignoreMetadata);
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
     * @param ignoreMetadata when true ignore the values, but not the existance
     * @return map
     */
    public static Map<String,Boolean> getBooleanMap(final String source,Boolean ignoreMetadata) {
        if(ignoreMetadata == null) {
            ignoreMetadata = usetestingDefaults;
        }
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
                if(value == null && bm.Value__c != 'Default' && ! ignoreMetadata) {
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
}
