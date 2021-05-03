/**
 * Test class for DatabaseHelper.
 * 
 * @version 2021-04-27
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2020-08-18 US268650 - Created
 * @since 2021-01-07 US281262 - Added setEnqueueScope for Queuable splitting of dml
 * @since 2021-03-30 - Increase test coverage
 * @since 2021-04-27 DE26549 - Added split test
 */
@IsTest
private class DatabaseHelperTest {

    static final String CPU_TIME_RE = 'Limits: CPU Time: [0-9]* out of 0';
    static final Pattern CPU_TIME_PATTERN = Pattern.compile(CPU_TIME_RE);

    static void cpuTimeCheck(String actual,String message) {
        if(! CPU_TIME_PATTERN.matcher(actual).matches()) {
            System.assertEquals(CPU_TIME_RE,actual,message);
        }
    }

    @isTest
    static void safeTest() {
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

    @isTest
    static void dmlOptionsTest() {
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

    @isTest
    static void getErrorsTest() {
        System.assertEquals(true,DatabaseHelper.getErrors(null).isEmpty());
    }

    @isTest
    static void dmlExceptionTest() {
        User currentUser = new User(Id=UserInfo.getUserId());
        DatabaseHelper.Result result;
        try {
            insert currentUser;
        }
        catch(DMLException ex) {
            TriggerManagement.lastRethrownException = ex;
            result = new DatabaseHelperResult(DatabaseHelper.DMLOperation.INSERT_OP,ex,currentUser);
            List<String> resultStrings = DatabaseHelper.addStackTraceString(
                new List<String>(),
                ex );
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

    @isTest
    static void enqueueScopeTest() {
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

    @isTest
    static void enqueueScopeTest2() {
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

    @IsTest
    static void enqueueJobTest() {
        List<DatabaseHelperQueueable> queueableList = (
            new List<DatabaseHelperQueueable>{
                new DatabaseHelperQueueable(
                    new DatabaseHelper(),
                    DatabaseHelper.DMLOperation.INSERT_OP,
                    (new List<List<SObject>>{new List<SObject>()}) )
            }
        );
        Test.startTest();
        queueableList = DatabaseHelperQueueable.enqueueJob(queueableList);
        Test.stopTest();
        System.assertEquals(null,queueableList,'queueableList');
    }

    @isTest
    static void splitTest() {
        List<Account> accounts = (new List<Account>{
            new Account(Name='1'),
            new Account(Name='2'),
            new Account(Name='3'),
            new Account(Name='4'),
            new Account(Name='5'),
            new Account(Name='6'),
            new Account(Name='7'),
            new Account(Name='8')
        });
        List<List<SObject>> results = DatabaseHelper.split(accounts,null);
        System.assertEquals(1,results.size());
        System.assertEquals(accounts.size(),results[0].size());
        results = DatabaseHelper.split(accounts,0);
        System.assertEquals(1,results.size());
        System.assertEquals(accounts.size(),results[0].size());
        results = DatabaseHelper.split(accounts,1);
        System.assertEquals(8,results.size());
        System.assertEquals(1,results[0].size());
        System.assertEquals(1,results[1].size());
        System.assertEquals(1,results[2].size());
        System.assertEquals(1,results[3].size());
        System.assertEquals(1,results[4].size());
        System.assertEquals(1,results[5].size());
        System.assertEquals(1,results[6].size());
        System.assertEquals(1,results[7].size());
        results = DatabaseHelper.split(accounts,-1);
        System.assertEquals(9,results.size());
        System.assertEquals(0,results[0].size());
        System.assertEquals(1,results[1].size());
        System.assertEquals(1,results[2].size());
        System.assertEquals(1,results[3].size());
        System.assertEquals(1,results[4].size());
        System.assertEquals(1,results[5].size());
        System.assertEquals(1,results[6].size());
        System.assertEquals(1,results[7].size());
        System.assertEquals(1,results[8].size());
        results = DatabaseHelper.split(accounts,4);
        System.assertEquals(2,results.size());
        System.assertEquals(4,results[0].size());
        System.assertEquals(4,results[1].size());
        results = DatabaseHelper.split(accounts,-4);
        System.assertEquals(3,results.size());
        System.assertEquals(0,results[0].size());
        System.assertEquals(4,results[1].size());
        System.assertEquals(4,results[2].size());
    }
}