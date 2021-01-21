/**
 * Test class for Database Utilities.
 * 
 * @version 2019-01-21
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2019-01-21 Created
 */
@IsTest
private class DatabaseUtilitiesTest {
    static final String CPU_TIME_RE = 'Limits: CPU Time: [0-9]* out of 0';
    static final Pattern CPU_TIME_PATTERN = Pattern.compile(CPU_TIME_RE);

    static void cpuTimeCheck(String actual,String message) {
        if(! CPU_TIME_PATTERN.matcher(actual).matches()) {
            System.assertEquals(CPU_TIME_RE,actual,message);
        }
    }

    @isTest
    static void deactivateAllTest() {
        LimitHelper.throwsExceptionDefault = true;
        List<Contact> contacts = ( new List<Contact>{
            new Contact(LastName='Fudge'),
            new Contact(LastName='Chocolate')} );
        Test.startTest();
        // insert tests
        LimitHelper.cpuTimeReserved = Limits.getLimitCpuTime();
        for(Database.SaveResult sr : DatabaseUtilities.insertDeactivateAll(contacts, false)) {
            System.assertEquals(false,sr.isSuccess(),'Should hit cpu limit');
            System.assertEquals(1,sr.getErrors().size(),'Expected cpu limit errors');
            for(Database.Error e : sr.getErrors()) {
                cpuTimeCheck(e.getMessage(),'1.SaveResult.getErrors()');
            }
            System.assertEquals(null,sr.getId(),'We should not have an Id on failure.');
        }
        LimitHelper.cpuTimeReserved = 0;
        for(Database.SaveResult r : DatabaseUtilities.insertDeactivateAll(contacts, true)) {
            System.assertEquals(true,r.isSuccess());
        }

        // update tests
        LimitHelper.cpuTimeReserved = Limits.getLimitCpuTime();
        for(Database.SaveResult sr : DatabaseUtilities.updateDeactivateAll(contacts, false)) {
            System.assertEquals(false,sr.isSuccess(),'Should hit cpu limit');
            System.assertEquals(1,sr.getErrors().size(),'Expected cpu limit errors');
            for(Database.Error e : sr.getErrors()) {
                cpuTimeCheck(e.getMessage(),'2.SaveResult.getErrors()');
            }
            System.assertEquals(null,sr.getId(),'We should not have an Id on failure.');
        }
        LimitHelper.cpuTimeReserved = 0;
        for(Database.SaveResult r : DatabaseUtilities.updateDeactivateAll(contacts, true)) {
            System.assertEquals(true,r.isSuccess());
        }

        // upsert tests
        LimitHelper.cpuTimeReserved = Limits.getLimitCpuTime();
        for(Database.UpsertResult ur : DatabaseUtilities.upsertDeactivateAll(contacts, false)) {
            System.assertEquals(false,ur.isSuccess(),'Should hit cpu limit');
            System.assertEquals(1,ur.getErrors().size(),'Expected cpu limit errors');
            for(Database.Error e : ur.getErrors()) {
                cpuTimeCheck(e.getMessage(),'1.UpsertResult.getErrors()');
            }
            System.assertEquals(null,ur.getId(),'We should not have an Id on failure.');
        }
        LimitHelper.cpuTimeReserved = 0;
        for(Database.UpsertResult r : DatabaseUtilities.upsertDeactivateAll(contacts, true)) {
            System.assertEquals(true,r.isSuccess());
        }

        // delete test
        LimitHelper.cpuTimeReserved = Limits.getLimitCpuTime();
        for(Database.DeleteResult dr : DatabaseUtilities.deleteDeactivateAll(contacts,false)) {
            System.assertEquals(false,dr.isSuccess(),'Should hit cpu limit');
            System.assertEquals(1,dr.getErrors().size(),'Expected cpu limit errors');
            for(Database.Error e : dr.getErrors()) {
                cpuTimeCheck(e.getMessage(),'1.DeleteResult.getErrors()');
            }
            System.assertEquals(null,dr.getId(),'We should not have an Id on failure.');
        }
        LimitHelper.cpuTimeReserved = 0;
        for(Database.DeleteResult r : DatabaseUtilities.deleteDeactivateAll(contacts, true)) {
            System.assertEquals(true,r.isSuccess());
        }

        // error tests
        for(Database.SaveResult r : DatabaseUtilities.insertDeactivateAll(contacts, false)) {
            System.assertEquals(false,r.isSuccess());
        }
        for(Database.SaveResult r : DatabaseUtilities.updateDeactivateAll(contacts, false)) {
            System.assertEquals(false,r.isSuccess());
        }
        for(Database.UpsertResult r : DatabaseUtilities.upsertDeactivateAll(contacts, false)) {
            System.assertEquals(false,r.isSuccess());
        }
        for(Database.DeleteResult r : DatabaseUtilities.deleteDeactivateAll(contacts, false)) {
            System.assertEquals(false,r.isSuccess());
        }

        // undelete test
        LimitHelper.cpuTimeReserved = Limits.getLimitCpuTime();
        for(Database.UndeleteResult ur : DatabaseUtilities.undeleteDeactivateAll(contacts,false)) {
            System.assertEquals(false,ur.isSuccess(),'Should hit cpu limit');
            System.assertEquals(1,ur.getErrors().size(),'Expected cpu limit errors');
            for(Database.Error e : ur.getErrors()) {
                cpuTimeCheck(e.getMessage(),'1.UndeleteResult.getErrors()');
            }
            System.assertEquals(null,ur.getId(),'We should not have an Id on failure.');
        }
        LimitHelper.cpuTimeReserved = 0;
        for(Database.UndeleteResult r : DatabaseUtilities.undeleteDeactivateAll(contacts, true)) {
            System.assertEquals(true,r.isSuccess());
        }

        Test.stopTest();
    }

    @isTest
    static void allowFieldTruncationTest() {
        AbstractTrigger.setBooleanSettings('DeactivateAll',true);
        final String s64 = '0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF';
        final String s512 = s64+s64+s64+s64+s64+s64+s64+s64;
        List<Contact> contacts = ( new List<Contact>{
            new Contact(LastName='a'+s512),
            new Contact(LastName='b'+s512) } );
        for(Database.SaveResult r : DatabaseUtilities.insertAllowFieldTruncation(new List<Contact>{ contacts[0]},false) ) {
            System.assertEquals(true,r.isSuccess());
        } 
        List<Contact> contacts2 = contacts.deepclone(true,true,true);
        contacts2[1].LastName='';
        try {
            DatabaseUtilities.upsertAllowFieldTruncation(contacts2,true);
        }
        catch(Exception ex) {}
        System.assertNotEquals(null,contacts2[0].Id);
        System.assertEquals(null,contacts2[1].Id);
        for(Database.UpsertResult r : DatabaseUtilities.upsertAllowFieldTruncation(contacts,false) ) {
            System.assertEquals(true,r.isSuccess());
        }
        for(Database.SaveResult r : DatabaseUtilities.updateAllowFieldTruncation(contacts,false) ) {
            System.assertEquals(true,r.isSuccess());
        }
    }

    @isTest
    static void allowFieldTruncationTest2() {
        AbstractTrigger.setBooleanSettings('DeactivateAll',true);
        final String s64 = '0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF';
        final String s512 = s64+s64+s64+s64+s64+s64+s64+s64;
        List<Contact> contacts = ( new List<Contact>{
            new Contact(LastName='a'+s512),
            new Contact(LastName='b'+s512) } );
        for(Database.SaveResult r : DatabaseUtilities.insertAllowFieldTruncation(new List<Contact>{ contacts[0]},false) ) {
            System.assertEquals(true,r.isSuccess());
        } 
        List<Contact> contacts2 = contacts.deepclone(true,true,true);
        contacts2[1].LastName='';
        try {
            DatabaseUtilities.insertOrUpdate(contacts2,true,true);
        }
        catch(Exception ex) {}
        System.assertNotEquals(null,contacts2[0].Id);
        System.assertEquals(null,contacts2[1].Id);
        for(Database.SaveResult r : DatabaseUtilities.insertOrUpdate(contacts,true,false) ) {
            System.assertEquals(true,r.isSuccess());
        }
        for(Database.SaveResult r : DatabaseUtilities.updateAllowFieldTruncation(contacts,false) ) {
            System.assertEquals(true,r.isSuccess());
        }
    }

    @isTest
    static void updateIsSuccessTest() {
        SObject o = new User();
        Database.SaveResult r = Database.update(new List<SObject>{o},false)[0];
        Boolean success = DatabaseUtilities.updateIsSuccess( r, o, 'Failed' );
        System.assertEquals(false, success);
    }

    @isTest 
    static void simpleErrorListTest() {
        List<Contact> contacts = ( new List<Contact>{
            new Contact(LastName='Fudge'),
            new Contact(LastName='Chocolate'),
            new Contact() } );
        List<Database.SaveResult> saveResults = Database.insert(contacts,false);
        System.assertEquals(contacts.size(),saveResults.size(),'Our lists sizes should match');
        System.assertEquals(true,saveResults[0].isSuccess(),'Expected success');
        System.assertEquals(true,saveResults[1].isSuccess(),'Expected success');
        System.assertEquals(false,saveResults[2].isSuccess(),'Expected failure');
        List<String> errorList = new List<String>();
        DatabaseUtilities.SimpleErrorList simpleErrors = new DatabaseUtilities.SimpleErrorList(errorList,true);
        List<Contact> contactsClone = contacts.clone();
        List<Database.SaveResult> filterResults = (List<Database.SaveResult>)DatabaseUtilities.filterResults(
            saveResults,
            contactsClone,
            simpleErrors,
            'Anything' );
        System.assertEquals(2,filterResults.size(),'only expected 2 successes');
        System.assertEquals(2,contactsClone.size(),'only expected 2 successes');
        System.assertEquals(true,filterResults[0].isSuccess(),'Expected success');
        System.assertEquals(true,filterResults[1].isSuccess(),'Expected success');
        System.assertEquals(contacts[0],contactsClone[0],'expected lists to match');
        System.assertEquals(contacts[1],contactsClone[1],'expected lists to match');
        System.assertEquals(1,errorList.size(),'expected an error');
        System.assert(String.isNotBlank(errorList[0]),'Expected an error message');
    }
}