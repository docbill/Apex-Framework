// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * @description
 * This is a class that can use to in leiu of the Database.*Result objects.
 * That way we can add to this set exceptions that were never actually thrown
 * and such.
 *
 * @group ApexFramework
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2021-04-28 - Separated from the DatabaseHelper class
 * @since 2022-09-09 update for ApexDox commenting
 */
public class DatabaseHelperResult implements DatabaseHelper.Result {
    private final Object result;
    private final SObject record;
    private final Boolean insertFlag;
    private final DatabaseHelperBase.DMLOperation op;

    /**
     * @description
     * Constructor
     * 
     * @param op the dml statement that was performed
     * @param result one of Database.SaveResult, Database.UpsertResult,...
     * @param record the message being operated on
     * @param errors
     */
    public DatabaseHelperResult(
        DatabaseHelperBase.DMLOperation op,
        Object result,
        SObject record,
        List<Database.Error> errors
    ) {
        this.op = op;
        this.result = result;
        this.record = record;
        this.insertFlag = (op == DatabaseHelperBase.DMLOperation.INSERT_OP);
        this.errors = errors;
        // make sure we initialize the stack trace
        this.exceptions.isEmpty();
    }

    /**
     * @description
     * Constructor
     * 
     * @param op the dml statement that was performed
     * @param result one of Database.SaveResult, Database.UpsertResult,...
     * @param record the message being operated on
     */
    public DatabaseHelperResult(DatabaseHelperBase.DMLOperation op,Exception result,SObject record) {
        this.result = result;
        this.record = record;
        this.insertFlag = (op == DatabaseHelperBase.DMLOperation.INSERT_OP);
        this.exceptions = new List<DatabaseHelper.ResultException>();
        if(! (result instanceof DatabaseHelper.ResultException)) {
            DatabaseHelper.ResultException xresult = new DatabaseHelper.ResultException(result);
            xresult.message = result.getMessage();
            xresult.stackTraceString = result.getStackTraceString();
            result = xresult;
        }
        exceptions.add((DatabaseHelper.ResultException)result);
    }

    /**
     * @description
     * Find the record we operated on.
     * 
     * @return record
     */
    public SObject getSObject() { return record; }

    private List<Database.Error> errors {
        get {
            if(errors == null) {
                errors = new List<Database.Error>();
                for(DatabaseHelper.ResultException re : exceptions) {
                    errors.add(re.getError());
                }
            }
            return errors;
        }
        set;
    }

    /**
     * @description
     * This returns all errors as Database.Error type.
     * 
     * @return list of all errors
     */
    public List<Database.Error> getErrors() { return errors; }

    private List<DatabaseHelper.ResultException> exceptions {
        get {
            if(exceptions == null) {
                exceptions = new List<DatabaseHelper.ResultException>();
                for(Database.Error e : errors) {
                    DatabaseHelper.ResultException ex = new DatabaseHelper.ResultException(e.getMessage());
                    ex.statusCode = e.getStatusCode();
                    initCause(ex);
                    ex.stackTraceString = null;
                    exceptions.add(ex);
                }
            }
            return exceptions;
        }
        set;
    }

    /**
     * @description
     * This returns all errors as DatabaseHelper.ResultException type.
     * 
     * @return list of all errors
     */
    public List<DatabaseHelper.ResultException> getExceptions() { return exceptions; }

    /**
     * @description
     * Return just the first exception as DatabaseHelper.ResultException type.
     * 
     * @return the first exception or null if there were none
     */
    public DatabaseHelper.ResultException getException() {
        if(exceptions.isEmpty()) {
            return null;
        }
        return exceptions[0];
    }

    /**
     * @description
     * What is the id value we operated on?
     * 
     * @return id value
     */
    public Id getId() { return getId(result); }

    /**
     * @description
     * Was the DML successful?
     * 
     * @return true if success
     */
    public Boolean isSuccess() { return DatabaseHelper.isSuccess(result); }

    /**
     * @description
     * Test this was an insert or an upsert that created a record.
     * 
     * @return true if a new record was created
     */
    public Boolean isCreated() {
        if(result instanceof Database.UpsertResult) {
            return ((Database.UpsertResult)result).isCreated();
        }
        return insertFlag && DatabaseHelper.isSuccess(result);
    }

    /**
     * @description
     * Query a list of stack traces for each exception.
     * 
     * @return list of stack traces 
     */
    public List<String> getStackTraceStrings() {
        List<String> retval = new List<String>();
        for(Exception e : getExceptions()) {
            retval.add(e.getStackTraceString());
        }
        return retval;
    }

    /**
     * @description 
     * Called to convert the result to Database.SaveResult, Database.UpsertResult,
     * Database.DeleteResult, Database.UndeteleResult, or DatabaseHelper.Result
     * as specified by the apexType. 
     * 
     * @param apexType the desired result type
     * @return the converted result
     */
    public Object convertResult(System.Type apexType) {
        if(
            (result instanceof Database.SaveResult && Database.SaveResult.class.equals(apexType))
            || (result instanceof Database.UpsertResult && Database.UpsertResult.class.equals(apexType))
            || (result instanceof Database.DeleteResult && Database.DeleteResult.class.equals(apexType))
            || (result instanceof Database.UndeleteResult && Database.UndeleteResult.class.equals(apexType))
            || (result instanceof DatabaseHelper.Result && DatabaseHelper.Result.class.equals(apexType))
        ) {
            return result;
        }
        String s = JSON.serialize(new SimpleResult(this),true);
        return JSON.deserialize(s,apexType);
    }

    @TestVisible
    private static void initCause(Exception ex) {
        if(TriggerManagement.lastRethrownException != null) {
            ex.initCause(TriggerManagement.lastRethrownException);
        }
    }

    /**
     * @description 
     *
     * Convert the list of results to the type of result we need.
     * 
     * @param op database operation that was performed
     * @param results the list of results from the database operation
     * @param records the records that the DML was performed on
     * @param legacyMode true if we don't want DatabaseHelper.Result as output
     * @return the list of converted results
     */
    public static List<Object> convertResultType(
        DatabaseHelperBase.DMLOperation op,
        List<Object> results,
        List<SObject> records,
        Boolean legacyMode
    ) {
        List<Object> retval = results;
        System.Type apexType = null;
        Boolean isResultClass = false;
        Boolean isSaveResultClass = false;
        Boolean isUpsertResultClass = false;
        Boolean isDeleteResultClass = false;
        Boolean isUndeleteResultClass = false;
        TriggerManagement.lastRethrownException = null;
        if(legacyMode == true) {
            switch on op {
                when INSERT_OP, UPDATE_OP {
                    if(results instanceof List<Database.SaveResult>) {
                        return results;
                    }
                    isSaveResultClass = true;
                    apexType = Database.SaveResult.class;
                    retval = new List<Database.SaveResult>();
                }
                when UPSERT_OP {
                    if(results instanceof List<Database.UpsertResult>) {
                        return results;
                    }
                    isUpsertResultClass = true;
                    apexType = Database.UpsertResult.class;
                    retval = new List<Database.UpsertResult>();
                }
                when DELETE_OP {
                    if(results instanceof List<Database.DeleteResult>) {
                        return results;
                    }
                    isDeleteResultClass = true;
                    apexType = Database.DeleteResult.class;
                    retval = new List<Database.DeleteResult>();
                }
                when UNDELETE_OP {
                    if(results instanceof List<Database.UndeleteResult>) {
                        return results;
                    }
                    isUndeleteResultClass = true;
                    apexType = Database.UndeleteResult.class;
                    retval = new List<Database.UndeleteResult>();
                }
            }
        }
        else if(records != null) {
            if(results instanceof List<DatabaseHelper.Result>) {
                return results;
            }
            apexType = DatabaseHelper.Result.class;
            isResultClass = true;
            retval = new List<DatabaseHelper.Result>();
        }
        if(apexType != null) {
            Iterator<SObject> recordIterator = null;
            if(records != null) {
                recordIterator = records.iterator();
            }
            for(Object r : results) {
                SObject record = null;
                if(recordIterator != null && recordIterator.hasNext()) {
                    record = recordIterator.next();
                }
                for(;;) {
                    if((! isResultClass) && r instanceof DatabaseHelper.Result ) {
                        retval.add( ((DatabaseHelper.Result)r).convertResult( apexType ) );
                    }
                    else if( r instanceof DatabaseHelper.Result
                        || (isSaveResultClass && r instanceof Database.SaveResult)
                        || (isUpsertResultClass && r instanceof Database.UpsertResult)
                        || (isDeleteResultClass && r instanceof Database.DeleteResult)
                        || (isUndeleteResultClass && r instanceof Database.UndeleteResult)
                    ) {
                        retval.add(r);
                    }
                    else {
                        r = new DatabaseHelperResult(op,r,record,DatabaseHelper.getErrors(r));
                        continue;
                    }
                    break;
                }
            }
        }
        return retval;
    }

    /**
     * @description
     * Method to check success with out depending on the type of database results.
     * 
     * @param result from a insert,update,upsert,delete,or undelete
     * @return id value if assigned
     */
    @TestVisible
    private static Id getId(Object result) {
        Id retval = null;
        if(result instanceof Database.SaveResult) {
            retval = ((Database.SaveResult)result).getId();
        }
        else if(result instanceof Database.UpsertResult) {
            retval = ((Database.UpsertResult)result).getId();
        }
        else if(result instanceof Database.DeleteResult) {
            retval = ((Database.DeleteResult)result).getId();
        }
        else if(result instanceof Database.UndeleteResult) {
            retval = ((Database.UndeleteResult)result).getId();
        }
        else if(result instanceof DatabaseHelper.Result) {
            retval = ((DatabaseHelper.Result)result).getId();
        }
        return retval;
    }

    // we use this class to convert to json
    private class SimpleResult {
        Boolean success;
        Id id;
        List<Database.Error> errors;
        
        SimpleResult(DatabaseHelper.Result r) {
            id = r.getId();
            errors = r.getErrors();
            success = r.isSuccess();
        }
    }
}