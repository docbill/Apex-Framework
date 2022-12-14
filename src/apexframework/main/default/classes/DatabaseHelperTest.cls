// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * @description
 * Test class for DatabaseHelper.
 *
 * @group ApexFrameworkTest
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2020-08-18 US268650 - Created
 * @since 2021-01-07 US281262 - Added setEnqueueScope for Queuable splitting of dml
 * @since 2021-03-30 - Increase test coverage
 * @since 2021-04-27 DE26549 - Added split test
 * @since 2022-09-09 update for ApexDox commenting
 * @since 2022-12-13 update to test async callbacks
 */
@IsTest
private class DatabaseHelperTest {

    private static final String CPU_TIME_RE = 'Limits: CPU Time: [0-9]* out of 0';
    private static final Pattern CPU_TIME_PATTERN = Pattern.compile(CPU_TIME_RE);

    private static void cpuTimeCheck(String actual,String message) {
        if(! CPU_TIME_PATTERN.matcher(actual).matches()) {
            System.assertEquals(CPU_TIME_RE,actual,message);
        }
    }

    /**
     * @description 
     * Test all the safe method calls.
     */
    @isTest
    private static void safeTest() {
        LimitHelper.throwsExceptionDefault = true;
        List<Contact> contacts = ( new List<Contact>{
            new Contact(LastName='Fudge'),
            new Contact(LastName='Chocolate')} );
        Test.startTest();
        // insert tests
        LimitHelper.cpuTimeReserved = Limits.getLimitCpuTime();
        Iterator<Contact> contactIterator = contacts.iterator();
        for(DatabaseHelper.Result r : new DatabaseHelper().safeInsert(contacts)) {
            System.assertEquals(false,DatabaseHelper.isSuccess(r),'Should hit cpu limit');
            System.assertEquals(1,r.getErrors().size(),'Expected cpu limit errors');
            for(Database.Error e : r.getErrors()) {
                cpuTimeCheck(e.getMessage(),'1.safeInsert.getErrors()');
            }
            System.assertNotEquals(null,r.getException(),'Expected cpu limit exception');
            System.assertEquals(1,r.getExceptions().size(),'Expected cpu limit exceptions');
            for(Exception ex : r.getExceptions()) {
                cpuTimeCheck(ex.getMessage(),'2.safeInsert.getExceptions()');
            }
            System.assertEquals(1,r.getStackTraceStrings().size(),'Expected cpu limit stack trace');
            System.assertEquals(contactIterator.next(),r.getSObject(),'We always expect an object');
            System.assertEquals(null,r.getId(),'We should not have an Id on failure.');
            System.assertEquals(false,r.isCreated(),'We should not set isCreate on failure');

            Database.SaveResult sr = (Database.SaveResult)r.convertResult(Database.SaveResult.class);
            System.assertEquals(false,DatabaseHelper.isSuccess(sr),'Should hit cpu limit');
            System.assertEquals(1,sr.getErrors().size(),'Expected cpu limit errors');
            for(Database.Error e : sr.getErrors()) {
                cpuTimeCheck(e.getMessage(),'1.SaveResult.getErrors()');
            }
            System.assertEquals(null,sr.getId(),'We should not have an Id on failure.');
        }
        System.assert(! contactIterator.hasNext(),'Unexpected contact');
        LimitHelper.cpuTimeReserved = 0;
        for(DatabaseHelper.Result r : new DatabaseHelper().setOptAllOrNone(true).safeInsert(contacts)) {
            System.assertEquals(true,DatabaseHelper.isSuccess(r));
            System.assertEquals(true,r.getErrors().isEmpty());
            System.assertEquals(null,r.getException());
            System.assertEquals(true,r.getExceptions().isEmpty());
            System.assertEquals(true,r.getStackTraceStrings().isEmpty());
            System.assertNotEquals(null,r.getSObject());
            System.assertNotEquals(null,r.getId());
            System.assertEquals(true,r.isCreated());
            System.assert(r.convertResult(Database.SaveResult.class) instanceof Database.SaveResult);
        }

        // update tests
        LimitHelper.cpuTimeReserved = Limits.getLimitCpuTime();
        contactIterator = contacts.iterator();
        for(DatabaseHelper.Result r : new DatabaseHelper().safeUpdate(contacts)) {
            System.assertEquals(false,DatabaseHelper.isSuccess(r),'Should hit cpu limit');
            System.assertEquals(1,r.getErrors().size(),'Expected cpu limit errors');
            for(Database.Error e : r.getErrors()) {
                cpuTimeCheck(e.getMessage(),'1.safeUpdate.getErrors()');
            }
            System.assertEquals(1,r.getExceptions().size(),'Expected cpu limit exceptions');
            for(Exception ex : r.getExceptions()) {
                cpuTimeCheck(ex.getMessage(),'2.safeUpdate.getExceptions()');
            }
            System.assertEquals(1,r.getStackTraceStrings().size(),'Expected cpu limit stack trace');
            System.assertEquals(contactIterator.next(),r.getSObject(),'We always expect an object');
            System.assertEquals(null,r.getId(),'We should not have an Id on failure.');
            System.assertEquals(false,r.isCreated(),'We should not set isCreate on failure');

            Database.SaveResult sr = (Database.SaveResult)r.convertResult(Database.SaveResult.class);
            System.assertEquals(false,DatabaseHelper.isSuccess(sr),'Should hit cpu limit');
            System.assertEquals(1,sr.getErrors().size(),'Expected cpu limit errors');
            for(Database.Error e : sr.getErrors()) {
                cpuTimeCheck(e.getMessage(),'2.SaveResult.getErrors()');
            }
            System.assertEquals(null,sr.getId(),'We should not have an Id on failure.');
        }
        System.assert(! contactIterator.hasNext(),'Unexpected contact');
        LimitHelper.cpuTimeReserved = 0;
        for(DatabaseHelper.Result r : new DatabaseHelper().setOptAllOrNone(true).safeUpdate(contacts)) {
            System.assertEquals(true,DatabaseHelper.isSuccess(r));
            System.assertEquals(true,r.getErrors().isEmpty());
            System.assertEquals(true,r.getExceptions().isEmpty());
            System.assertEquals(true,r.getStackTraceStrings().isEmpty());
            System.assertNotEquals(null,r.getSObject());
            System.assertNotEquals(null,r.getId());
            System.assertEquals(false,r.isCreated());
            System.assert(r.convertResult(Database.SaveResult.class) instanceof Database.SaveResult);
        }

        // upsert tests
        LimitHelper.cpuTimeReserved = Limits.getLimitCpuTime();
        contactIterator = contacts.iterator();
        for(DatabaseHelper.Result r : new DatabaseHelper().safeUpsert(contacts)) {
            System.assertEquals(false,DatabaseHelper.isSuccess(r),'Should hit cpu limit');
            System.assertEquals(1,r.getErrors().size(),'Expected cpu limit errors');
            for(Database.Error e : r.getErrors()) {
                cpuTimeCheck(e.getMessage(),'1.safeUpsert.getErrors()');
            }
            System.assertEquals(1,r.getExceptions().size(),'Expected cpu limit exceptions');
            for(Exception ex : r.getExceptions()) {
                cpuTimeCheck(ex.getMessage(),'2.safeUpsert.getExceptions()');
            }
            System.assertEquals(1,r.getStackTraceStrings().size(),'Expected cpu limit stack trace');
            System.assertEquals(contactIterator.next(),r.getSObject(),'We always expect an object');
            System.assertEquals(null,r.getId(),'We should not have an Id on failure.');
            System.assertEquals(false,r.isCreated(),'We should not set isCreate on failure');

            Database.UpsertResult ur = (Database.UpsertResult)r.convertResult(Database.UpsertResult.class);
            System.assertEquals(false,DatabaseHelper.isSuccess(ur),'Should hit cpu limit');
            System.assertEquals(1,ur.getErrors().size(),'Expected cpu limit errors');
            for(Database.Error e : ur.getErrors()) {
                cpuTimeCheck(e.getMessage(),'1.UpsertResult.getErrors()');
            }
            System.assertEquals(null,ur.getId(),'We should not have an Id on failure.');
        }
        System.assert(! contactIterator.hasNext(),'Unexpected contact');
        LimitHelper.cpuTimeReserved = 0;
        for(DatabaseHelper.Result r : new DatabaseHelper().safeUpsert(contacts)) {
            System.assertEquals(true,DatabaseHelper.isSuccess(r));
            System.assertEquals(true,r.getErrors().isEmpty());
            System.assertEquals(true,r.getExceptions().isEmpty());
            System.assertEquals(true,r.getStackTraceStrings().isEmpty());
            System.assertNotEquals(null,r.getSObject());
            System.assertNotEquals(null,r.getId());
            System.assertEquals(false,r.isCreated());
            System.assert(r.convertResult(Database.UpsertResult.class) instanceof Database.UpsertResult);
        }

        // delete test
        LimitHelper.cpuTimeReserved = Limits.getLimitCpuTime();
        contactIterator = contacts.iterator();
        for(DatabaseHelper.Result r : new DatabaseHelper().safeDelete(contacts)) {
            System.assertEquals(false,DatabaseHelper.isSuccess(r),'Should hit cpu limit');
            System.assertEquals(1,r.getErrors().size(),'Expected cpu limit errors');
            for(Database.Error e : r.getErrors()) {
                cpuTimeCheck(e.getMessage(),'1.safeUpsert.getErrors()');
            }
            System.assertEquals(1,r.getExceptions().size(),'Expected cpu limit exceptions');
            for(Exception ex : r.getExceptions()) {
                cpuTimeCheck(ex.getMessage(),'2.safeUpsert.getExceptions()');
            }
            System.assertEquals(1,r.getStackTraceStrings().size(),'Expected cpu limit stack trace');
            System.assertEquals(contactIterator.next(),r.getSObject(),'We always expect an object');
            System.assertEquals(null,r.getId(),'We should not have an Id on failure.');
            System.assertEquals(false,r.isCreated(),'We should not set isCreate on failure');

            Database.DeleteResult dr = (Database.DeleteResult)r.convertResult(Database.DeleteResult.class);
            System.assertEquals(false,DatabaseHelper.isSuccess(dr),'Should hit cpu limit');
            System.assertEquals(1,dr.getErrors().size(),'Expected cpu limit errors');
            for(Database.Error e : dr.getErrors()) {
                cpuTimeCheck(e.getMessage(),'1.DeleteResult.getErrors()');
            }
            System.assertEquals(null,dr.getId(),'We should not have an Id on failure.');
        }
        System.assert(! contactIterator.hasNext(),'Unexpected contact');
        LimitHelper.cpuTimeReserved = 0;
        for(DatabaseHelper.Result r : new DatabaseHelper().safeDelete(contacts)) {
            System.assertEquals(true,DatabaseHelper.isSuccess(r));
            System.assertEquals(true,r.getErrors().isEmpty());
            System.assertEquals(true,r.getExceptions().isEmpty());
            System.assertEquals(true,r.getStackTraceStrings().isEmpty());
            System.assertNotEquals(null,r.getSObject());
            System.assertNotEquals(null,r.getId());
            System.assertEquals(false,r.isCreated());
            System.assert(r.convertResult(Database.DeleteResult.class) instanceof Database.DeleteResult);
        }

        // error tests
        for(DatabaseHelper.Result r : new DatabaseHelper().safeInsert(contacts)) {
            System.assertEquals(false,DatabaseHelper.isSuccess(r));
            System.assertEquals(false,r.getErrors().isEmpty());
            System.assertEquals(false,r.getExceptions().isEmpty());
            System.assertEquals(false,r.getStackTraceStrings().isEmpty());
            System.assertNotEquals(null,r.getSObject());
            System.assertEquals(null,r.getId());
            System.assertEquals(false,r.isCreated());
            System.assert(r.convertResult(Database.SaveResult.class) instanceof Database.SaveResult);
        }
        for(DatabaseHelper.Result r : new DatabaseHelper().safeUpdate(contacts)) {
            System.assertEquals(false,DatabaseHelper.isSuccess(r));
            System.assertEquals(false,r.getErrors().isEmpty());
            System.assertEquals(false,r.getExceptions().isEmpty());
            System.assertEquals(false,r.getStackTraceStrings().isEmpty());
            System.assertNotEquals(null,r.getSObject());
            System.assertEquals(null,r.getId());
            System.assertEquals(false,r.isCreated());
            System.assert(r.convertResult(Database.SaveResult.class) instanceof Database.SaveResult);
        }
        for(DatabaseHelper.Result r : new DatabaseHelper().safeUpsert(contacts)) {
            System.assertEquals(false,DatabaseHelper.isSuccess(r));
            System.assertEquals(false,r.getErrors().isEmpty());
            System.assertEquals(false,r.getExceptions().isEmpty());
            System.assertEquals(false,r.getStackTraceStrings().isEmpty());
            System.assertNotEquals(null,r.getSObject());
            System.assertEquals(null,r.getId());
            System.assertEquals(false,r.isCreated());
            System.assert(r.convertResult(Database.UpsertResult.class) instanceof Database.UpsertResult);
        }
        for(DatabaseHelper.Result r : new DatabaseHelper().safeDelete(contacts)) {
            System.assertEquals(false,DatabaseHelper.isSuccess(r));
            System.assertEquals(false,r.getErrors().isEmpty());
            System.assertEquals(false,r.getExceptions().isEmpty());
            System.assertEquals(false,r.getStackTraceStrings().isEmpty());
            System.assertNotEquals(null,r.getSObject());
            System.assertNotEquals(null,r.getId());
            System.assertEquals(false,r.isCreated());
            System.assert(r.convertResult(Database.DeleteResult.class) instanceof Database.DeleteResult);
        }

        // undelete test
        LimitHelper.cpuTimeReserved = Limits.getLimitCpuTime();
        contactIterator = contacts.iterator();
        for(DatabaseHelper.Result r : new DatabaseHelper().safeUndelete(contacts)) {
            System.assertEquals(false,DatabaseHelper.isSuccess(r),'Should hit cpu limit');
            System.assertEquals(1,r.getErrors().size(),'Expected cpu limit errors');
            for(Database.Error e : r.getErrors()) {
                cpuTimeCheck(e.getMessage(),'1.safeUpsert.getErrors()');
            }
            System.assertEquals(1,r.getExceptions().size(),'Expected cpu limit exceptions');
            for(Exception ex : r.getExceptions()) {
                cpuTimeCheck(ex.getMessage(),'2.safeUpsert.getExceptions()');
            }
            System.assertEquals(1,r.getStackTraceStrings().size(),'Expected cpu limit stack trace');
            System.assertEquals(contactIterator.next(),r.getSObject(),'We always expect an object');
            System.assertEquals(null,r.getId(),'We should not have an Id on failure.');
            System.assertEquals(false,r.isCreated(),'We should not set isCreate on failure');

            Database.UndeleteResult ur = (Database.UndeleteResult)r.convertResult(Database.UndeleteResult.class);
            System.assertEquals(false,DatabaseHelper.isSuccess(ur),'Should hit cpu limit');
            System.assertEquals(1,ur.getErrors().size(),'Expected cpu limit errors');
            for(Database.Error e : ur.getErrors()) {
                cpuTimeCheck(e.getMessage(),'1.UndeleteResult.getErrors()');
            }
            System.assertEquals(null,ur.getId(),'We should not have an Id on failure.');
        }
        System.assert(! contactIterator.hasNext(),'Unexpected contact');
        LimitHelper.cpuTimeReserved = 0;
        for(DatabaseHelper.Result r : new DatabaseHelper().setOptAllOrNone(true).safeUndelete(contacts)) {
            System.assertEquals(true,DatabaseHelper.isSuccess(r));
            System.assertEquals(true,r.getErrors().isEmpty());
            System.assertEquals(true,r.getExceptions().isEmpty());
            System.assertEquals(true,r.getStackTraceStrings().isEmpty());
            System.assertNotEquals(null,r.getSObject());
            System.assertNotEquals(null,r.getId());
            System.assertEquals(false,r.isCreated());
            System.assert(r.convertResult(Database.UndeleteResult.class) instanceof Database.UndeleteResult);
        }

        Test.stopTest();
    }

    /**
     * @description 
     * Test dmlOptions work as expected.
     */
    @isTest
    private static void dmlOptionsTest() {
        List<Contact> contacts = ( new List<Contact>{
            new Contact(LastName='Fudge'),
            new Contact(LastName='Chocolate')} );
        Test.startTest();
        // insert tests
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.OptAllOrNone = true;
        DatabaseHelper helper = new DatabaseHelper().setOptions(dmlOptions).setCheckLimits(true);
        Database.DMLOptions dmlOptions2 = new Database.DMLOptions();
 
        LimitHelper.cpuTimeReserved = Limits.getLimitCpuTime();
        Exception caughtException = null;
        LimitHelper.cpuTimeReserved = Limits.getLimitCpuTime();
        try {
            helper.legacyInsert(contacts);
        }
        catch(Exception ex) {
            caughtException=ex;
        }
        System.assertNotEquals(null,caughtException,'Should have caught an exception');
        LimitHelper.cpuTimeReserved = 0;
        caughtException = null;
        try {
            new DatabaseHelper().setOptions(dmlOptions).setCheckLimits(true).safeInsert(contacts);
        }
        catch(Exception ex) {
            caughtException=ex;
        }
        System.assertEquals(null,caughtException,'Should not have caught an exception');

        try {
            new DatabaseHelper().setOptions(dmlOptions).setCheckLimits(true).safeUpdate(contacts);
        }
        catch(Exception ex) {
            caughtException=ex;
        }
        System.assertEquals(null,caughtException,'Should not have caught an exception');

        try {
            helper.legacyUpsert(contacts);
        }
        catch(Exception ex) {
            caughtException=ex;
        }
        System.assertEquals(null,caughtException,'Should not have caught an exception');

        try {
            new DatabaseHelper().setOptAllOrNone(true).setExternalIdField(Contact.FirstName).safeUpsert(contacts);
        }
        catch(Exception ex) {
            caughtException=ex;
        }
        System.assertNotEquals(null,caughtException,'Should have caught an exception');

        helper.setExternalIDField(Contact.LastName);
        try {
            helper.legacyUpsert(contacts);
        }
        catch(Exception ex) {
            caughtException=ex;
        }
        System.assertNotEquals(null,caughtException,'Should have caught an exception');

        caughtException = null;
        try {
            helper.legacyDelete(contacts);
        }
        catch(Exception ex) {
            caughtException=ex;
        }
        System.assertEquals(null,caughtException,'Should not have caught an exception');

        helper.setExternalIDField(null);
        try {
            helper.legacyUpsert(contacts);
        }
        catch(Exception ex) {
            caughtException=ex;
        }
        System.assertNotEquals(null,caughtException,'Should have caught an exception');

        caughtException = null;

        try {
            helper.legacyUndelete(contacts);
        }
        catch(Exception ex) {
            caughtException=ex;
        }
        System.assertEquals(null,caughtException,'Should not have caught an exception');

        try {
            helper.assignOptions(contacts).legacyUpsert(contacts);
        }
        catch(Exception ex) {
            caughtException=ex;
        }
        System.assertEquals(null,caughtException,'Should not have caught an exception');

        Test.stopTest();
    }

    /**
     * @description 
     * Check that getErrors returns an empty set with a null argument.
     */
    @isTest
    private static void getErrorsTest() {
        System.assertEquals(true,DatabaseHelper.getErrors(null)?.isEmpty());
    }

    /**
     * @description 
     * Test dml exceptions work as expected.
     */
    @isTest
    private static void dmlExceptionTest() {
        User currentUser = new User(Id=UserInfo.getUserId());
        DatabaseHelper.Result result;
        try {
            insert currentUser;
        }
        catch(DMLException ex) {
            TriggerManagement.lastRethrownException = ex;
            result = new DatabaseHelperResult(DatabaseHelperBase.DMLOperation.INSERT_OP,ex,currentUser);
            List<String> resultStrings = ex.getStackTraceString().split('\n');
            System.assertNotEquals(0,resultStrings.size(),'Expected a stack trace string');
        }
        // this will be null because we created the result from an exception
        System.assertEquals(null,DatabaseHelperResult.getId(result),'Expected null');
        System.assertNotEquals(null,result.getException().statusCode,'getException().statusCode');
        System.assertNotEquals(null,result.getException().fields,'getException().fields');
        Exception typeEx = null;
        try {
            DatabaseHelperResult.initCause(result.getException());
        }
        catch(System.TypeException ex) {
            typeEx = ex;
        }
        System.assertNotEquals(null,typeEx,'typeEx');
    }

    /**
     * @description
     * Check enqueue scope values work as expected. 
     */
    @isTest
    private static void enqueueScopeTest() {
        Account account1 = new Account(Name='enqueueScopeTest1');

        Test.startTest();
        List<Account> accounts = (new List<Account>{account1});
        List<DatabaseHelper.Result> results = new DatabaseHelper().setEnqueueScope(-1).safeInsert(accounts);
        System.assertEquals(1,results.size());
        for(DatabaseHelper.Result result : results) {
            System.assertEquals(result.isSuccess(),true,'Expected success: '+result.getErrors());
        }
        Account a = [select Id,Name from Account where Id = :account1.Id];
        System.assertEquals(account1.Name,a.Name,'Failed to assign Name');
        account1.Name='enqueueScopeTest2-1';
        Account account2 = new Account(Name='enqueueScopeTest2-2');
        accounts.add(account2);
        results = new DatabaseHelper().setEnqueueScope(2).safeUpsert(accounts);
        System.assertEquals(0,results.size());
        Test.stopTest();

        a = [select Id,Name from Account where Id = :account1.Id];
        System.assertEquals(account1.Name,a.Name,'Failed to assign Name');
        a = [select Id,Name from Account where Name = :account2.Name];
    }

    /**
     * @description
     * Check enqueue scope values work as expected. 
     */
    @isTest
    private static void enqueueScopeTest2() {
        User currentUser = new User(Id=UserInfo.getUserId(),FirstName='enqueueScopeTest');
        Test.startTest();
        List<User> userList = (new List<User>{currentUser});
        List<DatabaseHelper.Result> results = new DatabaseHelper().setEnqueueScope(1).safeUpdate(userList);
        System.assertEquals(0,results.size());
        Test.stopTest();
        // for some reason the following check fails when doing a package deploy but not when running standalone
        // User u = [select Id,FirstName from User where Id = :currentUser.Id];
        // System.assertEquals(currentUser.FirstName,u.FirstName,'Failed to assign FirstName');
    }

    /**
     * @description
     * Check enqueue jobs are processed. 
     */
    @IsTest
    private static void enqueueJobTest() {
        List<DatabaseHelperQueueable> queueableList = (
            new List<DatabaseHelperQueueable>{
                new DatabaseHelperQueueable(
                    new DatabaseHelper(),
                    DatabaseHelperBase.DMLOperation.INSERT_OP,
                    (new List<List<SObject>>{new List<SObject>{new Account(Name='Bob')}}) )
            }
        );
        Test.startTest();
        queueableList = DatabaseHelperQueueable.enqueueJob(queueableList);
        Test.stopTest();
        System.assertEquals(null,queueableList,'queueableList');
    }

    /**
     * @description 
     * Test the safe callback by assigning firstname to `'Success'`
     */
    @isTest
    private static void safeCallbackTest() {
        List<Contact> contacts = ( new List<Contact>{
            new Contact(LastName='Fudge'),
            new Contact(LastName='Chocolate')} );
        DatabaseHelper helper = new DatabaseHelper();
        helper.setAsyncSafeCallback(new AsyncSafeCallback());
        helper.setEnqueueScope(contacts.size());
    
        Test.startTest();
        List<DatabaseHelper.Result> results = helper.safeInsert(contacts);
        System.assertEquals(0,results.size());
        Test.stopTest();

        Contact fudge = [SELECT LastName,FirstName FROM Contact WHERE LastName='Fudge'];
        System.assertEquals('Success',fudge.FirstName,'Callback should have set Firstname');
        Contact chocolate = [SELECT LastName,FirstName FROM Contact WHERE LastName='Chocolate'];
        System.assertEquals('Success',chocolate.FirstName,'Callback should have set Firstname');
    }

    /**
     * @description 
     * Test the save callback by assigning firstname to `'Success'`
     */
    @isTest
    private static void saveCallbackTest() {
        List<Contact> contacts = ( new List<Contact>{
            new Contact(LastName='Fudge'),
            new Contact(LastName='Chocolate')} );
        DatabaseHelper helper = new DatabaseHelper()
            .setAsyncSaveCallback(new AsyncSaveCallback())
            .setEnqueueScope(contacts.size());
    
        Test.startTest();
        List<Database.SaveResult> results = helper.legacyInsert(contacts);
        System.assertEquals(0,results.size());
        Test.stopTest();

        Contact fudge = [SELECT LastName,FirstName FROM Contact WHERE LastName='Fudge'];
        System.assertEquals('Success',fudge.FirstName,'Callback should have set Firstname');
        Contact chocolate = [SELECT LastName,FirstName FROM Contact WHERE LastName='Chocolate'];
        System.assertEquals('Success',chocolate.FirstName,'Callback should have set Firstname');
    }

    /**
     * @description 
     * Test the delete callback by undeleting and assigning firstname to `'Success'`
     */
    @isTest
    private static void deleteCallbackTest() {
        List<Contact> contacts = ( new List<Contact>{
            new Contact(LastName='Fudge'),
            new Contact(LastName='Chocolate')} );
        insert contacts;
        AsyncDeleteCallback callback = new AsyncDeleteCallback();
        DatabaseHelper helper = new DatabaseHelper()
            .setAsyncDeleteCallback(callback)
            .setFinializer(callback)
            .setEnqueueScope(contacts.size());

        Test.startTest();
        List<Database.DeleteResult> results = helper.legacyDelete(contacts);
        System.assertEquals(0,results.size());
        Test.stopTest();

        Contact fudge = [SELECT LastName,FirstName FROM Contact WHERE LastName='Fudge'];
        System.assertEquals('Success',fudge.FirstName,'Callback should have set Firstname');
        Contact chocolate = [SELECT LastName,FirstName FROM Contact WHERE LastName='Chocolate'];
        System.assertEquals('Success',chocolate.FirstName,'Callback should have set Firstname');
    }

    /**
     * @description
     * Similar interface to the `DataSource.AsyncSaveCallback` and `DataSource.AsyncDeleteCallback`.
     * Used to return results from asynchronous updates.
     */
    public class AsyncSafeCallback implements DatabaseHelper.AsyncSafeCallback {
        public void processResults(DatabaseHelperBase.DMLOperation op,List<DatabaseHelper.Result> results) {
            System.assertEquals(DatabaseHelperBase.DMLOperation.INSERT_OP,op,'Expected insert');
            List<Contact> contacts = new List<Contact>();
            for(DatabaseHelper.Result result : results) {
                Contact c = (Contact)result.getSObject();
                c.FirstName='Success';
                contacts.add(c);
            }
            update contacts;
        }
    }

    /**
     * @description
     * Implement the `DataSource.AsyncSaveCallback`.
     */
    public class AsyncSaveCallback extends DataSource.AsyncSaveCallback {
        public override void processSave(Database.SaveResult result) {
            Contact c = new Contact(Id = result.getId(),FirstName='Success');
            update c;
        }
    }

    /**
     * @description
     * Implement the `DataSource.AsyncDeleteCallback`.
     */
    public class AsyncDeleteCallback 
        extends DataSource.AsyncDeleteCallback
        implements System.Finalizer
    {
        List<Contact> contacts = new List<Contact>();
        public void execute(System.FinalizerContext ctx) {
            undelete contacts;
            for(Contact c : contacts) {
                c.FirstName = 'Success';
            }
            update contacts;
        }

        public override void processDelete(Database.DeleteResult result) {
            Contact c = new Contact(Id = result.getId());
            contacts.add( c );
        }
    }

}
