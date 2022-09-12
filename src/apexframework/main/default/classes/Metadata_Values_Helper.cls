// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * @description
 * This is a set of utilities for treating simple metadata a a map.
 * 
 * @group ApexFramework
 * 
 * @author Bill Riemers <briemers@redhat.com>
 * @since 2020-08-26 US268900 - Created as part of PQI approval implementation
 * @since 2020-12-03 - Added factory method
 * @since 2022-09-09 update for ApexDox commenting
 */
public without sharing class Metadata_Values_Helper {

    private static Map<String,Metadata_Values_Helper> metadataValuesHelperMap = new Map<String,Metadata_Values_Helper>();

    private final String source;

    /**
     * @description
     * Constructor
     * 
     * @param source
     */
    public Metadata_Values_Helper(String source) {
        this.source = source;
    }

    /**
     * @description
     * Factory method to get a metadata value helper.
     * 
     * @param source
     * @return the metadata value helper
     */
    public static Metadata_Values_Helper getMetadataValuesHelper(String source) {
        Metadata_Values_Helper mdvHelper = metadataValuesHelperMap.get(source);
        if(mdvHelper == null) {
            mdvHelper = new Metadata_Values_Helper(source);
            metadataValuesHelperMap.put(source,mdvHelper);
        }
        return mdvHelper;
    }

    /**
     * @description
     * This is the map of data obtained from the Decimal2_Values__mdt table.
     */
    public Map<String,Decimal> decimal2Map {
        get {
            if(decimal2Map == null) {
                decimal2Map = getDecimal2Map(source);
            }
            return decimal2Map;
        }
        set;
    }

    /**
     * @description
     * This is the map of data obtained from the String_Values__mdt table.
     */
    public Map<String,String> stringMap {
        get {
            if(stringMap == null) {
                stringMap = getStringMap(source);
            }
            return stringMap;
        }
        set;
    }

    /**
     * @description
     * Query the map from the Decimal2_Values__mdt table.
     * 
     * @param source
     * @return map
     */
    public static Map<String,Decimal> getDecimal2Map(String source) {
        Map<String,Decimal> retval = new Map<String,Decimal>();
        for(Decimal2_Values__mdt dv : [
            select Key__c,Value__c
            from Decimal2_Values__mdt
            where Source__c = :source 
                and Active__c = true
        ])
        {
            retval.put(dv.Key__c,dv.Value__c);
        }
        return retval;
    }

    /**
     * @description
     * Query the map from the String_Values__mdt table.
     * 
     * @param source
     * @return map
     */
    public static Map<String,String> getStringMap(String source) {
        Map<String,String> retval = new Map<String,String>();
        for(String_Values__mdt dv : [
            select Key__c,Value__c
            from String_Values__mdt
            where Source__c = :source 
            and Active__c = true
        ])
        {
            retval.put(dv.Key__c,dv.Value__c);
        }
        return retval;
    }
}
