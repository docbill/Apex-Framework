// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * @description
 * This Class implements some useful database utilities.  Many copied from TestDataFactory.  It is pretty dangerious to use these in code, but
 * sometimes you need to deactivate triggers to repair or migrate data.   So these are available to call from anonymous apex...
 *
 * @group ApexFramework
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2020-08-19 US266008 - Added governor limit checks
 * @since 2021-01-07 US281262 - Added setEnqueueScope for Queuable splitting of dml
 * @since 2021-01-27 workaround stack trace bug
 * @since 2021-02-11 initCause on exceptions
 * @since 2021-03-24 lock on DatabaseHelper.class.getName() when enqueueJob is called
 * @since 2021-03-24 remember in queueable instance boolean values
 * @since 2021-04-27 DE26549 - Increment queue counter
 * @since 2021-10-27 US307550 - Fixed enqueueing multiple dml calls
 * @since 2022-09-09 update for ApexDox commenting
 * 
 * @todo Add a callback mechanism for errors
 */
public with sharing class DatabaseHelper {
    /**
     * @description
     * This is just a wiled guess at the minimum numer of ms we should reserve for a DML
     * Statement.
     */
    private static final Integer MINIMUM_TIME_PER_DML = 10;

    /**
     * @description 
     * Used internally.
     */
    public enum DMLOperation { INSERT_OP, UPDATE_OP, UPSERT_OP, DELETE_OP, UNDELETE_OP }

    private Boolean checkLimits = null;
    private Boolean legacyMode = false;
    private Boolean deactivateTriggers = false;
    private Integer enqueueScope = null;
    private Schema.SObjectField externalIDField = null;
    
    /**
     * @description
     * Standard Constructor.
     */
    public DatabaseHelper() {}

    private Database.DMLOptions options {
        get {
            if(options == null) {
                options = new Database.DMLOptions();
                options.OptAllOrNone = false;
            }
            return options;
        }
        set;
    }

    /**
     * @description
     * We cannot pass the options to an upsert operation, so a workaround
     * is to assign the options to all the records.
     * 
     * @param recordList
     * @return this
     */
    public DatabaseHelper assignOptions(List<SObject> recordList) {
        for(SObject record : recordList) {
            record.setOptions( options );
        }
        return this;
    }

    /**
     * @description
     * Setting this value causes the dml operation to be performed as
     * a chain of queueable jobs.  Each job performing the dml on the
     * number of records specified.
     * 
     * A negative value means only the overflow records of
     * the first grouping will be processed in a queueable job.
     * 
     * @param value
     * @return this
     */
    public DatabaseHelper setEnqueueScope(Integer value) {
        enqueueScope = value;
        return this;
    }

    /**
     * @description
     * Retrieve value set for enqueueScope.
     * @return enqueueScope
     */
    public Integer getEnqueueScope() {
        return enqueueScope;
    }

    /**
     * @description
     * Set the OptAllOrNone flag on the dmlOptions.
     * 
     * @param value
     * @return this
     */
    public DatabaseHelper setOptAllOrNone(Boolean value) {
        options.OptAllOrNone = value;
        return this;
    }

    /**
     * @description
     * Set the allowFieldTruncation flag on the dmlOptions.
     * 
     * @param value
     * @return this
     */
    public DatabaseHelper setAllowFieldTruncation(Boolean value) {
        options.AllowFieldTruncation = value;
        return this;
    }
    
    /**
     * @description
     * Set the dmlOptions.
     * 
     * @param value
     * @return this
     */
    public DatabaseHelper setOptions(Database.DMLOptions value) {
        options = value;
        return this;
    }

    /**
     * @description
     * Set to disable all triggers that use the Deactivate all triggers
     * that use an isActive check on the DeactivateAll boolean metadata.
     * 
     * @param value
     * @return this
     */
    public DatabaseHelper setDeactivateTriggers(Boolean value) {
        this.deactivateTriggers = value;
        return this;
    }

    /**
     * @description
     * Set the external id field to use in an upsert.
     * 
     * @param value
     * @return this
     */
    public DatabaseHelper setExternalIDField(Schema.SObjectField value) {
        externalIDField = value;
        return this;
    }

    /**
     * @description
     * Called to change the check limits property.
     * A setCheckLimits(null) is equivalent to the 
     * setCheckLimits(LimitHelper.throwsExceptionDefault)
     * immediatly prior to the dml operation.
     * 
     * We only throw the limit exception if optAllOrNothing 
     * is true.
     * 
     * @param value if true we should check the limits.
     * @return this
     */
    public DatabaseHelper setCheckLimits(Boolean value) {
        checkLimits = value;
        return this;
    }

    /**
     * @description
     * Called to insert the recordList.
     * 
     * @param recordList
     * @return result list
     */
    public List<Result> safeInsert(List<SObject> recordList) {
        legacyMode = false;
        return (List<Result>)dmlStatement(DMLOperation.INSERT_OP, recordList);
    }

    /**
     * @description
     * Called to insert the recordList.
     * 
     * @param recordList
     * @return result list
     */
    public List<Database.SaveResult> legacyInsert(List<SObject> recordList) {
        legacyMode = true;
        return (List<Database.SaveResult>)dmlStatement(DMLOperation.INSERT_OP, recordList);
    }

    /**
     * @description
     * Called to update the recordList.
     * 
     * @param recordList
     * @return result list
     */
    public List<Database.SaveResult> legacyUpdate(List<SObject> recordList) {
        legacyMode = true;
        return (List<Database.SaveResult>)dmlStatement(DMLOperation.UPDATE_OP, recordList);
    }

    /**
     * @description
     * Called to update the recordList.
     * 
     * @param recordList
     * @return result list
     */
    public List<Result> safeUpdate(List<SObject> recordList) {
        legacyMode = false;
        return (List<Result>)dmlStatement(DMLOperation.UPDATE_OP, recordList);
    }

    /**
     * @description
     * Called to upsert the recordList.
     * 
     * @param recordList
     * @return result list
     */
    public List<Database.UpsertResult> legacyUpsert(List<SObject> recordList) {
        legacyMode = true;
        return (List<Database.UpsertResult>)dmlStatement(DMLOperation.UPSERT_OP, recordList);
    }

    /**
     * @description
     * Called to upsert the recordList.
     * 
     * @param recordList
     * @return result list
     */
    public List<Result> safeUpsert(List<SObject> recordList) {
        legacyMode = false;
        return (List<Result>)dmlStatement(DMLOperation.UPSERT_OP, recordList);
    }

    /**
     * @description
     * Called to delete the recordList.
     * 
     * @param recordList
     * @return result list
     */
    public List<Database.DeleteResult> legacyDelete(List<SObject> recordList) {
        legacyMode = true;
        return (List<Database.DeleteResult>)dmlStatement(DMLOperation.DELETE_OP, recordList);
    }

    /**
     * @description
     * Called to delete the recordList.
     * 
     * @param recordList
     * @return result list
     */
    public List<Result> safeDelete(List<SObject> recordList) {
        legacyMode = false;
        return (List<Result>)dmlStatement(DMLOperation.DELETE_OP, recordList);
    }

    /**
     * @description
     * Called to undelete the recordList.
     * 
     * @param recordList
     * @return result list
     */
    public List<Database.UndeleteResult> legacyUndelete(List<SObject> recordList) {
        legacyMode = true;
        return (List<Database.UndeleteResult>)dmlStatement(DMLOperation.UNDELETE_OP, recordList);
    }

    /**
     * @description
     * Called to undelete the recordList.
     * 
     * @param recordList
     * @return result list
     */
    public List<Result> safeUndelete(List<SObject> recordList) {
        legacyMode = false;
        return (List<Result>)dmlStatement(DMLOperation.UNDELETE_OP, recordList);
    }

    /**
     * @description
     * This performs a database operation, with optional limit checks.  If a limit is hit
     * a custom LimitException is thrown.
     * 
     * @param op dml operation to perform
     * @param recordList to insert
     * @return the results list
     */
    public List<Object> dmlStatement(
        DMLOperation op,
        List<SObject> recordList )
    {
        Integer queueableJobs = 0;
        if(enqueueScope != null && enqueueScope != 0) {
            List<List<SObject>> recordsList = split(recordList,-enqueueScope);
            if(recordsList.size() > 1 || enqueueScope > 0) {
                queueableJobs = 1;
                if((new LimitHelper()).setQueueableJobs(1).checkLimits(false) == null) {
                    if(! recordsList.isEmpty()) {
                        recordList = recordsList.remove(0);
                    }
                    new DatabaseHelperQueueable(this,op,recordsList).enqueueJob();
                }
            }
        }
        Integer requiredDML = 0;
        if(! recordList.isEmpty()) {
            requiredDML = 1;
        }
        Boolean deactivateTriggers = this.deactivateTriggers
            && (requiredDML > 0)
            && ! BooleanValuesHelper.getBooleanValue('DeactivateAll',false);
        if(deactivateTriggers) {
            BooleanValuesHelper.setValuesWhichStartWith('DeactivateAll',true);
        }
        List<Object> retval = null;
        try {
            String limitMessage = null;
            if(checkLimits == true || (checkLimits == null && LimitHelper.throwsExceptionDefault == true)) {
                limitMessage = (new LimitHelper())
                    .setCpuTime(MINIMUM_TIME_PER_DML)
                    .setDmlStatements(requiredDML)
                    .setDmlRows(recordList.size())
                    .setQueueableJobs(queueableJobs)
                    .checkLimits( (options == null || options.optAllOrNone == true) );
            }
            if(limitMessage != null) {
                retval = convertException(op,new LimitHelper.LimitsException(limitMessage),recordList.iterator());
            }
            else {
                switch on op {
                    when INSERT_OP {
                        retval = Database.insert(recordList,options);
                    }
                    when UPDATE_OP {
                        retval = Database.update(recordList,options);
                    }
                    when UPSERT_OP {
                        if(externalIDField != null) {
                            retval = Database.upsert(recordList,externalIdField,(options == null || options.optAllOrNone == true));
                        }
                        else {
                            retval = Database.upsert(recordList,(options == null || options.optAllOrNone == true));
                        }
                    }
                    when DELETE_OP {
                        retval = Database.delete(recordList,(options == null || options.optAllOrNone == true));
                    }
                    when UNDELETE_OP {
                        retval = Database.undelete(recordList,(options == null || options.optAllOrNone == true));
                    }
                }
            }
        }
        finally {
            if(deactivateTriggers) {
                BooleanValuesHelper.setValuesWhichStartWith('DeactivateAll',false);
            }
        }
        return DatabaseHelperResult.convertResultType(op,retval,recordList,legacyMode);
    }

    /**
     * @description
     * Splits a list into smaller lists no greate than size.
     * If size is negative the first list in the returned array
     * will be empty.
     * 
     * @param records list to split
     * @param size the number of records per list
     * @return a list of records lists of the appropriate size
     */
    @TestVisible
    static List<List<SObject>> split(List<SObject> records,Integer size) {
        List<List<SObject>> retval = new List<List<SObject>>();
        if(records != null) {
            // DE26549 reworked this logic
            if(size == null || size == 0) {
                retval.add(records);
            }
            else {
                List<SObject> currentList = new List<SObject>();
                Integer remaining=size;
                if(size < 0) {
                    size = -size;
                    remaining = 0;
                }
                for(SObject record : records) {
                    if(record != null) {
                        if(remaining-- < 1) {
                            retval.add(currentList);
                            currentList = new List<SObject>();
                            remaining = size-1; // We count this record right away
                        }
                        currentList.add(record);
                    }
                }
                retval.add(currentList);
            }
        }
        return retval;
    }

    private List<Object> convertException(DMLOperation op,Exception ex,Iterator<SObject> recordIterator) {
        List<Result> retval = new List<Result>();
        while(recordIterator.hasNext()) {
            retval.add(new DatabaseHelperResult(op,ex,recordIterator.next()));
        }
        return retval;
    }

    /**
     * @description
     * Method to check success with out depending on the type of database results.
     * 
     * @param result from a insert,update,upsert,delete,or undelete
     * @return true if success
     */
    public static Boolean isSuccess(Object result) {
        Boolean retval = false;
        if(result instanceof Database.SaveResult) {
            retval = ((Database.SaveResult)result).isSuccess();
        }
        else if(result instanceof Database.UpsertResult) {
            retval = ((Database.UpsertResult)result).isSuccess();
        }
        else if(result instanceof Database.DeleteResult) {
            retval = ((Database.DeleteResult)result).isSuccess();
        }
        else if(result instanceof Database.UndeleteResult) {
            retval = ((Database.UndeleteResult)result).isSuccess();
        }
        else if(result instanceof Result) {
            retval = ((Result)result).isSuccess();
        }
        return retval;
    }

    /**
     * @description
     * Method to get errors with out depending on the type of database results.
     * 
     * @param result from a insert,update,upsert,delete,or undelete
     * @return a list of database errors
     */
    public static List<Database.Error> getErrors(Object result) {
        if(result instanceof Database.SaveResult) {
            return ((Database.SaveResult)result).getErrors();
        }
        if(result instanceof Database.UpsertResult) {
            return ((Database.UpsertResult)result).getErrors();
        }
        if(result instanceof Database.DeleteResult) {
            return ((Database.DeleteResult)result).getErrors();
        }
        if(result instanceof Database.UndeleteResult) {
            return ((Database.UndeleteResult)result).getErrors();
        }
        List<Database.Error> retval = null;
        if(result == null) { 
            retval = new List<Database.Error>();
        }
        return retval;
    }

    /**
     * @description
     * This is a class that can use to in leiu of the Database.*Result objects.
     * That way we can add to this set exceptions that were never actually thrown
     * and such.
     */
    public interface Result {

        /**
         * @description
         * Find the record we operated on.
         * 
         * @return record
         */
        SObject getSObject();

        /**
         * @description
         * This returns all errors as Database.Error type.
         * 
         * @return list of all errors
         */
        List<Database.Error> getErrors();

        /**
         * @description
         * This returns all errors as DatabaseHelper.ResultException type.
         * 
         * @return list of all errors
         */
        List<ResultException> getExceptions();

        /**
         * @description
         * Return just the first exception as DatabaseHelper.ResultException type.
         * 
         * @return the first exception or null if there were none
         */
        ResultException getException();

        /**
         * @description
         * What is the id value we operated on?
         * 
         * @return id value
         */
        Id getId();

        /**
         * @description
         * Was the DML successful?
         * 
         * @return true if success
         */
        Boolean isSuccess();

        /**
         * @description
         * Test this was an insert or an upsert that created a record.
         * 
         * @return true if a new record was created
         */
        Boolean isCreated();

        /**
         * @description
         * Query a list of stack traces for each exception.
         * 
         * @return list of stack traces 
         */
        List<String> getStackTraceStrings();

        /**
         * @description
         * Convert the result to a different type.
         * 
         * @param apexType
         * @return converted result
         */
        Object convertResult(System.Type apexType);
    }

    @TestVisible
    static List<String> addStackTraceString(List<String> results,Exception cause) {
        if(cause != null) {
            results.add(cause.getStackTraceString());
        }
        return results;
    }

    /**
     * @description
     * We use an exception class for error, so we can throw if we want and we can
     * get a stack trace.
     * 
     * In order for the getError method to work, this class must have the same memembers 
     * as the Database.Error class.
     */
    public class ResultException extends Exception {
        private transient Boolean ignoreStackTraceString = false;

        /**
         * @description
         * Generate a stack trace string for the result.
         * @return stack trace
         */
        public String stackTraceString {
            get {
                if(ignoreStackTraceString == true) {
                    return null;
                }
                return stackTraceString;
            }
            set {
                if(value == null || value == '()') {
                    // stack traces only seem to be complete if we actually
                    // catch an exception.  So throw anytype of exception
                    // and then we have a stack trace.
                    try {
                        Integer.valueOf('catdog');
                    }
                    catch(Exception ex) {
                        List<String> results = addStackTraceString(
                            new List<String>(),
                            ex.getCause() );
                        
                        for(String v : ex.getStackTraceString().split('\n',3)) {
                            results.add(v);
                        }

                        value = String.join(results,'\n');
                    }
                }
                stackTraceString = value;
            }
        }

        /**
         * @description 
         * Respective message for this exception
         */
        public String message {
            get{ return getMessage(); }
            set{ setMessage(value); }
        }

        /**
         * @description 
         * If not assigned, the DmlType of the getCause exception
         */
        public StatusCode statusCode {
            get {
                if(statusCode == null) {
                    Exception ex = getCause();
                    if(ex instanceof DmlException) {
                        statusCode = ((DmlException)ex).getDmlType(0);
                    }
                }
                return statusCode;
            }
            set;
        }

        /**
         * @description
         * List of DmlFieldNames associated with this result.
         */
        public String [] fields {
            get {
                if(fields == null) {
                    fields = new List<String>();
                    Exception ex = getCause();
                    if(ex instanceof DmlException) {
                        fields = ((DmlException)ex).getDmlFieldNames(0);
                    }
                }
                return fields;
            }
            set;
        }

        /**
         * @description 
         * Get this result as a Database.Error
         * @return a Database.Error copy of this result
         */
        public Database.Error getError() {
            ignoreStackTraceString = true;
            String s = JSON.serialize(this,true);
            ignoreStackTraceString = false;
            return (Database.Error)JSON.deserialize(s,Database.Error.class);
        }

        /**
         * @description 
         * Get method for stack trace string
         * @return the stack trace
         */
        public override String getStackTraceString() {
            return stackTraceString;
        }
    }
}
