// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * @description
 * This class used to copy data from one object to another using Field_Map_Entry__mdt and User_Field_Map_Entry__mdt values
 *
 * @group ApexFramework
 * 
 * @author  Bill C Riemers <briemers@redhat.com>
 * @since 2019-11-21 - Created
 * @since 2019-12-19 - Updated to allow boolean and decimal default values
 * @since 2020-02-10 US244638 US245940 - Added support for User_Field_Map_Entry__mdt
 * @since 2020-03-05 US244638 US245940 - Added isDebugging flag
 * @since 2021-04-06 - Increase test coverage
 * @since 2021-04-27 - Changes towards depreciated Map_Name__c (picklists are not handled well by unlocked packages)
 * @since 2022-08-04 SPP-4116 - Added getDestinationEntityMap method
 * @since 2022-09-09 update for ApexDox commenting
 */
public class Field_Map {
    /**
     * @description
     * Name of the boolean metadata that activates debugging logs
     */
    public static final String DEBUG_SETTING = 'Field_Map.debug';

    private final Boolean isDebugging;

    /**
     * @description
     * Name of the map we are using
     */
    public final String mapName;

    @TestVisible
    private Map<String,List<FieldMapEntry>> fieldEntriesMap = new Map<String,List<FieldMapEntry>>();

    private Map<String,List<FieldMapEntry>> fieldEntriesBySourceMap = new Map<String,List<FieldMapEntry>>();

    /**
     * @description
     * This gives us a way to inject Field_Map_Entry__mdt.
     */
    public List<Field_Map_Entry__mdt> fieldEntriesForTesting {
        get;
        set {
            fieldEntriesForTesting = value;
            fieldEntriesForTesting2 = null;
            if(value != null) {
                fieldEntriesForTesting2 = new List<FieldMapEntry>();
                for(Field_Map_Entry__mdt fme : value) {
                    fieldEntriesForTesting2.add(new FieldMapEntry(fme));
                }
            }
        }
    }

    @TestVisible
    private List<FieldMapEntry> fieldEntriesForTesting2 = null;

    /**
     * @description
     * Standard constructor.
     * 
     * @param name of the field map
     */
    public Field_Map(String name) {
        mapName = name;
        isDebugging = BooleanValuesHelper.getBooleanValue(DEBUG_SETTING,Test.isRunningTest());
    }

    /**
     * @description
     * Implements special rules for copying fields.
     * 
     * @param src to copy from
     * @param dest to copy to
     * @return list of Error Messages
     */
    public List<String> copyFields(SObject src,SObject dest)
    {
        Map<String,SObject> entityMap = new Map<String,SObject>();
        if(src != null) {
            final String sourceEntityName = src.getSObjectType().getDescribe().getName();
            entityMap.put( sourceEntityName, src );                
        }
        return copyFields( entityMap, dest );
    }

    @TestVisible
    private static Object convertText(String value,SObject dest,String fieldApiName) {
        Object retval = value;
        if(value != null) {
            // allow default values for booleans and decimals
            Schema.DescribeFieldResult dfr = dest.getsObjectType().getDescribe().fields.getMap().get(fieldApiName).getDescribe();
            Schema.SOAPType st = dfr.getSOAPType();
            switch on st {
                when Boolean {
                    retval = (value == 'true');
                }
                when Double, Decimal {
                    retval = Decimal.valueof( value );
                }
            }
        }
        return retval;
    }

    /**
     * @description
     * Implements special rules for copying fields.
     * 
     * @param entityNameMap to use to field values
     * @param dest to copy to
     * @return list of Error Messages
     */
    public List<String> copyFields(Map<String,SObject> entityNameMap, SObject dest) 
    {
        System.debug('dest='+dest);
        List<String> copyFieldErrorList = new List<String>();
        
        if(dest != null) {
            final String destinationEntityName = dest.getSObjectType().getDescribe().getName();
            final Set<String> sourceEntitySet = entityNameMap.keySet();
            if(isDebugging) {
                System.debug('copyFields('+destinationEntityName+','+entityNameMap.keySet()+')');
            }
            List<FieldMapEntry> fmeList = getFieldMapEntriesByDest( dest );
            if(fieldEntriesForTesting2 != null) {
                // this allows resource injection from a test class
                fmeList = fieldEntriesForTesting2;
            }
            for(FieldMapEntry fme : fmeList )
            {
                if ( fme.destinationEntityQualifiedApiName == destinationEntityName
                    && fme.destinationFieldQualifiedApiName != null
                    && ( fme.defaultValue != null || fme.sourceEntityQualifiedApiName != null ) )
                {
//                    System.debug(
//                        'Source_Entity__c='+fme.sourceEntityQualifiedApiName
//                        + ',Source_Field__c='+fme.sourceFieldQualifiedApiName
//                        + ',Destination_Entity__c='+fme.destinationEntityQualifiedApiName
//                        + ',Destination_Field__c='+fme.destinationFieldQualifiedApiName );
                    SObject source = entityNameMap.get(fme.sourceEntityQualifiedApiName);
//                    System.debug('source='+source);
                    fme.copyField(source,dest,copyFieldErrorList);
                }
            }
        }
        
        return copyFieldErrorList;
    }

    /**
     * @description
     * Obtain all the field names for the specified source, prefixed with the specified string.
     * 
     * @param prefix string to prefix to field names, useful when generating a subquery
     * @param sourceSObjectType the source SObjectType we are looking for
     * @return a set of fieldnames prefixed with specified value
     */
    public Set<String> getSourceFieldNames(String prefix,SObjectType sourceSObjectType) {
        final String sourceEntityName = sourceSObjectType.getDescribe().getName();
        if(isDebugging) {
            System.debug('getSourceFieldNames('+prefix+','+sourceEntityName+')');
        }
        Set<String> sourceFieldNames = new Set<String>();
        List<FieldMapEntry> fmeList = getFieldMapEntriesBySource(sourceEntityName);
        if(fieldEntriesForTesting2 != null) {
            // this allows resource injection from a test class
            fmeList = fieldEntriesForTesting2;
        }
        for(FieldMapEntry fme : fmeList)
        {
            if( fme.sourceEntityQualifiedApiName == sourceEntityName
                && fme.sourceFieldQualifiedApiName != null ) 
            {
                sourceFieldNames.add(prefix+fme.sourceFieldQualifiedApiName);
            }
        }
        return sourceFieldNames;
    }

    /**
     * @description
     * Create a map of entities we can copy to.  This is useful, if we are 
     * planning on inserting brand new objects, or there is a field we can use
     * for upserts.
     * 
     * @param sourceSObjectType the source object we are mapping from
     * @return a map of entity qualified api name to a newly created SObject
     */
    public Map<String,SObject> getDestinationEntityMap(SObjectType sourceSObjectType) {
        final String sourceEntityName = sourceSObjectType.getDescribe().getName();
        if(isDebugging) {
            System.debug('getDestinationEntityMap('+sourceEntityName+')');
        }
        Map<String,SObject> destinationEntityMap = new Map<String,SObject>();
        List<FieldMapEntry> fmeList = getFieldMapEntriesBySource(sourceEntityName);
        if(fieldEntriesForTesting2 != null) {
            // this allows resource injection from a test class
            fmeList = fieldEntriesForTesting2;
        }
        for(FieldMapEntry fme : fmeList)
        {
            if( fme.sourceEntityQualifiedApiName == sourceEntityName
                && fme.destinationEntityQualifiedApiName != null ) 
            {
                destinationEntityMap.put(fme.destinationEntityQualifiedApiName,null);
            }
        }
        for(String key : destinationEntityMap.keySet()) {
            SObject obj = (SObject)Type.forName(key).newInstance();
            destinationEntityMap.put(key,obj);
        }
        return destinationEntityMap;
    }

    private static void addAll(List<FieldMapEntry> targetList, final String mapName, List<User_Field_Map_Entry__mdt> sourceList) {
        for(User_Field_Map_Entry__mdt fme : sourceList) {
            if( ( fme.Map_Name__c == null && fme.MasterLabel.startsWithIgnoreCase(mapName+'.'))
                || mapName == fme.Map_Name__c )
            {
                targetList.add( new FieldMapEntry(fme) );
            }
        }
    }

    private static void addAll(List<FieldMapEntry> targetList, final String mapName, List<Field_Map_Entry__mdt> sourceList) {
        for(Field_Map_Entry__mdt fme : sourceList) {
            if( ( fme.Map_Name__c == null && fme.MasterLabel.startsWithIgnoreCase(mapName+'.'))
                || mapName == fme.Map_Name__c )
            {
                targetList.add( new FieldMapEntry(fme) );
            }
        }
    }

    /**
     * @description 
     * Get a list of field names for the specified destination
     * 
     * @param prefix to add to the field name, like 'Account.'
     * @param destinationSObjectType the object type of the destinatior
     * @return the list of fieldnames with the prefix applied
     */
    public Set<String> getDestinationFieldNames(String prefix,SObjectType destinationSObjectType) {
        final String destEntityName = destinationSObjectType.getDescribe().getName();
        Set<String> destFieldNames = new Set<String>();
        List<FieldMapEntry> fmeList = getFieldMapEntriesByDest( destEntityName );
        if(fieldEntriesForTesting2 != null) {
            // this allows resource injection from a test class
            fmeList = fieldEntriesForTesting2;
        }
        for(FieldMapEntry fme : fmeList)
        {
            if( fme.destinationEntityQualifiedApiName == destEntityName
                && fme.destinationFieldQualifiedApiName != null ) 
            {
                destFieldNames.add(prefix+fme.destinationFieldQualifiedApiName);
            }
        }
        return destFieldNames;
    }

    private List<FieldMapEntry> getFieldMapEntriesBySource( String sourceEntityName )
    {
        List<FieldMapEntry> fmeList = fieldEntriesBySourceMap.get( sourceEntityName );
        if(fmeList == null) {
            fmeList = new List<FieldMapEntry>();
            Map<String,String> masterLabelLikeMap = (new Map<String,String>{
                mapName => '%',
                null => mapName+'.%'
            });
            for(String xmapName : masterLabelLikeMap.keySet()) {
                String masterLabelLike = masterLabelLikeMap.get(xmapName);
                addAll( fmeList, mapName, [
                    select
                        Map_Name__c,
                        MasterLabel,
                        Source_Entity__r.QualifiedApiName,
                        Source_Field__r.QualifiedApiName,
                        Destination_Entity__c,
                        Destination_Field__c,
                        Default_Value__c,
                        Nullable__c,
                        Overwritable__c,
                        Required__c,
                        Sequence_Number__c
                    from User_Field_Map_Entry__mdt 
                    where Source_Entity__r.QualifiedApiName = :sourceEntityName
                        and Map_Name__c = :xmapName
                        and MasterLabel like :masterLabelLike
                        and Source_Field__c != null ] );
                addAll( fmeList, mapName, [
                    select
                        Map_Name__c,
                        MasterLabel,
                        Source_Entity__r.QualifiedApiName,
                        Source_Field__r.QualifiedApiName,
                        Destination_Entity__r.QualifiedApiName,
                        Destination_Field__r.QualifiedApiName,
                        Default_Value__c,
                        Nullable__c,
                        Overwritable__c,
                        Required__c,
                        Sequence_Number__c
                    from Field_Map_Entry__mdt 
                    where Source_Entity__r.QualifiedApiName = :sourceEntityName
                        and Map_Name__c = :xmapName
                        and MasterLabel like :masterLabelLike
                        and Source_Field__c != null ] );
            }
            fieldEntriesBySourceMap.put( sourceEntityName, fmeList);
        }
        return fmeList;
    }

    private List<FieldMapEntry> getFieldMapEntriesByDest(SObject dest) {
        List<FieldMapEntry> retval = null;
        if(dest != null) {
            retval = getFieldMapEntriesByDest(dest.getSObjectType().getDescribe().getName());
        }
        return retval;
    }

    private List<FieldMapEntry> getFieldMapEntriesByDest(final String destinationEntityName) {
        List<FieldMapEntry> retval = fieldEntriesMap.get(destinationEntityName);
        if(retval == null) {
            retval = new List<FieldMapEntry>();
            switch on destinationEntityName {
                when 'Event','Task','User' {
                    addAll(retval,mapName,[
                        select
                            Map_Name__c,
                            MasterLabel,
                            Source_Entity__r.QualifiedApiName,
                            Source_Field__r.QualifiedApiName,
                            Destination_Entity__c,
                            Destination_Field__c,
                            Default_Value__c,
                            Nullable__c,
                            Overwritable__c,
                            Required__c,
                            Sequence_Number__c
                        from User_Field_Map_Entry__mdt 
                        where Destination_Entity__c = :destinationEntityName
                            and Map_Name__c in (null,:mapName)
                            and Destination_Field__c != null
                        // doing an or selection causes an internal salesforce error
                        //                    and (Source_Entity__r.QualifiedApiName in :sourceEntitySet OR Default_Value__c != null)
                        order by Sequence_Number__c ASC NULLS LAST ] );
                }
                when else  {
                    addAll(retval,mapName,[
                        select
                            Map_Name__c,
                            MasterLabel,
                            Source_Entity__r.QualifiedApiName,
                            Source_Field__r.QualifiedApiName,
                            Destination_Entity__r.QualifiedApiName,
                            Destination_Field__r.QualifiedApiName,
                            Default_Value__c,
                            Nullable__c,
                            Overwritable__c,
                            Required__c,
                            Sequence_Number__c
                        from Field_Map_Entry__mdt 
                        where Destination_Entity__r.QualifiedApiName = :destinationEntityName
                            and Map_Name__c in (null,:mapName)
                            and Destination_Field__c != null
                        // doing an or selection causes an internal salesforce error
                        //                    and (Source_Entity__r.QualifiedApiName in :sourceEntitySet OR Default_Value__c != null)
                        order by Sequence_Number__c ASC NULLS LAST ] );
                }
            }
            fieldEntriesMap.put(destinationEntityName,retval);
        }
        return retval;
    }

    @TestVisible
    private class FieldMapEntry {
        @TestVisible
        private String sourceEntityQualifiedApiName;
        @TestVisible
        private String sourceFieldQualifiedApiName;
        @TestVisible
        private String destinationEntityQualifiedApiName;
        @TestVisible
        private String destinationFieldQualifiedApiName;
        @TestVisible
        private String defaultValue;
        @TestVisible
        private Boolean nullable;
        @TestVisible
        private Boolean overwritable;
        @TestVisible
        private Boolean required;
        @TestVisible
        private Decimal sequenceNumber;
        
        @TestVisible
        FieldMapEntry(
            String sourceEntityQualifiedApiName,
            String sourceFieldQualifiedApiName,
            String destinationEntityQualifiedApiName,
            String destinationFieldQualifiedApiName,
            String defaultValue,
            Boolean nullable,
            Boolean overwritable,
            Boolean required,
            Decimal sequenceNumber )
        {
            this.sourceEntityQualifiedApiName = sourceEntityQualifiedApiName;
            this.sourceFieldQualifiedApiName = sourceFieldQualifiedApiName;
            this.destinationEntityQualifiedApiName = destinationEntityQualifiedApiName;
            this.destinationFieldQualifiedApiName = destinationFieldQualifiedApiName;
            this.defaultValue = defaultValue;
            this.nullable = nullable;
            this.overwritable = overwritable;
            this.required = required;
            this.sequenceNumber = sequenceNumber;
        }
        
        FieldMapEntry(Field_Map_Entry__mdt value) {
            String sourceEntityQualifiedApiName = null;
            if(value.Source_Entity__r != null) {
                sourceEntityQualifiedApiName = value.Source_Entity__r.QualifiedApiName;
            }
            this.sourceEntityQualifiedApiName = sourceEntityQualifiedApiName;
            String sourceFieldQualifiedApiName = null;
            if(value.Source_Field__r != null) {
                sourceFieldQualifiedApiName = value.Source_Field__r.QualifiedApiName;
            }
            this.sourceFieldQualifiedApiName = sourceFieldQualifiedApiName;
            String destinationEntityQualifiedApiName = null;
            if(value.Destination_Entity__r != null) {
                destinationEntityQualifiedApiName = value.Destination_Entity__r.QualifiedApiName;
            }
            this.destinationEntityQualifiedApiName = destinationEntityQualifiedApiName;
            String destinationFieldQualifiedApiName = null;
            if(value.Destination_Field__r != null) {
                destinationFieldQualifiedApiName = value.Destination_Field__r.QualifiedApiName;
            }
            this.destinationFieldQualifiedApiName = destinationFieldQualifiedApiName;
            this.defaultValue = value.Default_Value__c;
            this.nullable = value.Nullable__c;
            this.overwritable = value.Overwritable__c;
            this.required = value.Required__c;
            this.sequenceNumber = value.Sequence_Number__c;
        }

        FieldMapEntry(User_Field_Map_Entry__mdt value) {
            String sourceEntityQualifiedApiName = null;
            if(value.Source_Entity__r != null) {
                sourceEntityQualifiedApiName = value.Source_Entity__r.QualifiedApiName;
            }
            this.sourceEntityQualifiedApiName = sourceEntityQualifiedApiName;
            String sourceFieldQualifiedApiName = null;
            if(value.Source_Field__r != null) {
                sourceFieldQualifiedApiName = value.Source_Field__r.QualifiedApiName;
            }
            this.sourceFieldQualifiedApiName = sourceFieldQualifiedApiName;
            this.destinationEntityQualifiedApiName = value.Destination_Entity__c;
            this.destinationFieldQualifiedApiName = value.Destination_Field__c;
            this.defaultValue = value.Default_Value__c;
            this.nullable = value.Nullable__c;
            this.overwritable = value.Overwritable__c;
            this.required = value.Required__c;
            this.sequenceNumber = value.Sequence_Number__c;
        }

        @TestVisible
        void copyField(SObject source, SObject dest, List<String> errors) {
            try {
                Object value = null;
                if(source != null && sourceFieldQualifiedApiName != null) {
                    value = source.get(sourceFieldQualifiedApiName);
                }
                
                Object currentValue = null;
                Object defaultValue = this.defaultValue;
                try {
                    currentValue = dest.get(destinationFieldQualifiedApiName);
                    if(currentValue != null && ! nullable) {
                        defaultValue = currentValue;
                    }
                    else if(defaultValue != null) {
                        defaultValue = Field_Map.convertText(this.defaultValue,dest,destinationFieldQualifiedApiName);
                    }
                }
                catch(Exception ex1) {
                    System.debug('Failed to retrieve current value from: '+this+'\n'+ex1);
                }
                if(value == null && defaultValue != null) {
                    value = defaultValue;
                }
                if( (overwritable || currentValue == null)
                    && (nullable || value != null) ) 
                {
                    dest.put(destinationFieldQualifiedApiName, value );
                    currentValue = value;
                }
                //Create an error when mandatory field is not populated
                if(currentValue == null && required == true )
                {
                    errors.add( 'Required Field on ' + destinationEntityQualifiedApiName + ' was not populated: ' + destinationFieldQualifiedApiName );
                }
            }
            catch(Exception ex) {
                System.debug('Failed to update order from: '+this+'\n'+ex);
            }
        } 
    }
}