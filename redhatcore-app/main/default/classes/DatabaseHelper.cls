/**
 * This Class implements some useful database utilities.  Many copied from TestDataFactory.  It is pretty dangerious to use these in code, but
 * sometimes you need to deactivate triggers to repair or migrate data.   So these are available to call from anonymous apex...
 *
 * @version 2020-08-19
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2020-08-19 US266008 - Added governor limit checks
 * 
 * @todo update TestDataFactory to call this class, rather than having a duplicate implementation.
 */
public with sharing class DatabaseHelper {

    /**
     * This is just a wiled guess at the minimum numer of ms we should reserve for a DML
     * Statement.
     */
    private static final Integer MINIMUM_TIME_PER_DML = 10;

    private enum DMLOperation { INSERT_OP, UPDATE_OP, UPSERT_OP, DELETE_OP, UNDELETE_OP }

    private Boolean checkLimits = null;
    private Boolean legacyMode = false;
    private Boolean deactivateTriggers = false;
    private Schema.SObjectField externalIDField = null;
    
    /**
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
     * This performs a database operation, with optional limit checks.  If a limit is hit
     * a custom LimitException is thrown.
     * 
     * @param op dml operation to perform
     * @param recordList to insert
     */
    private List<Object> dmlStatement(
        DMLOperation op,
        List<SObject> recordList )
    {
        Integer requiredDML = 0;
        if(! recordList.isEmpty()) {
            requiredDML = 1;
        }
        Boolean deactivateTriggers = this.deactivateTriggers
            && (requiredDML > 0)
            && ! AbstractTrigger.isActive('DeactivateAll',false);
        if(deactivateTriggers) {
            AbstractTrigger.setBooleanSettings('DeactivateAll',true);
        }
        List<Object> retval = null;
        try {
            String limitMessage = null;
            if(checkLimits == true || (checkLimits == null && LimitHelper.throwsExceptionDefault == true)) {
                limitMessage = (new LimitHelper())
                    .setCpuTime(MINIMUM_TIME_PER_DML)
                    .setDmlStatements(requiredDML)
                    .setDmlRows(recordList.size())
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
                AbstractTrigger.setBooleanSettings('DeactivateAll',false);
            }
        }
        return convertResultType(op,retval,recordList);
    }

    private List<Object> convertResultType(
        DMLOperation op,
        List<Object> results,
        List<SObject> records
    ) {
        List<Object> retval = results;
        System.Type apexType = null;
        Boolean isResultClass = false;
        Boolean isSaveResultClass = false;
        Boolean isUpsertResultClass = false;
        Boolean isDeleteResultClass = false;
        Boolean isUndeleteResultClass = false;
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
            if(results instanceof List<Result>) {
                return results;
            }
            apexType = Result.class;
            isResultClass = true;
            retval = new List<Result>();
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
                    if((! isResultClass) && r instanceof Result ) {
                        retval.add( ((Result)r).convertResult( apexType) );
                    }
                    else if( r instanceof Result
                        || (isSaveResultClass && r instanceof Database.SaveResult)
                        || (isUpsertResultClass && r instanceof Database.UpsertResult)
                        || (isDeleteResultClass && r instanceof Database.DeleteResult)
                        || (isUndeleteResultClass && r instanceof Database.UndeleteResult)
                    ) {
                        retval.add(r);
                    }
                    else {
                        r = new Result(op,r,record,getErrors(r));
                        continue;
                    }
                    break;
                }
            }
        }
        return retval;
    }

    private List<Object> convertException(DMLOperation op,Exception ex,Iterator<SObject> recordIterator) {
        List<Result> retval = new List<Result>();
        while(recordIterator.hasNext()) {
            retval.add(new Result(op,ex,recordIterator.next()));
        }
        return retval;
    }

    /**
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
     * Method to check success with out depending on the type of database results.
     * 
     * @param result from a insert,update,upsert,delete,or undelete
     * @return id value if assigned
     */
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
        else if(result instanceof Result) {
            retval = ((Result)result).getId();
        }
        return retval;
    }

    /**
     * This is a class that can use to in leiu of the Database.*Result objects.
     * That way we can add to this set exceptions that were never actually thrown
     * and such.
     */
    public class Result {
        final Object result;
        final SObject record;
        final Boolean insertFlag;

        /**
         * Constructor
         * @param op the dml statement that was performed
         * @param result one of Database.SaveResult, Database.UpsertResult,...
         * @param record the message being operated on
         */
        public Result(DMLOperation op,Object result,SObject record,List<Database.Error> errors) {
            this.result = result;
            this.record = record;
            this.insertFlag = (op == DMLOperation.INSERT_OP);
            this.errors = errors;
        }

        /**
         * Constructor
         * 
         * @param op the dml statement that was performed
         * @param result one of Database.SaveResult, Database.UpsertResult,...
         * @param record the message being operated on
         */
        public Result(DMLOperation op,Exception result,SObject record) {
            this.result = result;
            this.record = record;
            this.insertFlag = (op == DMLOperation.INSERT_OP);
            this.exceptions = new List<ResultException>();
            if(! (result instanceof ResultException)) {
                ResultException xresult = new ResultException(result);
                xresult.message = result.getMessage();
                result = xresult;
            }
            exceptions.add((ResultException)result);
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
                    for(ResultException re : exceptions) {
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

        private List<ResultException> exceptions {
            get {
                if(exceptions == null) {
                    exceptions = new List<ResultException>();
                    for(Database.Error e : errors) {
                        ResultException ex = new ResultException(e.getMessage());
                        ex.statusCode = e.getStatusCode();
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
        public List<ResultException> getExceptions() { return exceptions; }

        /**
         * Return just the first exception as DatabaseHelper.ResultException type.
         * 
         * @return the first exception or null if there were none
         */
        public ResultException getException() {
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
        public Boolean isSuccess() { return isSuccess(result); }

        /**
         * Test this was an insert or an upsert that created a record.
         * 
         * @return true if a new record was created
         */
        public Boolean isCreated() {
            if(result instanceof Database.UpsertResult) {
                return ((Database.UpsertResult)result).isCreated();
            }
            return insertFlag && isSuccess(result);
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

        @TestVisible
        private Object convertResult(System.Type apexType) {
            if(
                (result instanceof Database.SaveResult && Database.SaveResult.class.equals(apexType))
                || (result instanceof Database.UpsertResult && Database.UpsertResult.class.equals(apexType))
                || (result instanceof Database.DeleteResult && Database.DeleteResult.class.equals(apexType))
                || (result instanceof Database.UndeleteResult && Database.UndeleteResult.class.equals(apexType))
                || (result instanceof Result && Result.class.equals(apexType))
            ) {
                return result;
            }
            String s = JSON.serialize(new SimpleResult(this),true);
            return JSON.deserialize(s,apexType);
        }

    }

    // we use this class to convert to json
    private class SimpleResult {
        Boolean success;
        Id id;
        List<Database.Error> errors;
        
        SimpleResult(Result r) {
            id = r.getId();
            errors = r.getErrors();
            success = r.isSuccess();
        }
    }

    /**
     * We use an exception class for error, so we can throw if we want and we can
     * get a stack trace.
     */
    public class ResultException extends Exception {
        public String message {
            get{ return getMessage(); }
            set{ setMessage(value); }
        }

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

        public Database.Error getError() {
            String s = JSON.serialize(this,true);
            return (Database.Error)JSON.deserialize(s,Database.Error.class);
        }
    }
}