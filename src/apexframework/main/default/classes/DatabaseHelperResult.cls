// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * This is a class that can use to in leiu of the Database.*Result objects.
 * That way we can add to this set exceptions that were never actually thrown
 * and such.
 *
 * @version 2022-08-11
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2021-04-28 - Separated from the DatabaseHelper class
 * @since 2022-08-11 Reduce cognitive complexity
 */
public class DatabaseHelperResult implements DatabaseHelper.Result {
    final Object result;
    final SObject record;
    final Boolean insertFlag;

    /**
     * Constructor
     * @param op the dml statement that was performed
     * @param result one of Database.SaveResult, Database.UpsertResult,...
     * @param record the message being operated on
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public DatabaseHelperResult(DatabaseHelper.DMLOperation op,Object result,SObject record,List<Database.Error> errors) {
        this.result = result;
        this.record = record;
        this.insertFlag = (op == DatabaseHelper.DMLOperation.INSERT_OP);
        this.errors = errors;
        // make sure we initialize the stack trace
        this.exceptions.isEmpty();
    }

    /**
     * Constructor
     * 
     * @param op the dml statement that was performed
     * @param result one of Database.SaveResult, Database.UpsertResult,...
     * @param record the message being operated on
     */
    public DatabaseHelperResult(DatabaseHelper.DMLOperation op,Exception result,SObject record) {
        this.result = result;
        this.record = record;
        this.insertFlag = (op == DatabaseHelper.DMLOperation.INSERT_OP);
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
     * This returns all errors as DatabaseHelper.ResultException type.
     * 
     * @return list of all errors
     */
    public List<DatabaseHelper.ResultException> getExceptions() { return exceptions; }

    /**
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
     * What is the id value we operated on?
     * 
     * @return id value
     */
    public Id getId() { return getId(result); }

    /**
     * Was the DML successful?
     * 
     * @return true if success
     */
    public Boolean isSuccess() { return DatabaseHelper.isSuccess(result); }

    /**
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
    static void initCause(Exception ex) {
        if(TriggerManagement.lastRethrownException != null) {
            ex.initCause(TriggerManagement.lastRethrownException);
        }
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static List<Object> convertResultType(
        DatabaseHelper.DMLOperation op,
        List<Object> results,
        List<SObject> records,
        Boolean legacyMode
    ) {
        ConversionHelper helper = null;
        TriggerManagement.lastRethrownException = null;
        if(legacyMode == true) {
            helper = new ConversionHelper(op,results);
        }
        else if(records != null) {
            helper = new ConversionHelper(results);
        }
        return helper.convertResults(op,records);
    }

    /**
     * Method to check success with out depending on the type of database results.
     * 
     * @param result from a insert,update,upsert,delete,or undelete
     * @return id value if assigned
     */
    @TestVisible
    @SuppressWarnings('PMD.CognitiveComplexity')
    static Id getId(Object result) {
        if(result instanceof Database.SaveResult) {
            return ((Database.SaveResult)result).getId();
        }
        else if(result instanceof Database.UpsertResult) {
            return ((Database.UpsertResult)result).getId();
        }
        else if(result instanceof Database.DeleteResult) {
            return ((Database.DeleteResult)result).getId();
        }
        else if(result instanceof Database.UndeleteResult) {
            return ((Database.UndeleteResult)result).getId();
        }
        else if(result instanceof DatabaseHelper.Result) {
            return ((DatabaseHelper.Result)result).getId();
        }
        return null;
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

    private class ConversionHelper {
        List<Object> results;
        List<Object> convertedList;
        System.Type apexType = null;
        Boolean isResultClass = false;
        Boolean isSaveResultClass = false;
        Boolean isUpsertResultClass = false;
        Boolean isDeleteResultClass = false;
        Boolean isUndeleteResultClass = false;

        // safe mode
        ConversionHelper(List<Object> results)
        {
            this.results = results;
            apexType = DatabaseHelper.Result.class;
            isResultClass = true;
            if(results instanceof List<DatabaseHelper.Result>) {
                convertedList = results;
            }
            else {
                convertedList = new List<DatabaseHelper.Result>();
            }
        }

        // legacy mode
        ConversionHelper(DatabaseHelper.DMLOperation op,List<Object> results)
        {
            this.results = results;
            Boolean noConvert = false;
            switch on op {
                when INSERT_OP, UPDATE_OP {
                    noConvert = (results instanceof List<Database.SaveResult>);
                    isSaveResultClass = true;
                    apexType = Database.SaveResult.class;
                    convertedList = new List<Database.SaveResult>();
                }
                when UPSERT_OP {
                    noConvert = (results instanceof List<Database.UpsertResult>);
                    isUpsertResultClass = true;
                    apexType = Database.UpsertResult.class;
                    convertedList = new List<Database.UpsertResult>();
                }
                when DELETE_OP {
                    noConvert = (results instanceof List<Database.DeleteResult>);
                    isDeleteResultClass = true;
                    apexType = Database.DeleteResult.class;
                    convertedList = new List<Database.DeleteResult>();
                }
                when UNDELETE_OP {
                    noConvert = (results instanceof List<Database.UndeleteResult>);
                    isUndeleteResultClass = true;
                    apexType = Database.UndeleteResult.class;
                    convertedList = new List<Database.UndeleteResult>();
                }
            }
            if(noConvert) {
                convertedList = results;
            }
        }


        List<Object> convertResults(DatabaseHelper.DMLOperation op,List<SObject> records)
        {
            if(convertedList != null && convertedList.isEmpty()) {
                Iterator<SObject> recordIterator = null;
                if(records != null) {
                    recordIterator = records.iterator();
                }
                for(Object r : results) {
                    SObject record = null;
                    if(recordIterator != null && recordIterator.hasNext()) {
                        record = recordIterator.next();
                    }
                    convert(op,r,record);
                }
            }
            return convertedList;
        }

        void convert(DatabaseHelper.DMLOperation op,Object r,SObject record) {
            if((! isResultClass) && r instanceof DatabaseHelper.Result ) {
                convertedList.add( ((DatabaseHelper.Result)r).convertResult( apexType ) );
            }
            else if( r instanceof DatabaseHelper.Result
                || (isSaveResultClass && r instanceof Database.SaveResult)
                || (isUpsertResultClass && r instanceof Database.UpsertResult)
                || (isDeleteResultClass && r instanceof Database.DeleteResult)
                || (isUndeleteResultClass && r instanceof Database.UndeleteResult)
            ) {
                convertedList.add(r);
            }
            else {
                convert( op,
                    new DatabaseHelperResult(op,r,record,DatabaseHelper.getErrors(r)),
                    record );
            }
        }
    }
}
