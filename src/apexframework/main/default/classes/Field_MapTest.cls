// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * @description
 * Test class for Field_Map
 *
 * @group ApexFrameworkTest
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2019-12-19 - Created
 * @since 2020-03-05 US244638 US245940 - added tests using the user field map 
 * @since 2021-04-06 - Increase test coverage
 * @since 2022-08-04 - Renamed "Test_Map" to "Test Map"
 * @since 2022-09-09 update for ApexDox commenting
 */
@isTest
private class Field_MapTest {

    private static Field_Map contactAccountFieldMap {
        get {
            if(contactAccountFieldMap == null) {
                contactAccountFieldMap = new Field_Map('contactAccount');
                List<String> jsonList = (new List<String>{
                    '{',
                        '"attributes" : { "type" : "Field_Map_Entry__mdt" },',
                        '"Source_Entity__c" : "Contact",',
                        '"Source_Field__c" : "Contact.LastName",',
                        '"Destination_Entity__c" : "Account",',
                        '"Destination_Field__c" : "Account.Name",',
                        '"Default_Value__c" : "fudge",',
                        '"Nullable__c" : false,',
                        '"Overwritable__c" : true,',
                        '"Required__c" : false,',
                        '"Source_Entity__r" : {',
                            '"attributes" : { "type" : "EntityDefinition" },',
                            '"DurableId" : "Contact",',
                            '"QualifiedApiName" : "Contact"',
                        '},',
                        '"Source_Field__r" : {',
                            '"attributes" : { "type" : "FieldDefinition" },',
                            '"DurableId" : "Contact.LastName",',
                            '"QualifiedApiName" : "LastName"',
                        '},',
                        '"Destination_Entity__r" : {',
                            '"attributes" : { "type" : "EntityDefinition" },',
                            '"DurableId" : "Account",',
                            '"QualifiedApiName" : "Account"',
                        '},',
                        '"Destination_Field__r" : {',
                            '"attributes" : { "type" : "FieldDefinition" },',
                            '"DurableId" : "Account.Name",',
                            '"QualifiedApiName" : "Name"',
                        '}',
                    '}'
                });
                String jsonValue = String.join(jsonList,'\n');
                Field_Map_Entry__mdt contactAccountFieldMapEntry = (Field_Map_Entry__mdt)JSON.deserialize(jsonValue, Field_Map_Entry__mdt.class);
                contactAccountFieldMap.fieldEntriesForTesting = (new List<Field_Map_Entry__mdt>{contactAccountFieldMapEntry});
            }
            return contactAccountFieldMap;
        }
        set;
    }

    @isTest
    private static void testMap() {
        Field_Map fm = new Field_Map('Test Map');
        contactAccountFieldMap.fieldEntriesForTesting2 = (new List<Field_Map.FieldMapEntry>{
            new Field_Map.FieldMapEntry(
                Contact.class.getName(),
                'LastName',
                Account.class.getName(),
                'Name',
                'fudge',
                false,
                true,
                true,
                1.0 )
        } );

        Test.startTest();
        Contact sourceContact = new Contact();
        Contact destContact = new Contact(Title='Dr');
        List<String> errors = fm.copyFields(sourceContact, destContact);
        System.assertEquals(0,errors.size());
        System.assertEquals(true,destContact.DoNotCall);
        System.assertEquals('noone@nowhere.com',destContact.Email);
        System.assertEquals('Dr',destContact.Title);
        
        User destUser = new User(Title='Dr');
        errors = fm.copyFields(sourceContact, destUser);
        System.assertEquals(0,errors.size());
        System.assertEquals(true,destUser.ReceivesInfoEmails);
        System.assertEquals('noone@nowhere.com',destUser.Email);
        System.assertEquals('Dr',destUser.Title);

        sourceContact.DoNotCall=false;
        sourceContact.Email='someone@somewhere.com';
        sourceContact.Title = 'Mr';
        destContact = new Contact(Title='Dr');
        errors = fm.copyFields(sourceContact, destContact);
        System.assertEquals(0,errors.size());
        System.assertEquals(true,destContact.DoNotCall);
        System.assertEquals('someone@somewhere.com',destContact.Email);
        System.assertEquals('Dr',destContact.Title);

        destUser = new User(Title='Dr');
        errors = fm.copyFields(sourceContact, destUser);
        System.assertEquals(0,errors.size());
        System.assertEquals(true,destUser.ReceivesInfoEmails);
        System.assertEquals('someone@somewhere.com',destUser.Email);
        System.assertEquals('Dr',destUser.Title);

        destContact = new Contact(
            DoNotCall=false,
            Email='someoneelse@somewhereelse.com',
            Title = null );
        errors = fm.copyFields(sourceContact, destContact);
        System.assertEquals(0,errors.size());
        System.assertEquals(true,destContact.DoNotCall);
        System.assertEquals('someone@somewhere.com',destContact.Email);
        System.assertEquals('Mr',destContact.Title);
        
        destUser = new User(
            Email='someoneelse@somewhereelse.com',
            ReceivesInfoEmails=false,
            Title = null );
        errors = fm.copyFields(sourceContact, destUser);
        System.assertEquals(0,errors.size());
        System.assertEquals(true,destUser.ReceivesInfoEmails);
        System.assertEquals('someone@somewhere.com',destUser.Email);
        System.assertEquals('Mr',destUser.Title);
        
        sourceContact.Title = null;
        destContact = new Contact(
            DoNotCall=false,
            Email='someoneelse@somewhereelse.com',
            Title = null );
        errors = fm.copyFields(sourceContact, destContact);
        System.assertEquals(1,errors.size());
        System.assertEquals(true,destContact.DoNotCall);
        System.assertEquals('someone@somewhere.com',destContact.Email);
        System.assertEquals(null,destContact.Title);
        
        sourceContact.Title = null;
        destUser = new User(
            Email='someoneelse@somewhereelse.com',
            ReceivesInfoEmails=false,
            Title = null );
        errors = fm.copyFields(sourceContact, destUser);
        System.assertEquals(1,errors.size());
        System.assertEquals(true,destUser.ReceivesInfoEmails);
        System.assertEquals('someone@somewhere.com',destUser.Email);
        System.assertEquals(null,destUser.Title);

        sourceContact = new Contact(LastName='Bob');
        Account destAccount = new Account();
        errors.clear();
        errors = contactAccountFieldMap.copyFields(sourceContact, destAccount);
        System.assertEquals(0,errors.size(),'no errors expected');
        System.assertEquals('Bob',destAccount.Name,'destAccount.Name');
        Test.stopTest();
    }
   
    @isTest
    private static void getDestinationEntityMapTest() {
        Field_Map fm = new Field_Map('Test Map');
        String contactName = Contact.SObjectType.getDescribe().getName();
        Test.startTest();
        Map<String,SObject> entityMap = fm.getDestinationEntityMap(Contact.SObjectType);
        System.assert(entityMap.containsKey(contactName),'Expected '+contactName+' in '+entityMap);
        System.assert(entityMap.get(contactName) instanceof Contact,'Expected to be instance of contact: '+entityMap.get(Contact.class.getName()));
        Test.stopTest();
    }

    @isTest
    private static void getDestinationFieldNamesTest() {
        Field_Map fm = new Field_Map('Test Map');

        Test.startTest();
        List<String> destFieldNames = new List<String>(fm.getDestinationFieldNames('',Contact.SObjectType));
        destFieldNames.sort();
        System.assertEquals('DoNotCall,Email,Title',String.join(destFieldNames,','));
        destFieldNames = new List<String>(fm.getDestinationFieldNames('',User.SObjectType));
        destFieldNames.sort();
        System.assertEquals('Email,ReceivesInfoEmails,Title',String.join(destFieldNames,','));
        destFieldNames = new List<String>(contactAccountFieldMap.getDestinationFieldNames('',Account.SObjectType));
        System.assertEquals('Name',String.join(destFieldNames,','));
        Test.stopTest();
    }
    
    @isTest
    private static void getSourceFieldNamesTest() {
        Field_Map fm = new Field_Map('Test Map');
        Test.startTest();
        List<String> sourceFieldNames = new List<String>(fm.getSourceFieldNames('',Contact.SObjectType));
        sourceFieldNames.sort();
        System.assertEquals('Email,Title',String.join(sourceFieldNames,','));
        sourceFieldNames = new List<String>(contactAccountFieldMap.getSourceFieldNames('',Contact.SObjectType));
        System.assertEquals('LastName',String.join(sourceFieldNames,','));
        Test.stopTest();
    }

    @isTest
    private static void copyFieldTest() {
        Field_Map.FieldMapEntry fme = new Field_Map.FieldMapEntry(
            Contact.class.getName(),
            'LastName',
            Account.class.getName(),
            'Name',
            'fudge',
            false,
            true,
            true,
            1.0 );
        Contact src = new Contact(LastName='Anything');
        Account dest = new Account();
        List<String> errors = new List<String>();
        Test.startTest();
        fme.copyField(src,dest,errors);
        System.assertEquals(0,errors.size(),'expected no errors');
        System.assertEquals('Anything',dest.Name,'dest.Name');
        fme.copyField(src,null,errors);
        System.assertEquals(0,errors.size(),'expected no errors');
        fme.copyField(new Opportunity(),dest,errors);
        System.assertEquals(0,errors.size(),'expected no errors');
        Test.stopTest();
    }

    @isTest
    private static void convertTextTest() {
        Test.startTest();
        Decimal value = (Decimal)Field_Map.convertText('0.00',new Opportunity(),'Amount');
        System.assertEquals(0.00,value,'convertTest(0.00,...)');
        Boolean value2 = (Boolean)Field_Map.convertText('true',new Contact(),'DoNotCall');
        System.assertEquals(true,value2,'convertTest(true,...)');
        Test.stopTest();
    }

}